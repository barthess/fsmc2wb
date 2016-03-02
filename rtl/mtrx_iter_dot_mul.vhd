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
    
    -- transpose flags for B operand
    tb_i : in std_logic;
    --ta_i : in std_logic;
    
    -- address outputs
    a_adr_o : out std_logic_vector(WIDTH*2-1 downto 0) := (others => '1');
    b_adr_o : out std_logic_vector(WIDTH*2-1 downto 0) := (others => '1')
  );
end mtrx_iter_dot_mul;


-----------------------------------------------------------------------------

architecture beh of mtrx_iter_dot_mul is
  
  constant ZERO  : std_logic_vector(WIDTH-1 downto 0)   := (others => '0');
  constant ZERO2 : std_logic_vector(2*WIDTH-1 downto 0) := (others => '0');
  
  signal i, j, k : std_logic_vector(WIDTH-1 downto 0);
  signal id1, jd1, kd1, id2, jd2, kd2 : std_logic_vector(WIDTH-1 downto 0);
  signal m, p, n : std_logic_vector(WIDTH-1 downto 0);
  signal m1, p1, n1 : std_logic_vector(WIDTH-1 downto 0);
  signal ip1, km1, kn1, jp1 : std_logic_vector(2*WIDTH-1 downto 0);

  -- data valid tracker state
  type state_t is (IDLE, PRELOAD1, PRELOAD2, ACTIVE, HALT);
  signal state : state_t := IDLE;
  
  signal a0,  a1,  a2,  b0,  b1,  b2  : std_logic_vector(2*WIDTH-1 downto 0) := ZERO2;
  signal at0, at1, at2, bt0, bt1, bt2 : std_logic_vector(2*WIDTH-1 downto 0) := ZERO2;
  signal end_wire : std_logic := '0';
  signal end_reg  : std_logic := '0';
  
begin

  --a_adr_o <= a2 when (ta_i = '0') else at2;
  --b_adr_o <= b2 when (tb_i = '0') else bt2;

  end_o <= end_reg;
  
  end_delay : entity work.delay
  generic map (
    LAT => 3,
    WIDTH => 1,
    default => '0'
  )
  port map (
    clk   => clk_i,
    ce    => ce_i,
    di(0) => end_wire,
    do(0) => end_reg
  );

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
  -- [i*p + k] => [i*(p_i + 1) + k] => [i*p_i + i + k]
  --
  data_pipeline : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if (rst_i = '0') and (ce_i = '1') then
        id1 <= i;
        jd1 <= j;
        jd2 <= jd1;
        kd1 <= k;
        kd2 <= kd1;
        
        a0 <= i*p;
        a1 <= a0 + id1;
        a2 <= a1 + kd2;
        
        b0 <= k*n;
        b1 <= b0 + kd1;
        b2 <= b1 + jd2;

        bt0 <= j*p;
        bt1 <= bt0 + jd1;
        bt2 <= bt1 + kd2;

        a_adr_o <= a2;

        if (tb_i = '0') then
          b_adr_o <= b2;
        else 
          b_adr_o <= bt2;
        end if;

      end if; -- rst & ce
    end if; -- clk
  end process;

  --
  --
  --
  address_proc : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if (rst_i = '1') then
        state <= IDLE;
      else
        if ce_i = '1' then
          case state is
          when IDLE =>
            state <= PRELOAD1;
            
          when PRELOAD1 =>
            state <= PRELOAD2;
            
          when PRELOAD2 =>
            state <= ACTIVE;
            
          when ACTIVE =>
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

