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
entity mtrx_add is
  Generic (
    BRAM_AW : positive := 10;
    BRAM_DW : positive := 64;
    -- Data latency. Consist of:
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
    rdy_o  : out std_logic := '0'; -- active high 1 cycle
    sub_not_add_i : in std_logic;
    
    -- BRAM interface
    -- Note: there are no clocks for BRAMs. They are handle in higher level
    bram_adr_a_o : out std_logic_vector(BRAM_AW-1 downto 0);
    bram_adr_b_o : out std_logic_vector(BRAM_AW-1 downto 0);
    bram_adr_c_o : out std_logic_vector(BRAM_AW-1 downto 0);
    bram_dat_a_i : in  std_logic_vector(BRAM_DW-1 downto 0);
    bram_dat_b_i : in  std_logic_vector(BRAM_DW-1 downto 0);
    bram_dat_c_o : out std_logic_vector(BRAM_DW-1 downto 0);
    bram_we_o    : out std_logic -- for C bram
  );
end mtrx_add;


-----------------------------------------------------------------------------

architecture beh of mtrx_add is
  
  -- operand and result addresses registers
  constant ZERO : std_logic_vector(BRAM_AW-1 downto 0) := (others => '0');
  signal A_adr : std_logic_vector(BRAM_AW-1 downto 0);
  signal B_adr : std_logic_vector(BRAM_AW-1 downto 0);
  signal C_adr : std_logic_vector(BRAM_AW-1 downto 0);
  signal nd_track : std_logic_vector(BRAM_AW-1 downto 0);
  signal lat_i, lat_o : natural range 0 to 15 := DAT_LAT;
  
  -- multiplicator control signals
  signal add_nd  : std_logic := '0';
  signal add_ce  : std_logic := '0';
  signal add_rdy : std_logic;

  -- state machine
  type state_t is (IDLE, PRELOAD, ACTIVE, HALT);
  signal state : state_t := IDLE;
  type rdy_state_t is (RDY_IDLE, RDY_ACTIVE, RDY_HALT);
  signal rdy_state : rdy_state_t := RDY_IDLE;

begin
  
  bram_adr_a_o <= A_adr;
  bram_adr_b_o <= B_adr;
  bram_adr_c_o <= C_adr;
  bram_we_o    <= add_rdy;

  --
  -- adder
  --
  dadd : entity work.dadd
  port map (
    a      => bram_dat_a_i,
    b      => bram_dat_b_i,
    result => bram_dat_c_o,
    clk    => clk_i,
    ce     => add_ce,
    rdy    => add_rdy,
    operation(5 downto 1) => "00000",
    operation(0) => sub_not_add_i,
    operation_nd => add_nd
  );
  
  --
  -- Main state machine
  -- 
  main : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if (rst_i = '1') then
        state   <= IDLE;
        add_nd  <= '0';
        add_ce  <= '0';
        lat_i   <= DAT_LAT;
      else
        case state is
        when IDLE =>
          A_adr     <= size_i(9 downto 0);
          B_adr     <= size_i(9 downto 0);
          C_adr     <= size_i(9 downto 0);
          nd_track  <= size_i(9 downto 0);
          lat_i     <= lat_i - 1;
          state     <= PRELOAD;

        when PRELOAD =>
          A_adr <= A_adr - 1;
          B_adr <= B_adr - 1;
          lat_i <= lat_i - 1;
          if (lat_i = 0) then
            state  <= ACTIVE;
            add_ce <= '1';
            add_nd <= '1';
          end if;

        when ACTIVE =>
          A_adr <= A_adr - 1;
          B_adr <= B_adr - 1;

          if (nd_track /= 0) then
            nd_track <= nd_track - 1;
          else
            add_nd <= '0';
          end if;
          
          if (add_rdy = '1') then
            C_adr <= C_adr - 1;
            if (C_adr = 0) then
              add_ce <= '0';
              state  <= HALT;
            end if;
          end if;

        when HALT =>
          state <= HALT;
        end case;
        
      end if; -- clk
    end if; -- rst
  end process;


  --
  -- ready pin logic
  -- 
  rdy_o <= '1' when (rdy_state = RDY_ACTIVE and lat_o = 0) else '0';
  
  rdy_o_driver : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if (rst_i = '1') then
        rdy_state <= RDY_IDLE;
        -- we need only half of the pipeline during data flush
        -- because data transferred in one direction
        lat_o <= DAT_LAT / 2;
      else
        case rdy_state is
        when RDY_IDLE =>
          if (C_adr = 0 and add_rdy = '1' and state = ACTIVE) then
            rdy_state <= RDY_ACTIVE;
          end if;

        when RDY_ACTIVE =>
          lat_o <= lat_o - 1;
          if (lat_o = 0) then
            rdy_state <= RDY_HALT;
          end if;

        when RDY_HALT =>
          rdy_state <= RDY_HALT;
        end case;
        
      end if; -- clk
    end if; -- rst
  end process;


end beh;

