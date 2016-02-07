library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.STD_LOGIC_UNSIGNED.ALL;

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
    -- active high. Must be used before every new calculation
    -- data sizes must be valid 1 clock before reset low
    rst_i  : in  std_logic;
    clk_i  : in  std_logic;
    ce_i   : in  std_logic;
    m_i    : in  std_logic_vector(MTRX_AW-1 downto 0); -- rows
    n_i    : in  std_logic_vector(MTRX_AW-1 downto 0); -- columns
    end_o  : out std_logic := '0'; -- active high 1 clock when last valid data presents on bus
    eye_o  : out std_logic := '0'; -- eye element strobe
    dv_o   : out std_logic := '0'; -- data valid (sitable for BRAM CE)
    adr_o  : out std_logic_vector(2*MTRX_AW-1 downto 0)
  );
end mtrx_iter_eye;


-----------------------------------------------------------------------------
-- Sequential iterator with eye signal
-- WARNING: Eye signal works correctly ONLY with square matrices
--
architecture eye of mtrx_iter_eye is
  
  signal m, n, i, j : natural range 0 to 2**MTRX_AW-1   := 0;
  signal adr        : natural range 0 to 2**(2*MTRX_AW)-1 := 0;
  signal big_step   : natural range 0 to 2**(1+MTRX_AW)-1 := 0;
  signal comparator : natural range 0 to 2**(2*MTRX_AW)-1 := 0;
  
  -- data valid tracker state
  type state_t is (ACTIVE, HALT);
  signal state : state_t := ACTIVE;
  
begin
  m <= to_integer(unsigned(m_i));
  n <= to_integer(unsigned(n_i));

 main : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if (rst_i = '1') then
        i   <= 0;
        j   <= 0;
        adr <= 0;
        end_o <= '0';
        state <= ACTIVE;
        big_step <= m + 2;
        comparator <= 0;
      else
        adr_o <= std_logic_vector(to_unsigned(adr, 2*MTRX_AW));
        dv_o  <= '1';
        end_o <= '0';
        if (comparator = adr) then
          eye_o <= '1';
        else 
          eye_o <= '0';
        end if;
        
        case state is
        when ACTIVE =>
          if ce_i = '1' then
            if (i = m and j = n) then
              end_o <= '1';
              state <= HALT;
            end if;
            adr <= adr + 1;
            j <= j + 1;
            if (j = n) then
              j <= 0;
              comparator <= comparator + big_step;
              i <= i + 1;
            end if;
          end if; -- ce
          
        when HALT =>
          dv_o <= '0';
          state <= HALT;
        end case;
      end if; -- rst
    end if; -- clk
  end process;


end eye;


