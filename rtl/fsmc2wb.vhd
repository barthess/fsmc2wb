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
    AW : positive; -- total FSMC address width
    DW : positive; -- data witdth
    USENBL : std_logic; -- set to '1' if you want NBL (byte select) pin support
    AWSEL  : positive; -- address lines used for slave select
    AWSLAVE : positive -- wishbone slave address width 
  );
	Port (
    clk_i : in std_logic; -- high speed internal FPGA clock
    err_o : out std_logic;
    ack_o : out std_logic;
    
    -- FSMC interface
    A : in STD_LOGIC_VECTOR (AW-1 downto 0);
    D : inout STD_LOGIC_VECTOR (DW-1 downto 0);
    NWE : in STD_LOGIC;
    NOE : in STD_LOGIC;
    NCE : in STD_LOGIC;
    NBL : in std_logic_vector (1 downto 0);
    
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

  -- MMU check routine. Must be called when addres sampled
  function mmu_check(A   : in std_logic_vector(AW-1 downto 0);
                     NBL : in std_logic_vector(1 downto 0)) 
                     return std_logic is
  begin
    if (A(AW-1 downto AWSEL+AWSLAVE) /= 0) or ((NBL(0) /= NBL(1) and USENBL = '0')) then
      return '1';
    else
      return '0';
    end if;
  end mmu_check;

  -- Return actual address bits
  function get_addr(A : in std_logic_vector(AW-1 downto 0)) 
                     return std_logic_vector is
  begin
    return A(AWSLAVE-1 downto 0);
  end get_addr;
  
  -- 
  function get_sel(A : in std_logic_vector(AW-1 downto 0)) 
                     return std_logic_vector is
  begin
    return A(AWSLAVE+AWSEL - 1 downto AWSLAVE);
  end get_sel;
  
end fsmc2wb;



-----------------------------------------------------------------------------

architecture beh of fsmc2wb is

type state_t is (IDLE, FLUSH);
  signal a_reg : STD_LOGIC_VECTOR (AWSLAVE-1 downto 0);
  signal sel_reg : STD_LOGIC_VECTOR (AWSEL-1 downto 0);
  signal d_reg : STD_LOGIC_VECTOR (DW-1 downto 0); 
  signal nwe_reg : STD_LOGIC_VECTOR (1 downto 0) := "11";
  -- control signals for WB slave
  signal sel_wire_nce : STD_LOGIC;
  signal we_wire : std_logic;
  signal stb_wire : std_logic;
  signal err_wire : std_logic;
  -- outputs from data bus muxer
  signal fsmc_do_wire : std_logic_vector(DW-1 downto 0);
  signal fsmc_do_reg  : std_logic_vector(DW-1 downto 0);
begin

  -- data muxer from multiple wishbone slaves to data bus
  di_muxer : entity work.muxer
  generic map (
    AW => AWSEL,
    DW => DW
  )
  port map (
    A  => sel_reg,
    do => fsmc_do_wire,
    di => dat_i
  );

  -- MMU muxer from multiple wishbone slaves
  mmu_muxer : entity work.muxer
  generic map (
    AW => AWSEL,
    DW => 1
  )
  port map (
    A     => sel_reg,
    do(0) => err_wire,
    di    => err_i
  );

  -- ACK muxer from multiple wishbone slaves
  ack_muxer : entity work.muxer
  generic map (
    AW => AWSEL,
    DW => 1
  )
  port map (
    A     => sel_reg,
    do(0) => ack_o,
    di    => ack_i
  );

  -- demuxer for chip select line
  sel_demux : entity work.demuxer
    generic map (
      AW => 3,
      DW => 1,
      default => '0'
    )
    port map (
      di(0) => sel_wire_nce,
      a     => sel_reg,
      do    => sel_o
    );
    
  -- fanout bus outputs to slaves (no muxers)
  wb_fanout : for n in 0 to 2**AWSEL-1 generate 
  begin
    we_o(n)  <= we_wire;
    stb_o(n) <= stb_wire;
    adr_o((n+1)*AWSLAVE-1 downto n*AWSLAVE) <= a_reg;  
    dat_o((n+1)*DW-1 downto n*DW) <= d_reg;
  end generate;
  
  -- connect 3-state data bus
  D <= fsmc_do_reg when (NCE = '0' and NOE = '0') else (others => 'Z');
  
  -- bus registering
  process(clk_i) begin
    if rising_edge(clk_i) then
      d_reg   <= D;
      a_reg   <= get_addr(A);
      sel_reg <= get_sel(A);
      nwe_reg <= nwe_reg(0) & NWE;
      fsmc_do_reg <= fsmc_do_wire;
    end if;
  end process;
  
  -- BRAM WE logic. Will be activate 1 clock after WE goes down
  process(clk_i) begin
    if rising_edge(clk_i) then
      if (nwe_reg = "10") then
         we_wire  <= '1';
         stb_wire <= '1';
      else
         we_wire  <= '0';
         stb_wire <= '0';
      end if;
    end if;
  end process;

  -- MMU process
  process(clk_i) begin
    if rising_edge(clk_i) then
      if (NCE = '0') then
        err_o <= mmu_check(A, NBL) or err_wire;
      end if;
    end if;
  end process;

  -- NCE process
  sel_wire_nce <= not NCE;
  
end beh;




