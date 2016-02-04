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
  constant ZERO  : std_logic_vector(MTRX_AW-1   downto 0) := (others => '0');
  constant ZERO2 : std_logic_vector(2*MTRX_AW-1 downto 0) := (others => '0');
  signal m, n : std_logic_vector(MTRX_AW-1 downto 0) := ZERO;
  signal adr : std_logic_vector(2*MTRX_AW-1 downto 0) := ZERO2;
  signal big_step : std_logic_vector(2*MTRX_AW-1 downto 0) := ZERO2;
begin
  
  rdy_o <= '1' when (m = m_i and n = n_i and rst_i = '0') else '0';
  adr_o <= adr;
  
  main : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if (rst_i = '1') then
        m   <= ZERO;
        n   <= ZERO;
        adr <= ZERO2;
        big_step <= (ZERO & m_i) + 1;
      else
        adr <= adr + big_step;
        n <= n+ 1;
        if (n = n_i) then
          n <= ZERO;
          adr <= (ZERO & m) + 1;
          m <= m + 1;
        end if;
      end if; -- rst
    end if; -- clk
  end process;

end transpose;



