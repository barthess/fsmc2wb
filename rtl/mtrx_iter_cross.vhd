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
entity mtrx_iter_cross is
  Generic (
    WIDTH : positive := 5 -- number of bits needed for addressing matrix
  );
  Port (
    clk_i : in  std_logic;
    rst_i : in  std_logic;

    -- end if iteration. Active high 1 clock when final valid data on address buses
    end_o : out std_logic := '0';
    
    -- operands' dimensions
    m_i : in std_logic_vector(WIDTH-1 downto 0);
    p_i : in std_logic_vector(WIDTH-1 downto 0);
    n_i : in std_logic_vector(WIDTH-1 downto 0);
    
    -- address outputs
    a_adr_o : out std_logic_vector(WIDTH*2-1 downto 0) := (others => '1');
    b_adr_o : out std_logic_vector(WIDTH*2-1 downto 0) := (others => '1')
  );
end mtrx_iter_cross;


-----------------------------------------------------------------------------

architecture beh of mtrx_iter_cross is
  
  constant ZERO  : std_logic_vector(WIDTH-1 downto 0)   := (others => '0');
  constant ZERO2 : std_logic_vector(2*WIDTH-1 downto 0) := (others => '0');
  
  signal i, j, k : std_logic_vector(WIDTH-1 downto 0) := ZERO;
  
  signal ja, ka : std_logic_vector(WIDTH-1 downto 0) := ZERO;
  signal jb, kb : std_logic_vector(WIDTH-1 downto 0) := ZERO;
  signal a_tmp  : std_logic_vector (2*WIDTH-1 downto 0) := ZERO2;
  signal b_tmp  : std_logic_vector (2*WIDTH-1 downto 0) := ZERO2;
  
  signal big_step_a : std_logic_vector(WIDTH downto 0) := (others => '0');
  signal big_step_b : std_logic_vector(WIDTH downto 0) := (others => '0');
  
  type state_t is (IDLE, ACTIVE);
  signal state : state_t := IDLE;
  
begin

  --
  --
  --
  big_step_sample_proc : process(clk_i) 
  begin
    if rising_edge(clk_i) then
      if (rst_i = '1') then
        big_step_a <= ('0' & p_i) + 1;
        big_step_b <= ('0' & n_i) + 1;
      end if;
    end if;
  end process;
  
  --
  --
  --
  a_counter : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if (rst_i = '1') then
        a_tmp <= ZERO2;
        ka <= ZERO;
        ja <= ZERO;
      else
        a_adr_o <= a_tmp + ka;
        ka <= ka + 1;
        if (ka = p_i) then
          ka <= ZERO;
          ja <= ja + 1;
          if (ja = n_i) then
            a_tmp <= a_tmp + big_step_a;
            ja <= ZERO;
          end if;
        end if;
      end if;
    end if; -- clk
  end process;

  --
  --
  --
  b_counter : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if (rst_i = '1') then
        b_tmp <= ZERO2;
        kb <= ZERO;
        jb <= ZERO;
      else
        b_adr_o <= b_tmp;
        b_tmp <= b_tmp + big_step_b;
        kb <= kb + 1;
        if (kb = p_i) then
          kb <= ZERO;
          jb <= jb + 1;
          if (jb = n_i) then
            jb <= ZERO;
            b_tmp <= ZERO2;
          else
            b_tmp <= ZERO & jb + 1;
          end if;
        end if;
      end if; -- rst
    end if; -- clk
  end process;


  --
  --
  --
  end_generator : process(clk_i) 
  begin
    if rising_edge(clk_i) then
      end_o <= '0';
      if (rst_i = '1') then
        i <= ZERO;
        j <= ZERO;
        k <= ZERO;
      else
        k <= k+1;
        if (k = p_i) then
          j <= j+1;
          k <= ZERO;
          if (j = n_i) then
            i <= i+1;
            j <= ZERO;
            if (i = m_i) then
              i <= ZERO;
              end_o <= '1';
            end if;
          end if;
        end if;
      end if; -- rst
    end if; -- clk
  end process;




-- этот вариант умеет корректоно взводить сигнал окончания
-- при вырожденном случае, но при синтезе получается сликом
-- медленным
--  end_generator : process(clk_i) 
--  begin
--    if rising_edge(clk_i) then
--      end_o <= '0';
--      if (rst_i = '1') then
--        i <= ZERO;
--        j <= ZERO;
--        k <= ZERO;
--        state <= ACTIVE;
--      else
--        case state is
--        when ACTIVE =>
--          k <= k+1;
--          if (k = p_i) then
--            j <= j+1;
--            k <= ZERO;
--            if (j = n_i) then
--              i <= i+1;
--              j <= ZERO;
--              if (i = m_i) then
--                i <= ZERO;
--                end_o <= '1';
--                state <= IDLE;
--              end if;
--            end if;
--          end if;
--          
--        when IDLE =>
--          end_o <= '0';
--        end case;
--      end if; -- rst
--    end if; -- clk
--  end process;


end beh;


