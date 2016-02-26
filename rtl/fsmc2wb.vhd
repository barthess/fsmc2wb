----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:43:03 07/21/2015 
-- Design Name: 
-- Module Name:    fsmc_glue - A_fsmc_glue 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
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

entity fsmc2wb is
  Generic (
    AW : positive := 23; -- total FSMC address width
    DW : positive := 16; -- data witdth
    --USENBL : std_logic :='0'; -- set to '1' if you want NBL (byte select) pin support
    AWSEL  : positive  := 4; -- address lines used for slave select
    AWSLAVE : positive := 16 -- wishbone slave address width 
  );
	Port (
    clk_i : in std_logic; -- high speed internal FPGA clock
    
    -- FSMC interface
    A : in STD_LOGIC_VECTOR (AW-1 downto 0);
    D : inout STD_LOGIC_VECTOR (DW-1 downto 0);
    NWE : in STD_LOGIC;
    NOE : in STD_LOGIC;
    NCE : in STD_LOGIC;
    --NBL : in std_logic_vector (1 downto 0);
    
    -- External interrupt/status lines for STM32
    external_err_o : out std_logic;
    external_mmu_err_o : out std_logic;
    external_ack_o : out std_logic;
    
    -- WB slaves interface
    sel_o : out std_logic_vector(2**AWSEL - 1           downto 0);
    stb_o : out std_logic_vector(2**AWSEL - 1           downto 0);
    we_o  : out std_logic_vector(2**AWSEL - 1           downto 0);
    err_i : in  std_logic_vector(2**AWSEL - 1           downto 0);
    ack_i : in  std_logic_vector(2**AWSEL - 1           downto 0);
    adr_o : out std_logic_vector(AWSLAVE * 2**AWSEL - 1 downto 0);
    dat_o : out std_logic_vector(DW * 2**AWSEL - 1      downto 0);
    dat_i : in  std_logic_vector(DW * 2**AWSEL - 1      downto 0)
  );

  -- Return actual address bits
  function get_addr(A : in std_logic_vector(AW-1 downto 0)) 
                     return std_logic_vector is
  begin
    return A(AWSLAVE-1 downto 0);
  end get_addr;
  
  -- return wb slave select bits
  function get_sel(A : in std_logic_vector(AW-1 downto 0)) 
                     return std_logic_vector is
  begin
    return A(AWSLAVE+AWSEL - 1 downto AWSLAVE);
  end get_sel;
  
end fsmc2wb;



-----------------------------------------------------------------------------

architecture beh of fsmc2wb is

  signal fsmc_a_reg    : STD_LOGIC_VECTOR (AWSLAVE-1 downto 0);
  signal fsmc_d_reg    : STD_LOGIC_VECTOR (DW-1 downto 0); 
  signal fsmc_nwe_reg  : STD_LOGIC_VECTOR (1 downto 0) := "11";
  signal fsmc_noe_reg  : STD_LOGIC_VECTOR (1 downto 0) := "11";
  signal fsmc_nce_reg  : STD_LOGIC := '1';

  signal slave_select : STD_LOGIC_VECTOR (AWSEL-1 downto 0);
  
  -- control signals for WB slave
  signal we_wire  : std_logic := '0';
  signal stb_wire : std_logic := '0';
  signal sel_wire : std_logic := '0';
  signal err_wire : std_logic := '0';
  signal sel_w, sel_r, stb_r, stb_w : std_logic := '0';
  
  -- output data from WB to FSMC
  signal fsmc_do_wire : std_logic_vector(DW-1 downto 0);
  signal fsmc_do_reg : std_logic_vector(DW-1 downto 0);
  
  attribute IOB : string;
  attribute IOB of fsmc_do_reg : signal is "TRUE";

  type state_t is (IDLE, ADSET, READ1);
  signal state : state_t := IDLE;
  
