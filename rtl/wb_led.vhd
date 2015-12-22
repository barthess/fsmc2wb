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

entity wb_led is
  Generic (
    AW : positive; -- address width
    DW : positive  -- data width
  );
  Port (
    led   : out std_logic_vector(5 downto 0);

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
end wb_led;



-----------------------------------------------------------------------------

architecture beh of wb_led is

  signal led_reg : std_logic_vector(5 downto 0);
  signal err_dat : std_logic;
  signal err_adr : std_logic;

begin

  dat_o(DW-1 downto 6) <= (others => '0');
  dat_o(5 downto 0) <= led_reg;
  led <= led_reg;
  err_o <= err_dat or err_adr;

  -- dat_i to LED
  process(clk_i) begin
    if rising_edge(clk_i) then
      if (stb_i = '1' and sel_i = '1') then
        if (we_i = '1') then
          led_reg <= dat_i(5 downto 0);
          ack_o <= '1';
        end if;
      end if;
    end if;
  end process;
  
  -- data check
  process(clk_i) begin
    if rising_edge(clk_i) then
      if (sel_i = '1' and adr_i > 0 and we_i = '1' and dat_i(DW-1 downto 6) > 0) then
        err_dat <= '1';
      else
        err_dat <= '0';
      end if;
    end if;
  end process;

  -- MMU check
  process(clk_i) begin
    if rising_edge(clk_i) then
      if (sel_i = '1' and adr_i > 0) then
        err_adr <= '1';
      else
        err_adr <= '0';
      end if;
    end if;
  end process;
  
end beh;




