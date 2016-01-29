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
-- multiply matrix A(m x p) by  B(p x n), put result in C(m x n)
-- Note: only A and B needs sophisticated addressing. C always uses 
-- simple sequential increment.
--
entity adr4mul is
  Generic (
    WIDTH : positive := 5 -- number of bits needed for addressing matrix
  );
  Port (
    clk_i : in  std_logic;
    rst_i : in  std_logic;
  
    row_rdy_o : out std_logic; -- single pre multiplied row ready. Active high during 1 clock cycle
    end_o : out std_logic; -- end if iteration. Active high 1 clock when final valid data present on adr buses
    dv_o : out std_logic; -- data valid

    -- operands' dimensions
    m_i : in std_logic_vector(WIDTH-1 downto 0);
    p_i : in std_logic_vector(WIDTH-1 downto 0);
    n_i : in std_logic_vector(WIDTH-1 downto 0);
    
    -- address outputs
    a_adr_o : out std_logic_vector(WIDTH*2-1 downto 0);
    b_adr_o : out std_logic_vector(WIDTH*2-1 downto 0)
  );
end adr4mul;


-----------------------------------------------------------------------------

architecture beh of adr4mul is
  
  constant ZERO  : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
  constant ZERO2 : std_logic_vector(2*WIDTH-1 downto 0) := (others => '0');
  
  --signal m, n, p : std_logic_vector(WIDTH-1 downto 0);
  signal i, j, k : std_logic_vector(WIDTH-1 downto 0) := ZERO;
  signal i_cnt, j_cnt, k_cnt : std_logic_vector(WIDTH-1 downto 0) := ZERO;
  signal i_end, j_end, k_end : std_logic := '0';

  signal big_step : std_logic_vector(2*WIDTH-1 downto 0) := ZERO2;

  signal j_reg : std_logic_vector(1*WIDTH-1 downto 0) := (others => '0');
  signal k_reg : std_logic_vector(2*WIDTH-1 downto 0) := (others => '0');
  
  signal j_end_reg : std_logic_vector(0 downto 0) := (others => '0');
  signal k_end_reg : std_logic_vector(1 downto 0) := (others => '0');
  
  signal i_end_adj : std_logic;
  signal j_end_adj : std_logic;
  signal k_end_adj : std_logic;

begin

  -- data fronts adjuster
  i_cnt <= i;
  j_cnt <= j_reg(1*WIDTH-1 downto 0*WIDTH);
  k_cnt <= k_reg(2*WIDTH-1 downto 1*WIDTH);
  i_end_adj <= i_end;
  j_end_adj <= j_end_reg(0);
  k_end_adj <= k_end_reg(1);
  adjuster : process(clk_i) 
  begin
    if rising_edge(clk_i) then
      if (rst_i = '1') then
        k_reg <= (others => '0');
        j_reg <= (others => '0');
        j_end_reg <= (others => '0');
        k_end_reg <= (others => '0');
      else
        k_reg <= k_reg(1*WIDTH-1 downto 0) & k;
        j_reg <= j;
        k_end_reg <= k_end_reg(0) & k_end;
        j_end_reg(0) <= j_end;
      end if;
    end if;
  end process;
  
  
  --
  --
  --
  step_latcher : process(clk_i) 
  begin
    if rising_edge(clk_i) then
      if (rst_i = '1') then
        big_step <= (ZERO & p_i) + 1;
      end if;
    end if;
  end process;


  --
  -- fastest counter
  --
  k_p_iterator : process(clk_i) 
  begin
    if rising_edge(clk_i) then
      k_end <= '0';
      if (rst_i = '1') then
        k <= ZERO;
      else
        if k = p_i then
          k <= ZERO;
          k_end <= '1';
        else
          k <= k + 1;
        end if;
      end if;
    end if;
  end process;
  
  
  --
  -- medium counter
  --
  j_n_iterator : process(clk_i) 
  begin
    if rising_edge(clk_i) then
      j_end <= '0';
      if (rst_i = '1') then
        j <= ZERO;
      else
        if (k_end = '1') then
          if j = n_i then
            j <= ZERO;
            j_end <= '1';
          else
            j <= j + 1;
          end if;
        end if;
      end if; -- rst
    end if; -- clk
  end process;
  
  --
  -- slowest counter
  --
  i_m_iterator : process(clk_i) 
  begin
    if rising_edge(clk_i) then
      i_end <= '0';
      if (rst_i = '1') then
        i <= ZERO;
      else
        if (j_end = '1') then
          if i = m_i then
            i <= ZERO;
            i_end <= '1';
          else
            i <= i + 1;
          end if;
        end if;
      end if; -- rst
    end if; -- clk
  end process;
  
  

  
  
  --
  --
  --
  a_counter : process(clk_i)
    variable tmp : std_logic_vector (2*WIDTH-1 downto 0) := ZERO2;
    variable j_delay : std_logic_vector (1 downto 0) := (others => '0');
  begin
    if rising_edge(clk_i) then
      if (rst_i = '1') then
        a_adr_o <= ZERO2;
        tmp := ZERO2;
        j_delay := (others => '0');
      else
        j_delay := j_delay(0) & j_end;
        if (j_delay(1) = '1') then
          tmp := tmp + big_step;
        end if;
        a_adr_o <= (ZERO & k_cnt) + tmp;
      end if;
    end if; -- clk
  end process;
  
  
  
  
  --
  --
  --
  b_counter : process(clk_i)
    variable tmp : std_logic_vector (2*WIDTH-1 downto 0) := ZERO2;
    variable small : std_logic_vector (2*WIDTH-1 downto 0) := ZERO2;
  begin
    if rising_edge(clk_i) then
      if (rst_i = '1') then
        b_adr_o <= ZERO2;
        tmp := ZERO2;
      else
        if (j_cnt = n_i) then
          small := small + 1;
          tmp := ZERO2;
        end if;
        tmp := tmp + big_step;
        b_adr_o <= small + tmp;
      end if;
    end if; -- clk
  end process;
  
  
  
