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
  Generic (
    AW : positive := 6; -- address width. 2**AW is number of words in bitmap
    WW : positive := 4 -- 2**WW is data word width. Must be like wishbone data width
  );
  Port (
    clk_i : in  std_logic;
    rst_i : in  std_logic;
    ce_i  : in  std_logic;
    dat_i : in  std_logic_vector(63 downto 0);
    dat_o : out std_logic_vector(2**WW-1 downto 0);
    adr_o : out std_logic_vector(AW-1 downto 0);
    dv_o  : out std_logic := '0'
  );
end zero_mapper;


-----------------------------------------------------------------------------
-- 
--
architecture beh of zero_mapper is
  constant ZERO64 : std_logic_vector(63 downto 0) := (others => '0');
  signal cnt : std_logic_vector(AW+WW-1 downto 0);
  signal map16b : std_logic_vector(2**WW-1 downto 0);
begin
  
  dat_o <= map16b;
  adr_o <= cnt(AW+WW-1 downto WW);

  main : process(clk_i)
    variable idx : natural range 0 to 2**WW-1;
  begin
    if rising_edge(clk_i) then
      if (rst_i = '1') then
        cnt <= (others => '0');
        dv_o <= '0';
      else
        if ce_i = '1' then
          cnt <= cnt + 1;
          dv_o <= '1';

          idx := conv_integer(cnt(WW-1 downto 0));
          if (dat_i = ZERO64) then
            map16b(idx) <= '0';
          else
            map16b(idx) <= '1';
          end if;
        else
          dv_o <= '0';
        end if; -- ce
      end if; -- rst
    end if; -- clk
  end process;


end beh;


