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
entity mtrx_iter_eye is
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
    eye_o  : out std_logic := '0'; -- eye element strobe
    adr_o  : out std_logic_vector(2*MTRX_AW-1 downto 0)
  );
end mtrx_iter_eye;


-----------------------------------------------------------------------------
-- Sequential iterator with eye signal
-- WARNING: Eye signal works correctly ONLY with square matrices
--
architecture eye of mtrx_iter_eye is
  constant ZERO  : std_logic_vector(MTRX_AW-1   downto 0) := (others => '0');
  constant ZERO2 : std_logic_vector(2*MTRX_AW-1 downto 0) := (others => '0');
  signal m, n : std_logic_vector(MTRX_AW-1 downto 0) := ZERO;
  signal adr : std_logic_vector(2*MTRX_AW-1 downto 0) := ZERO2;
  signal big_step : std_logic_vector(2*MTRX_AW-1 downto 0) := ZERO2;
  signal comparator : std_logic_vector(2*MTRX_AW-1 downto 0) := ZERO2;
begin
  
  rdy_o <= '1' when (m = m_i and n = n_i and rst_i = '0') else '0';
  eye_o <= '1' when (comparator = adr) else '0';
  adr_o <= adr;
  
  main : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if (rst_i = '1') then
        m   <= ZERO;
        n   <= ZERO;
        adr <= ZERO2;
        big_step <= (ZERO & m_i) + 2;
        comparator <= ZERO2;
      else
        adr <= adr + 1;
        n <= n + 1;
        if (n = n_i) then
          n <= ZERO;
          comparator <= comparator + big_step;
          m <= m + 1;
        end if;
      end if; -- rst
    end if; -- clk
  end process;

end eye;


