library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.std_logic_misc.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

--
--
--
entity mtrx_mov is
  Generic (
    MTRX_AW : positive := 5; -- 2**MTRX_AW = max matrix index
    BRAM_DW : positive := 64;
    -- Data latency. Contains
    -- 1) address path to BRAM
    -- 2) BRAM data latency (generally 1 cycle)
    -- 3) data path from BRAM to device
    DAT_LAT : positive range 1 to 15 := 1
  );
  Port (
    -- control interface
    rst_i  : in  std_logic; -- active high. Must be used before every new calculation
    clk_i  : in  std_logic;
    size_i : in  std_logic_vector(15 downto 0); -- size of input operands
    err_o  : out std_logic := '0'; -- active high 1 clock
    rdy_o  : out std_logic := '0'; -- active high 1 clock
    -- operation select
    -- 0 copy
    -- 1 set
    -- 2 transposition
    -- 3 eye generate
    op_i : in std_logic_vector(1 downto 0);

    -- BRAM interface
    -- Note: there are no clocks for BRAMs. They are handle in higher level
    bram_adr_a_o : out std_logic_vector(2*MTRX_AW-1 downto 0);
    bram_adr_b_o : out std_logic_vector(2*MTRX_AW-1 downto 0); -- unused
    bram_adr_c_o : out std_logic_vector(2*MTRX_AW-1 downto 0);
    
    set_constant : in  std_logic_vector(BRAM_DW-1 downto 0); -- external constant for memset
    bram_dat_a_i : in  std_logic_vector(BRAM_DW-1 downto 0);
    bram_dat_b_i : in  std_logic_vector(BRAM_DW-1 downto 0);
    bram_dat_c_o : out std_logic_vector(BRAM_DW-1 downto 0);
    bram_we_o    : out std_logic -- for C bram
  );
end mtrx_mov;


-----------------------------------------------------------------------------

architecture beh of mtrx_mov is
  
  -- operand and result addresses registers
  constant ZERO  : std_logic_vector(MTRX_AW-1   downto 0) := (others => '0');
  constant ZERO2 : std_logic_vector(2*MTRX_AW-1 downto 0) := (others => '0');
  constant OP_CPY : integer := 0;
  constant OP_EYE : integer := 1;
  constant OP_TRN : integer := 2;
  constant OP_SET : integer := 3;
  
  signal a_adr : std_logic_vector(2*MTRX_AW-1 downto 0) := ZERO2;
  signal c_adr : std_logic_vector(2*MTRX_AW-1 downto 0) := ZERO2;
  signal a_adr_array : std_logic_vector(4*2*MTRX_AW-1 downto 0) := (others => '0');
  signal c_adr_array : std_logic_vector(4*2*MTRX_AW-1 downto 0) := (others => '0');
  
  signal m_size, p_size : std_logic_vector(MTRX_AW-1 downto 0) := ZERO;
  signal mi, pi, mo, po : std_logic_vector(MTRX_AW-1 downto 0) := ZERO;
  
  signal end_of_i, end_of_o : std_logic := '0';
  
  signal rst_i_tracker_array : std_logic_vector(3 downto 0) := (others => '1');
  signal rst_o_tracker_array : std_logic_vector(3 downto 0) := (others => '1');
  signal rst_i_tracker : std_logic := '1';
  signal rst_o_tracker : std_logic := '1';
  
  constant ZERO64 : std_logic_vector(BRAM_DW-1 downto 0) := (others => '0');
  constant ONE64  : std_logic_vector(BRAM_DW-1 downto 0) := x"3FF0000000000000"; -- 1.000000
  signal result_buf : std_logic_vector(BRAM_DW-1 downto 0);
  signal result_we : std_logic := '0';

  -- state machine
  type state_t is (IDLE, PRELOAD, ACTIVE, HALT);
  signal state : state_t := IDLE;
  
  signal lat_i, lat_o : natural range 0 to 15 := DAT_LAT;
  
