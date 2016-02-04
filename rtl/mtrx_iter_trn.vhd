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
entity mtrx_iter_trn is
  Generic (
    MTRX_AW : positive := 5 -- 2**MTRX_AW = max matrix index
  );
  Port (
    -- control interface
    rst_i  : in  std_logic; -- active high. Must be used before every new calculation
    clk_i  : in  std_logic;
    m_i    : in  std_logic_vector(MTRX_AW-1 downto 0); -- rows
    n_i    : in  std_logic_vector(MTRX_AW-1 downto 0); -- columns
    rdy_o  : out std_logic := '0'; -- active high 1 clock when last valid data presents on bus
    adr_o  : out std_logic_vector(2*MTRX_AW-1 downto 0)
  );
end mtrx_iter_trn;



-----------------------------------------------------------------------------
-- generates transposed addresses
--
architecture transpose of mtrx_iter_trn is

  signal m, n     : natural range 0 to 2**MTRX_AW-1     := 0;
  signal i, j     : natural range 0 to 2**MTRX_AW-1     := 0;
  signal adr      : natural range 0 to 2**(2*MTRX_AW)-1 := 0;
  signal big_step : natural range 0 to 2**(1+MTRX_AW)-1 := 0;
  
begin
  m <= to_integer(unsigned(m_i));
  n <= to_integer(unsigned(n_i));
  
  rdy_o <= '1' when (i = m and j = n and rst_i = '0') else '0';
  adr_o <= std_logic_vector(to_unsigned(adr, 2*MTRX_AW));
  
  main : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if (rst_i = '1') then
        i   <= 0;
        j   <= 0;
        adr <= 0;
        big_step <= m + 1;
      else
        adr <= adr + big_step;
        j <= j + 1;
        if (j = n) then
          j <= 0;
          adr <= i + 1;
          i   <= i + 1;
        end if;
      end if; -- rst
    end if; -- clk
  end process;

end transpose;



