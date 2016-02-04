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
entity mtrx_iter_trn is
  Generic (
    MTRX_AW : positive := 5 -- 2**MTRX_AW = max matrix index
  );
  Port (
    -- control interface
    rst_i  : in  std_logic; -- active high. Must be used before every new calculation
    clk_i  : in  std_logic;
    m_i    : in  std_logic_vector(MTRX_AW-1 downto 0); -- rows
    n_i    : in  std_logic_vector(MTRX_AW-1 downto 0); -- columns
    end_o  : out std_logic := '0'; -- active high 1 clock when last valid data presents on bus
    dv_o   : out std_logic := '0'; -- data valid (sitable for BRAM CE)
    adr_o  : out std_logic_vector(2*MTRX_AW-1 downto 0)
  );
end mtrx_iter_trn;



-----------------------------------------------------------------------------
-- generates transposed addresses
--
architecture transpose of mtrx_iter_trn is

  signal m, n     : natural range 0 to 2**MTRX_AW-1     := 0;
  signal i, j     : natural range 0 to 2**MTRX_AW-1     := 0;
  signal adr      : natural range 0 to 2**(2*MTRX_AW)-1 := 0;
  signal big_step : natural range 0 to 2**(1+MTRX_AW)-1 := 0;
  signal end_reg  : std_logic := '0';
  signal adr_reg  : std_logic_vector(2*MTRX_AW-1 downto 0);
  
  -- data valid tracker state
  type state_t is (IDLE, ACTIVE, HALT);
  signal state : state_t := IDLE;
  
begin

  m <= to_integer(unsigned(m_i));
  n <= to_integer(unsigned(n_i));
  
  end_o <= end_reg;
  adr_o <= adr_reg;
  
  main : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if (rst_i = '1') then
        i   <= 0;
        j   <= 0;
        adr <= 0;
        big_step <= m + 1;
      else
        if (i = m and j = n) then
          end_reg <= '1';
        else 
          end_reg <= '0';
        end if;
        adr_reg <= std_logic_vector(to_unsigned(adr, 2*MTRX_AW));

        adr <= adr + big_step;
        j <= j + 1;
        if (j = n) then
          j <= 0;
          adr <= i + 1;
          i   <= i + 1;
        end if;
      end if; -- rst
    end if; -- clk
  end process;


  dv_tracker : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if (rst_i = '1') then
        dv_o <= '0';
        state <= IDLE;
      else
        case state is
        when IDLE => 
          dv_o <= '1';
          state <= ACTIVE;
          
        when ACTIVE =>
          if (end_reg = '1') then
            dv_o <= '0';
            state <= HALT;
          end if;
          
        when HALT =>
          state <= HALT;
        end case;
      end if; -- rst
    end if; -- clk
  end process;


end transpose;