--  --
--  -- input addresses generator
--  --
--  process(clk_i) 
--    --variable i,j,k : std_logic_vector (WIDTH-1 downto 0);
--  begin
--    if rising_edge(clk_i) then
--      
--      row_rdy_o <= '0';
--      end_o <= '0';
--      
--      if (rst_i = '1') then
--        state <= IDLE;
--        i <= (others => '0');
--        j <= (others => '0');
--        k <= (others => '0');
--        m <= (others => '0');
--        p <= (others => '0');
--        n <= (others => '0');
--        dv_o  <= '0';
--      else
--        case state is
--        when IDLE =>
--          dv_o  <= '0';
--          m <= '0' & m_i;
--          p <= '0' & p_i;
--          n <= '0' & n_i;
--          state <= ACTIVE;
--
--        when ACTIVE =>
--          dv_o <= '1';
--          
--          k <= k+1;
--          if (k = p) then
--            j <= j+1;
--            k <= (others => '0');
--            row_rdy_o <= '1';
--            if (j = n) then
--              i <= i+1;
--              j <= (others => '0');
--              if (i = m) then
--                i <= (others => '0');
--                end_o <= '1';
--                state <= IDLE;
--              end if;
--            end if;
--          end if;
--        end case;
--
--      end if; -- rst
--    end if; -- clk
--  end process;
--
--  --
--  --  multiplication based code
--  --
--  process(clk_i) 
--    variable a, b : std_logic_vector(2*WIDTH downto 0);
--  begin
--    if rising_edge(clk_i) then
--      if (rst_i = '1') then
--        a_adr_o <= (others => '0');
--        b_adr_o <= (others => '0');
--      else
--        if state = ACTIVE then
--          if (a_tran_i = '0') then
--            a := i*(p+1) + k; -- [i*p + k]
--          else
--            a := k*(m+1) + i; -- [k*m + i]
--          end if;
--          if (b_tran_i = '0') then
--            b := k*(n+1) + j; -- [k*n + j]
--          else
--            b := j*(p+1) + k; -- [j*p + k]
--          end if;
--          
--          a_adr_o <= a(2*WIDTH-1 downto 0);
--          b_adr_o <= b(2*WIDTH-1 downto 0);
--        end if;
--      end if;
--    end if; -- clk
--  end process;


end beh;