begin
  
  rst_i_demuxer : entity work.demuxer
  generic map(
    AW => 2,
    DW => 1,
    default => '1'
  )
  port map(
    A     => op_i,
    di(0) => rst_i_tracker,
    do    => rst_i_tracker_array
  );
  
  rst_o_demuxer : entity work.demuxer
  generic map(
    AW => 2,
    DW => 1,
    default => '1'
  )
  port map(
    A     => op_i,
    di(0) => rst_o_tracker,
    do    => rst_o_tracker_array
  );
  
  a_adr_muxer : entity work.muxer
  generic map(
    AW => 2,
    DW => 2*MTRX_AW
  )
  port map(
    A  => op_i,
    di => a_adr_array,
    do => a_adr
  );
  
  c_adr_muxer : entity work.muxer
  generic map(
    AW => 2,
    DW => 2*MTRX_AW
  )
  port map(
    A  => op_i,
    di => c_adr_array,
    do => c_adr
  );
  

  
  
  bram_adr_a_o <= a_adr;
  bram_adr_b_o <= (others => '0');
  bram_adr_c_o <= c_adr;
  bram_we_o    <= result_we;
  bram_dat_c_o <= result_buf;

  --
  -- Main state machine
  --
  main : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if (rst_i = '1') then
        state <= IDLE;
        result_we <= '0';
        rdy_o <= '0';
        err_o <= '0';
        rst_i_tracker <= '1';
        rst_o_tracker <= '1';
      else        
        rdy_o <= '0';
        err_o <= '0';  
        
        case state is
        when IDLE =>
          if size_i(15 downto 2*MTRX_AW) > 0 then
            err_o <= '1';
            state <= HALT;
          else
            m_size <= size_i(MTRX_AW-1   downto 0);
            p_size <= size_i(2*MTRX_AW-1 downto MTRX_AW);
            rst_i_tracker <= '0';
            lat_i <= lat_i - 1;
            state <= PRELOAD;
          end if;
          
        when PRELOAD =>
          lat_i <= lat_i - 1;
          if (lat_i = 0) then
            state <= ACTIVE;
            rst_o_tracker <= '0';
            result_we <= '1';
            result_buf <= bram_dat_a_i;
          end if;
         
        when ACTIVE =>
          if end_of_i = '1' then
            rst_i_tracker <= '1';
          end if;
          
          if end_of_o = '1' then
            rst_o_tracker <= '1';
            result_we <= '0';
            rdy_o <= '1';
            state <= HALT;
          end if;

        when HALT =>
          state <= HALT;
          
        end case;
      end if; -- clk
    end if; -- rst
  end process;




  end_of_i <= '1' when (mi = m_size and pi = p_size) else '0';

  cpy_i_tracker_proc : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if (rst_i_tracker_array(OP_CPY) = '1') then
        mi <= ZERO;
        pi <= ZERO;
        a_adr_array(OP_CPY) <= ZERO2;
      else
        a_adr_array(OP_CPY) <= a_adr_array(OP_CPY) + 1;
        mi <= mi + 1;
        if (mi = m_size) then
          mi <= ZERO;
          pi <= pi + 1;
        end if;
      end if; -- rst
    end if; -- clk
  end process;



  end_of_o <= '1' when (mo = m_size and po = p_size) else '0';

  cpy_o_tracker_proc : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if (rst_o_tracker_array(OP_CPY) = '1') then
        mo <= ZERO;
        po <= ZERO;
        c_adr_array(OP_CPY) <= ZERO2;
      else
        c_adr_array(OP_CPY) <= c_adr_array(OP_CPY) + 1;
        mo <= mo + 1;
        if (mo = m_size) then
          mo <= ZERO;
          po <= po + 1;
        end if;
      end if; -- rst
    end if; -- clk
  end process;










  eye_tracker_proc : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if (rst_i_tracker_array(OP_EYE) = '1') then
      else 
      end if; -- rst
    end if; -- clk
  end process;

  trn_tracker_proc : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if (rst_i_tracker_array(OP_TRN) = '1') then
      else 
      end if; -- rst
    end if; -- clk
  end process;

  set_tracker_proc : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if (rst_i_tracker_array(OP_SET) = '1') then
      else 
      end if; -- rst
    end if; -- clk
  end process;









end beh;


