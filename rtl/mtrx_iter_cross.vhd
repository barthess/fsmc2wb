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
    ce_i  : in  std_logic;
    
    -- end if iteration. Active high 1 clock when final valid data on address buses
    end_o : out std_logic := '0';
    -- data valid
    dv_o  : out std_logic := '0';
    
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
  -- overall algorithm latency
  constant LATENCY : std_logic_vector(1 downto 0) := "10";
  
  signal j, k : std_logic_vector(WIDTH-1 downto 0) := ZERO;
  signal i_incr, j_incr, j_incr_generator : std_logic := '0';

  signal big_step_a : std_logic_vector(WIDTH downto 0) := (others => '0');
  signal big_step_b : std_logic_vector(WIDTH downto 0) := (others => '0');
  
  -- data valid tracker state
  type state_t is (IDLE, ACTIVE, HALT);
  signal state : state_t := IDLE;
  
  signal a_adr_reg, b_adr_reg : std_logic_vector(2*WIDTH-1 downto 0) := (others => '0');
  signal end_reg, dv_reg : std_logic := '0';
  
begin

  --
  --
  --
--  output_registering : process(clk_i) 
--  begin
--    if rising_edge(clk_i) then
--      if (rst_i = '0' and ce_i = '1') then
        a_adr_o <= a_adr_reg;
        b_adr_o <= b_adr_reg;
        end_o   <= end_reg;
        dv_o    <= dv_reg;
--      end if;
--    end if;
--  end process;
  
  --
  --
  --
  data_sample : process(clk_i) 
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
  k_counter : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if (rst_i = '1') then
        k <= p_i;
        j_incr <= '0';
      else
        if ce_i = '1' then
          k <= k - 1;
        end if;
        if k = 0 then
          k <= p_i;
          j_incr <= '1';
        else
          j_incr <= '0';
        end if;
      end if; -- ce
    end if; -- clk
  end process;
  
  --
  --
  --
  j_counter : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if (rst_i = '1') then
        j <= n_i;
        i_incr <= '0';
      else
        i_incr <= '0';
        if (ce_i = '1') and (j_incr = '1') then
          j <= j - 1;
          if j = 0 then
            j <= n_i;
            i_incr <= '1';
          end if;
        end if;
      end if; -- ce
    end if; -- clk
  end process;

  --
  --
  --
  dv_tracker : process(clk_i)
    variable delay : std_logic_vector(1 downto 0) := LATENCY;
  begin
    if rising_edge(clk_i) then
      if (rst_i = '1') then
        dv_reg <= '0';
        delay := LATENCY;
        state <= IDLE;
      else
        if ce_i = '1' then
          if delay = 0 then
            case state is
            when IDLE =>
              dv_reg <= '1';
              state <= ACTIVE;
            when ACTIVE =>
              if (end_reg = '1') then
                dv_reg <= '0';
                state <= HALT;
              end if;
            when HALT =>
              state <= HALT;
            end case;
          else
            delay := delay - 1;
          end if; -- delay
        end if; -- ce
      end if; -- rst
    end if; -- clk
  end process;

  --
  -- delay line for address calculator logic
  j_incr_delay : entity work.delay
  generic map (
    WIDTH => 1,
    LAT => 1,
    default => '0'
  )
  port map (
    clk => clk_i,
    ce => ce_i,
    di(0) => j_incr,
    do(0) => j_incr_generator
  );

  --
  --
  --
  a_generator : process(clk_i)
    variable a_tmp : std_logic_vector(2*WIDTH-1 downto 0) := ZERO2;
    variable ka : std_logic_vector(WIDTH-1 downto 0) := ZERO;
    variable ia : std_logic_vector(WIDTH-1 downto 0) := ZERO; -- end tracker
    variable delay : std_logic_vector(1 downto 0) := LATENCY;
  begin
    if rising_edge(clk_i) then
      if (rst_i = '1') then
        a_tmp := ZERO2;
        ka := ZERO;
        ia := m_i;
        delay := LATENCY;
        end_reg <= '0';
      else
        end_reg <= '0';
        if ce_i = '1' then
          if delay = 0 then
            a_adr_reg <= a_tmp + ka;
            ka := ka + 1;
            if (j_incr_generator = '1') then
              ka := ZERO;
              if (i_incr = '1') then
                a_tmp := a_tmp + big_step_a;
                
                if ia = 0 then
                  end_reg <= '1';
                end if;
                ia := ia - 1;
                
              end if;
            end if;
          else
            delay := delay - 1;
          end if; -- delay
        end if; -- ce
      end if; -- rst 
    end if; -- clk
  end process;

  --
  --
  --
  b_generator : process(clk_i)
    variable b_tmp : std_logic_vector(2*WIDTH-1 downto 0) := ZERO2;
    variable kb : std_logic_vector(WIDTH-1 downto 0) := ZERO;
    variable delay : std_logic_vector(1 downto 0) := LATENCY;
  begin
    if rising_edge(clk_i) then
      if (rst_i = '1') then
        b_tmp := ZERO2;
        kb := ZERO;
        delay := LATENCY;
      else
        if ce_i = '1' then
          if delay = 0 then
            b_adr_reg <= b_tmp;
            b_tmp := b_tmp + big_step_b;
            if (j_incr_generator = '1') then
              kb := kb + 1;
              b_tmp := ZERO & kb;
              if (i_incr = '1') then
                b_tmp := ZERO2;
                kb := ZERO;
              end if;
            end if;
          else
            delay := delay - 1;
          end if; -- delay
        end if; -- ce
      end if; -- rst
    end if; -- clk
  end process;
  

end beh;


