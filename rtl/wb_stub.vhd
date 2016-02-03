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

entity wb_stub is
  Generic (
    AW : positive := 16; -- address width
    DW : positive := 16; -- data width
    DAT_AW : integer := 3 -- address width of internal data array
  );
  Port (
    clk_i : in  std_logic;
    sel_i : in  std_logic;
    stb_i : in  std_logic;
    we_i  : in  std_logic;
    err_o : out std_logic;
    ack_o : out std_logic;
    adr_i : in  std_logic_vector(AW-1 downto 0);
    dat_o : out std_logic_vector(DW-1 downto 0);
    dat_i : in  std_logic_vector(DW-1 downto 0)
  );
end wb_stub;


-----------------------------------------------------------------------------

architecture beh of wb_stub is
  type math_ctl_reg_t is array (0 to 2**DAT_AW-1) of std_logic_vector(DW-1 downto 0);
  signal dat_array : math_ctl_reg_t := (others => (x"DEAD"));
begin
  
  -- bus sampling process
  main : process(clk_i) 
    variable int_adr : integer range 0 to 2**DAT_AW-1 := 0;
  begin
    if rising_edge(clk_i) then
      if (stb_i = '1' and sel_i = '1') then
        int_adr := conv_integer(adr_i(DAT_AW-1 downto 0));
        dat_o <= dat_array(int_adr);
        if (we_i = '1') then
          dat_array(int_adr) <= dat_i;
        end if;
      end if;
    end if;
  end process;

  -- MMU process
  mmu : process(clk_i) 
  begin
    if rising_edge(clk_i) then
      if (sel_i = '1' and stb_i = '1') then
        if (adr_i > 2**DAT_AW-1) then
          err_o <= '1';
          ack_o <= '0';
        else
          err_o <= '0';
          ack_o <= '1';
        end if;
      end if;
    end if;
  end process;

end beh;


