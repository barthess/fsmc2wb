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
    AW : positive; -- total FSMC address width
    DW : positive  -- data witdth
  );
  Port (
    clk_i : in  std_logic;
    sel_i : in  std_logic;
    stb_i : in  std_logic;
    we_i  : in  std_logic;
    mmu_o : out std_logic;
    ack_o : out std_logic;
    adr_i : in  std_logic_vector(AW-1 downto 0);
    dat_o : out std_logic_vector(DW-1 downto 0);
    dat_i : in  std_logic_vector(DW-1 downto 0)
  );
end wb_stub;



-----------------------------------------------------------------------------

architecture beh of wb_stub is

type state_t is (IDLE, FLUSH);
begin

  -- bus sampling process
  process(clk_i) begin
    if rising_edge(clk_i) then
      if (stb_i = '1' and sel_i = '1') then
        ack_o <= '1';
        if (we_i = '1') then
          dat_o <= dat_i;
        else
          dat_o <= x"DEAD";
        end if;
      end if;
    end if;
  end process;
  
  -- MMU process
  process(clk_i) begin
    if rising_edge(clk_i) then
      if (sel_i = '1' and adr_i > 0) then
        mmu_o <= '1';
      else
        mmu_o <= '0';
      end if;
    end if;
  end process;

end beh;




