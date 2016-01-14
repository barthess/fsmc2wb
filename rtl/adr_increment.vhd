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
entity adr_increment is
  Generic (
    WIDTH : positive -- number of bits for addressing square matrix dimension
  );
  Port (
    row_rdy_o : out std_logic; -- single multiplied row ready. Active high during 1 clock cycle
    mul_rdy_i : in std_logic;
    sum_rdy_i : in std_logic;
    eoc_o : out std_logic; -- all data iterated 
    clk_i : in  std_logic;
    rst_i : in  std_logic;

    -- operands' dimensions
    m_i : in std_logic_vector(WIDTH-1 downto 0);
    n_i : in std_logic_vector(WIDTH-1 downto 0);
    p_i : in std_logic_vector(WIDTH-1 downto 0);

    -- address outputs
    a_adr_o   : out std_logic_vector(4**WIDTH-1 downto 0);
    b_adr_o   : out std_logic_vector(4**WIDTH-1 downto 0);
    c_adr_o   : out std_logic_vector(4**WIDTH-1 downto 0);
    sum_adr_o : out std_logic_vector(2**WIDTH-1 downto 0);
  );
end mul;


-----------------------------------------------------------------------------

architecture beh of mul is
  signal m_reg : std_logic_vector(WIDTH-1 downto 0);
  signal n_reg : std_logic_vector(WIDTH-1 downto 0);
  signal p_reg : std_logic_vector(WIDTH-1 downto 0);
begin
  
  
  process(clk_i)
    variable cnt : std_logic_vector (WIDTH-1 downto 0) := 0;
  begin
    if rising_edge(clk_i) then
      sum_adr_o <= cnt;
      if (rst_i = 1) then
        cnt := 0;
      else
        if (mul_rdy_i = '1') then
          cnt := cnt + 1;
          if (cnt > m_i) then
            cnt := 0;
          end if;
        end if;
      end if;
    end if;
  end process;



  process(clk_i) 
    variable i : std_logic_vector (WIDTH-1 downto 0) := 0;
    variable j : std_logic_vector (WIDTH-1 downto 0) := 0;
    variable k : std_logic_vector (WIDTH-1 downto 0) := 0;
  begin
    if rising_edge(clk_i) then
      a_adr_o <= i*p_i + k;
      b_adr_o <= k*n_i + j;
      if (rst_i = 1) then
        i <= 0;
        j <= 0;
        k <= 0;
      else
        k := k+1;
        if (k = p_i) then
          j := j+1;
          k := 0;
          if (j = n_i) then
            i := i+1;
            j := 0;
            if (i = m_i) then
              i := 0;
              EOF <= '1';
            end if;
          end if;
        end if;
      end if;
    end if;
  end process;
  


  process(clk_i)
    variable cnt : (std_logic_vector(4**WIDTH-1 downto 0) := 0;
  begin
    if rising_edge(clk_i) then
      c_adr_o <= cnt;
      if (rst_i = 1) then
        cnt <= 0;
      else
        if (sum_rdy = '1') then
          cnt := cnt + 1;
        end if;
      end if;
    end if;
  end process;


  
  
end beh;




