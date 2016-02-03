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

entity wb_bram is
  Generic (
    WB_AW   : positive; -- wishbone address width
    BRAM_AW : positive; -- BRAM address width
    DW      : positive  -- data width
  );
  Port (
    bram_clk_o  : out std_logic;
    bram_adr_o  : out std_logic_vector(BRAM_AW-1 downto 0);
    bram_dat_i  : in  std_logic_vector(DW-1 downto 0);
    bram_dat_o  : out std_logic_vector(DW-1 downto 0);
    bram_we_o   : out std_logic;
    bram_en_o   : out std_logic;
      
    clk_i : in  std_logic;
    sel_i : in  std_logic;
    stb_i : in  std_logic;
    we_i  : in  std_logic;
    err_o : out std_logic;
    ack_o : out std_logic;
    adr_i : in  std_logic_vector(WB_AW-1 downto 0);
    dat_o : out std_logic_vector(DW-1 downto 0);
    dat_i : in  std_logic_vector(DW-1 downto 0)
  );
end wb_bram;


-----------------------------------------------------------------------------

architecture beh of wb_bram is
  signal adr_reg  : std_logic_vector(BRAM_AW-1 downto 0);
  signal dat_bram2wb_reg : std_logic_vector(DW-1 downto 0);
  signal dat_wb2bram_reg : std_logic_vector(DW-1 downto 0);
  signal we_reg   : std_logic; 
begin

  bram_clk_o  <= clk_i;
  bram_en_o   <= '1'; 
  ack_o       <= stb_i and sel_i;
  err_o       <= '1' when (WB_AW > BRAM_AW and sel_i = '1' and adr_i(WB_AW-1 downto BRAM_AW) > 0) else '0';
  
  main : process(clk_i)
  begin
    if rising_edge(clk_i) then
      adr_reg         <= adr_i(BRAM_AW-1 downto 0);
      dat_wb2bram_reg <= dat_i;
      dat_bram2wb_reg <= bram_dat_i;
      we_reg          <= we_i and stb_i and sel_i;
    end if;
  end process;
  
  bram_adr_o  <= adr_reg;
  bram_dat_o  <= dat_wb2bram_reg;
  dat_o       <= dat_bram2wb_reg;
  bram_we_o   <= we_reg;

--
-- old slow code without registering
--  
--  bram_clk_o  <= clk_i;
--  bram_adr_o  <= adr_i(BRAM_AW-1 downto 0);
--  bram_dat_o  <= dat_i;
--  dat_o       <= bram_dat_i;
--  bram_we_o   <= we_i and stb_i and sel_i;
--  bram_en_o   <= '1';
--  ack_o       <= stb_i and sel_i;
--  err_o <= '1' when (WB_AW > BRAM_AW and sel_i = '1' and adr_i(WB_AW-1 downto BRAM_AW) > 0) else '0';

end beh;




