library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

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
entity zero_mapper is
  Port (
    clk_i : in  std_logic;
    rst_i : in  std_logic;
    ce_i  : in  std_logic;
    dat_i : in  std_logic_vector(63 downto 0);
    dat_o : out std_logic_vector(32*32-1 downto 0)
  );
end zero_mapper;


-----------------------------------------------------------------------------
-- 
--
architecture beh of zero_mapper is
  constant ZERO64 : std_logic_vector(63 downto 0) := (others => '0');
  signal cnt : integer range 0 to 32*32-1;
begin

  main : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if (rst_i = '1') then
        cnt <= 0;
      else
        if ce_i = '1' then
          cnt <= cnt + 1;
          if (dat_i = ZERO64) then
            dat_o(cnt) <= '0';
          else
            dat_o(cnt) <= '1';
          end if;
        end if; -- ce
      end if; -- rst
    end if; -- clk
  end process;


end beh;


