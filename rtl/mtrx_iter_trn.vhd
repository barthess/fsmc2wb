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
    -- active high. Must be used before every new calculation
    -- data sizes must be valid 1 clock before reset low
    rst_i  : in  std_logic;
    clk_i  : in  std_logic;
    ce_i   : in  std_logic;
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

  type state_t is (ACTIVE, HALT);
  signal state : state_t := ACTIVE;
  
begin

  m <= to_integer(unsigned(m_i));
  n <= to_integer(unsigned(n_i));
  
  adr_o <= std_logic_vector(to_unsigned(adr, 2*MTRX_AW));
  end_o <= '1' when (rst_i = '0' and ce_i = '1' and i = m and j = n) else '0';
  dv_o  <= '1' when (rst_i = '0' and ce_i = '1' and state /= HALT) else '0';
  
  main : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if (rst_i = '1') then
        i   <= 0;
        j   <= 0;
        adr <= 0;
        state <= ACTIVE;
        big_step <= m + 1;
      else
        case state is
        when ACTIVE =>
          if ce_i = '1' then
            if (i = m and j = n) then
              state <= HALT;
            end if;
            adr <= adr + big_step;
            j <= j + 1;
            if (j = n) then
              j <= 0;
              adr <= i + 1;
              i   <= i + 1;
            end if;
          end if; -- ce
          
        when HALT =>
          state <= HALT;
        end case;
      end if; -- rst
    end if; -- clk
  end process;


end transpose;



