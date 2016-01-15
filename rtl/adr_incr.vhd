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

--
-- multiply matrix A(m x p) by  B(p x n), put result in C(m x n)
--
entity adr_incr is
  Generic (
    WIDTH : positive := 5 -- number of bits needed for addressing matrix
  );
  Port (
    row_rdy_o : out std_logic; -- single pre multiplied row ready. Active high during 1 clock cycle
    mul_rdy_i : in std_logic; -- signal from multiplier (used for sum_adr_o increment)
    sum_rdy_i : in std_logic; -- signal from piramidal adder (used for c_adr_o increment)
    eoc_o : out std_logic; -- all data processed
    clk_i : in  std_logic;
    rst_i : in  std_logic;

    -- operands' dimensions
    m_i : in std_logic_vector(WIDTH-1 downto 0);
    n_i : in std_logic_vector(WIDTH-1 downto 0);
    p_i : in std_logic_vector(WIDTH-1 downto 0);

    -- address outputs
    a_adr_o   : out std_logic_vector(WIDTH*2-1 downto 0);
    b_adr_o   : out std_logic_vector(WIDTH*2-1 downto 0);
    c_adr_o   : out std_logic_vector(WIDTH*2-1 downto 0);
    sum_adr_o : out std_logic_vector(WIDTH-1   downto 0)
  );
end adr_incr;


-----------------------------------------------------------------------------

architecture beh of adr_incr is
  signal m_reg : std_logic_vector(WIDTH-1 downto 0);
  signal n_reg : std_logic_vector(WIDTH-1 downto 0);
  signal p_reg : std_logic_vector(WIDTH-1 downto 0);
  signal i : std_logic_vector (WIDTH-1 downto 0) := (others => '0');
  signal j : std_logic_vector (WIDTH-1 downto 0) := (others => '0');
  signal k : std_logic_vector (WIDTH-1 downto 0) := (others => '0');
  signal k_row : std_logic_vector (WIDTH-1 downto 0) := (others => '0');
begin
  
  --
  -- address for temporal buffer in piramidal adder
  --
  process(clk_i)
    variable cnt : std_logic_vector (WIDTH-1 downto 0) := (others => '0');
  begin
    if rising_edge(clk_i) then
      sum_adr_o <= cnt;
      if (rst_i = '1') then
        cnt := (others => '0');
        row_rdy_o <= '0';
      else
        if (mul_rdy_i = '1') then
          if (cnt = p_i) then
            cnt := (others => '0');
            row_rdy_o <= '1';
          else
            cnt := cnt + 1;
            row_rdy_o <= '0';
          end if;
        end if;
      end if;
    end if;
  end process;

  --
  -- input addreses generator
  --
  process(clk_i) 
--    variable i : std_logic_vector (WIDTH-1 downto 0) := (others => '0');
--    variable j : std_logic_vector (WIDTH-1 downto 0) := (others => '0');
--    variable k : std_logic_vector (WIDTH-1 downto 0) := (others => '0');
  begin
    if rising_edge(clk_i) then
      a_adr_o <= i*(p_i+1) + k;
      b_adr_o <= k*(n_i+1) + j;
      if (rst_i = '1') then
        i <= (others => '0');
        j <= (others => '0');
        k <= (others => '0');
      else
        k <= k+1;
        if (k = p_i) then
          j <= j+1;
          k <= (others => '0');
          if (j = n_i) then
            i <= i+1;
            j <= (others => '0');
            if (i = m_i) then
              i <= (others => '0');
            end if;
          end if;
        end if;
      end if;
    end if;
  end process;
  
  
  
  
  --
  -- output matrix address
  --
  process(clk_i)
    variable cnt : std_logic_vector(WIDTH*2-1 downto 0) := (others => '0');
  begin
    if rising_edge(clk_i) then
      c_adr_o <= cnt;
      if (rst_i = '1') then
        cnt := (others => '0');
        eoc_o <= '0';
      else
        if (sum_rdy_i = '1') then
          if (cnt = m_i * n_i) then
            eoc_o <= '1';
          else
            eoc_o <= '0';
          end if;
          cnt := cnt + 1;
        end if;
      end if;
    end if;
  end process;

  
end beh;


