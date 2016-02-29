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
entity mtrx_iter_dot_mul is
  Generic (
    WIDTH : positive := 5 -- number of bits needed for addressing matrix
  );
  Port (
    clk_i : in  std_logic;
    rst_i : in  std_logic;
    ce_i  : in  std_logic;
    
    -- end if iteration. Active high 1 clock when final valid data on address buses
    end_o : out std_logic := '0';
    -- data valid
    dv_o  : out std_logic := '0';
    
    -- operands' dimensions
    m_i : in std_logic_vector(WIDTH-1 downto 0);
    p_i : in std_logic_vector(WIDTH-1 downto 0);
    n_i : in std_logic_vector(WIDTH-1 downto 0);
    
    -- transpose flags for operands
    ta_i : in std_logic;
    tb_i : in std_logic;
    
    -- address outputs
    a_adr_o : out std_logic_vector(WIDTH*2-1 downto 0) := (others => '1');
    b_adr_o : out std_logic_vector(WIDTH*2-1 downto 0) := (others => '1')
  );
end mtrx_iter_dot_mul;


-----------------------------------------------------------------------------

architecture beh of mtrx_iter_dot_mul is
  
  constant ZERO  : std_logic_vector(WIDTH-1 downto 0)   := (others => '0');
  --constant ZERO  : std_logic_vector(WIDTH downto 0)   := (others => '0');
  constant ZERO2 : std_logic_vector(2*WIDTH+1 downto 0) := (others => '0');
  
  signal i, j, k : std_logic_vector(WIDTH-1 downto 0);
  signal id, jd, kd : std_logic_vector(WIDTH-1 downto 0);
  signal m, p, n : std_logic_vector(WIDTH-1 downto 0);
  signal m1, p1, n1 : std_logic_vector(WIDTH-1 downto 0);
  signal ip1, km1, kn1, jp1 : std_logic_vector(2*WIDTH-1 downto 0);

  -- data valid tracker state
  type state_t is (IDLE, ACTIVE, HALT);
  signal state : state_t := IDLE;
  
  signal a_adr_reg, at_adr_reg, b_adr_reg, bt_adr_reg : std_logic_vector(2*WIDTH-1 downto 0) := (others => '0');
  signal end_wire : std_logic := '0';
  signal end_reg  : std_logic := '0';

begin

  b_adr_o <= b_adr_reg(2*WIDTH-1 downto 0) when (tb_i = '0') else bt_adr_reg(2*WIDTH-1 downto 0);
  a_adr_o <= a_adr_reg(2*WIDTH-1 downto 0) when (ta_i = '0') else at_adr_reg(2*WIDTH-1 downto 0);
  end_o <= end_reg;

  --
  --
  --
  counters : process(clk_i) 
  begin
    if rising_edge(clk_i) then
      if (rst_i = '1') then
        i <= ZERO;
        j <= ZERO;
        k <= ZERO;
        m <= m_i;
        p <= p_i;
        n <= n_i;
        end_wire <= '0';
      else
        if ce_i = '1' then
          end_wire <= '0';
          k <= k+1;
          if k = p then
            j <= j+1;
            k <= ZERO;
            if j = n then
              i <= i+1;
              j <= ZERO;
              if i = m then
                end_wire <= '1';
              end if;
            end if;
          end if;
        end if;
      end if;
    end if;
  end process;
  
  --
  --
  --
  delay_proc : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if (rst_i = '1') then
        id <= (others => '0');
        jd <= (others => '0');
        kd <= (others => '0');
      else
        if ce_i = '1' then
          id <= i;
          jd <= j;
          kd <= k;
          end_reg <= end_wire;
        end if; -- ce
      end if; -- rst
    end if; -- clk
  end process;

  --
  --
  --
  address_proc : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if (rst_i = '1') then
        m1 <= m_i - "11111";
        p1 <= p_i - "11111";
        n1 <= n_i - "11111";
        state <= IDLE;
      else
        if ce_i = '1' then
          case state is
          when IDLE =>
            ip1 <= i * p1;
            km1 <= k * m1;
            kn1 <= k * n1;
            jp1 <= j * p1;
            state <= ACTIVE;

          when ACTIVE =>
            ip1 <= i * p1;
            km1 <= k * m1;
            kn1 <= k * n1;
            jp1 <= j * p1;
            
            a_adr_reg  <= ip1 + kd;
            at_adr_reg <= km1 + id;
            b_adr_reg  <= kn1 + jd;
            bt_adr_reg <= jp1 + kd;
            
            dv_o <= '1';

            
            if end_reg = '1' then
              dv_o <= '0';
              state <= HALT;
            end if;
          when HALT =>
            state <= HALT;
          end case;
        end if; -- ce
      end if; -- rst
    end if; -- clk
  end process;
  

end beh;