begin
  ------------------------------------------------------------------------------
  -- lines from wishbone to FSMC
  ------------------------------------------------------------------------------

  -- data muxer from multiple wishbone slaves to data bus
  wb2fsmc_dat_muxer : entity work.muxer_reg(i)
  generic map (
    AW => AWSEL,
    DW => DW
  )
  port map (
    clk_i => clk_i,
    a     => slave_select,
    do    => fsmc_do_wire,
    di    => dat_i
  );

  -- Special process for data lines allignment
  do_reg_proc : process(clk_i) begin
    if rising_edge(clk_i) then
      fsmc_do_reg <= fsmc_do_wire;
    end if;
  end process;
  
  -- error muxer from multiple wishbone slaves
  wb2fsmc_err_muxer : entity work.muxer_reg(io)
  generic map (
    AW => AWSEL,
    DW => 1
  )
  port map (
    clk_i => clk_i,
    a     => slave_select,
    do(0) => external_err_o,
    di    => err_i
  );

  -- ACK muxer from multiple wishbone slaves
  wb2fsmc_ack_muxer : entity work.muxer_reg(io)
  generic map (
    AW => AWSEL,
    DW => 1
  )
  port map (
    clk_i => clk_i,
    a     => slave_select,
    do(0) => external_ack_o,
    di    => ack_i
  );

  ------------------------------------------------------------------------------
  -- lines from FSMC to wishbone
  ------------------------------------------------------------------------------

  -- demuxer for chip select line
  fsmc2wb_select_demux : entity work.demuxer_reg(o)
  generic map (
    AW => AWSEL,
    DW => 1,
    default => '0'
  )
  port map (
    clk_i => clk_i,
    a     => slave_select,
    di(0) => sel_wire,
    do    => sel_o
  );

  -- fanout bus outputs to all slaves without muxers
  fsmc2wb_stb_fork : entity work.fork_reg(o)
  generic map (
    ocnt => 2**AWSEL,
    DW   => 1
  )
  port map (
    clk_i => clk_i,
    di(0) => stb_wire,
    do    => stb_o
  );
  
  -- 
  fsmc2wb_we_fork : entity work.fork_reg(o)
  generic map (
    ocnt => 2**AWSEL,
    DW   => 1
  )
  port map (
    clk_i => clk_i,
    di(0) => we_wire,
    do    => we_o
  );
  
  --
  fsmc2wb_adr_fork : entity work.fork_reg(o)
  generic map (
    ocnt => 2**AWSEL,
    DW   => AWSLAVE
  )
  port map (
    clk_i => clk_i,
    di    => fsmc_a_reg,
    do    => adr_o
  );
  
  -- 
  fsmc2wb_dat_fork : entity work.fork_reg(o)
  generic map (
    ocnt => 2**AWSEL,
    DW   => DW
  )
  port map (
    clk_i => clk_i,
    di => fsmc_d_reg,
    do => dat_o
  );
  
  -- connect 3-state data bus
  D <= fsmc_do_reg when (NCE = '0' and NOE = '0') else (others => 'Z');
  
  -- bus registering
  process(clk_i) begin
    if rising_edge(clk_i) then
      fsmc_d_reg   <= D;
      fsmc_a_reg   <= get_addr(A);
      slave_select <= get_sel(A);
      fsmc_nwe_reg <= fsmc_nwe_reg(0) & NWE;
      fsmc_noe_reg <= fsmc_noe_reg(0) & NOE;
      fsmc_nce_reg <= NCE;
    end if;
  end process;
  
  
  -- resolution function for STB and SEL signals
  stb_wire <= stb_r or stb_w;
  sel_wire <= sel_r or sel_w;
  
  --
  --
  --
  read_proc : process(clk_i) 
  begin
    if rising_edge(clk_i) then
      case state is
      when IDLE =>
        if (fsmc_noe_reg = "10" and fsmc_nce_reg = '0') then
          stb_r <= '1';
          sel_r <= '1';
          state <= ADSET;
        end if;
      
      when ADSET =>
        state <= READ1;
        
      when READ1 =>
        stb_r <= '0';
        sel_r <= '0';
        state <= IDLE;
      end case;
      
    end if;
  end process;

  --
  -- BRAM WE logic. Will be activate 1 clock after WE goes down
  --
  write_proc : process(clk_i) 
  begin
    if rising_edge(clk_i) then
      if (fsmc_nwe_reg = "10" and fsmc_nce_reg = '0') then
        we_wire <= '1';
        stb_w   <= '1';
        sel_w   <= '1';
      else
        we_wire <= '0';
        stb_w   <= '0';
        sel_w   <= '0';
        -- тут получаются сигналы, активные 1 такт,
        -- а для вишбона надо 2. Возможно есть смысл скостылить чего-нибудь. 
        -- Такую же траблу надо проверить на цикле чтения
      end if;
    end if;
  end process;

  --
  -- MMU check
  --
  external_mmu_err_o <= '1' when (stb_wire = '1' and A(AW-1 downto AWSEL+AWSLAVE) > 0) else '0';
        
  --
  -- MMU process
  --
--  process(clk_i) begin
--    if rising_edge(clk_i) then
--      if stb_wire = '1' then
--        if A(AW-1 downto AWSEL+AWSLAVE) > 0 then
--          external_mmu_err_o <= '1';
--        else
--          external_mmu_err_o <= '0';
--        end if;
--      end if;
--    end if;
--  end process;


end beh;

