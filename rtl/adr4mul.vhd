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
    ce_i  : in  std_logic;
  
    row_rdy_o : out std_logic; -- single pre multiplied row ready. Active high during 1 clock cycle
    eoi_o : out std_logic; -- end if iteration. Active high 1 clock when final valid data present on adr buses
    dv_o : out std_logic; -- data valid

    -- operands' dimensions. Do NOT change them when iteration active
    m_i : in std_logic_vector(WIDTH-1 downto 0);
    p_i : in std_logic_vector(WIDTH-1 downto 0);
    n_i : in std_logic_vector(WIDTH-1 downto 0);
    
    -- address outputs
    a_adr_o : out std_logic_vector(WIDTH*2-1 downto 0);
    b_adr_o : out std_logic_vector(WIDTH*2-1 downto 0);
    
    -- transposition flags. 1 means true
    a_tran_i : in  std_logic;
    b_tran_i : in  std_logic
  );
end adr4mul;


-----------------------------------------------------------------------------

architecture beh of adr4mul is
  signal m, n, p : std_logic_vector(WIDTH downto 0);
  signal i, j, k : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
  type state_t is (IDLE, ACTIVE);
  signal state : state_t := IDLE;
  -- iteration helpers allowing to avoid multiplication
--  signal a_row : std_logic_vector(WIDTH*2-1 downto 0) := (others => '0');
--  signal b_col : std_logic_vector(WIDTH*2-1 downto 0) := (others => '0');
--  signal b_col_base : std_logic_vector(WIDTH*2-1 downto 0) := (others => '0');
begin
  
  --
  -- input addresses generator
  --
  process(clk_i) 
    --variable i,j,k : std_logic_vector (WIDTH-1 downto 0);
  begin
    if rising_edge(clk_i) then
      if (rst_i = '1') then
        state <= IDLE;
        i <= (others => '0');
        j <= (others => '0');
        k <= (others => '0');
        eoi_o <= '0';
        dv_o  <= '0';
        row_rdy_o <= '0';
      else
        if (ce_i = '1') then
          case state is
          when IDLE =>
            dv_o  <= '0';
            eoi_o <= '0';
            m <= '0' & m_i;
            p <= '0' & p_i;
            n <= '0' & n_i;
            state <= ACTIVE;

          when ACTIVE =>
            dv_o <= '1';
            
            k <= k+1;
            if (k = p) then
              j <= j+1;
              k <= (others => '0');
              row_rdy_o <= '1';
              if (j = n) then
                i <= i+1;
                j <= (others => '0');
                if (i = m) then
                  i <= (others => '0');
                  eoi_o <= '1';
                  state <= IDLE;
                end if;
              end if;
            else
              row_rdy_o <= '0';
            end if;
          end case;
          
        end if; -- ce_i
      end if;
    end if;
  end process;

  --
  --  multiplication based code
  --
  process(clk_i) 
  variable a, b : std_logic_vector(2*WIDTH downto 0);
  begin
    if rising_edge(clk_i) then
      if (rst_i = '1') then
        a_adr_o <= (others => '0');
        b_adr_o <= (others => '0');
      else
        if (ce_i = '1' and state = ACTIVE) then
          if (a_tran_i = '0') then
            a := i*(p+1) + k;
          else
            a := k*(m+1) + i; -- [k*m + i]
          end if;
          if (b_tran_i = '0') then
            b := k*(n+1) + j; -- [k*n + j]
          else
            b := j*(p+1) + k; -- [j*p + k]
          end if;
          
          a_adr_o <= a(2*WIDTH-1 downto 0);
          b_adr_o <= b(2*WIDTH-1 downto 0);
        end if;
      end if;
    end if; -- clk
  end process;


  --
  -- sum based code
  --
--  process(clk_i) 
--  begin
--    if rising_edge(clk_i) then
--      if (rst_i = '1') then
--        a_adr_o <= (others => '0');
--        b_adr_o <= (others => '0');
--      else
--        if (ce_i = '1' and state = ACTIVE) then
--          a_adr_o <= a_row + k;
--          b_adr_o <= b_col;
--        end if;
--      end if;
--    end if; -- clk
--  end process;

end beh;


