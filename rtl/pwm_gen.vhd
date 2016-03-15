library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity pwm_gen is

  generic (
    CLKIN_FREQ : integer := 80;         -- in MHz
    PWM_PERIOD : integer := 20000       -- us
    );
  port (
    clk         : in  std_logic;
    rst         : in  std_logic;        -- active high
    PWM_DATA_IN : in  std_logic_vector (15 downto 0);
    PWM_EN_IN   : in  std_logic;
    PWM_OUT     : out std_logic_vector (15 downto 0));

end entity pwm_gen;

architecture rtl of pwm_gen is

  signal clk_1mhz           : std_logic;
  signal clkdiv_cnt         : integer range 0 to (CLKIN_FREQ/2 - 1);
  type t_pwm_val is array (0 to 15) of std_logic_vector (15 downto 0);
  signal pwm_values         : t_pwm_val;
  signal pwm_values_latched : t_pwm_val;
  signal pwm_val_addr       : integer range 0 to 15;
  signal pwm_cnt            : std_logic_vector (15 downto 0);

begin
  process (clk, rst) is                 -- clock divider to 1MHz
  begin
    if rst = '1' then
      clk_1mhz   <= '0';
      clkdiv_cnt <= 0;
    elsif rising_edge(clk) then
      if clkdiv_cnt = (CLKIN_FREQ/2 - 1) then
        clkdiv_cnt <= 0;
        clk_1mhz   <= not clk_1mhz;
      else
        clkdiv_cnt <= clkdiv_cnt + 1;
      end if;
    end if;
  end process;

  process (clk, rst) is                 -- writing values to pwm registers
  begin
    if rst = '1' then
      pwm_val_addr <= 0;
    elsif rising_edge(clk) then
      if PWM_EN_IN = '1' then
        pwm_values(pwm_val_addr) <= PWM_DATA_IN;
        -- 16 pwm words
        if pwm_val_addr = 15 then
          pwm_val_addr <= 0;
        else
          pwm_val_addr <= pwm_val_addr + 1;
        end if;
      end if;
    end if;
  end process;

  process (clk_1mhz, rst) is            -- pwm counter (1-20000 us)
  begin
    if rst = '1' then
      pwm_cnt <= (0 => '1', others => '0');
    elsif rising_edge(clk_1mhz) then
      if (pwm_cnt = std_logic_vector(to_unsigned(PWM_PERIOD, 16))) then
        pwm_cnt            <= (0 => '1', others => '0');
        pwm_values_latched <= pwm_values;
      else
        pwm_cnt <= pwm_cnt + 1;
      end if;
    end if;
  end process;

  g_pwm : for i in 0 to 15 generate
    process (clk_1mhz) is
    begin
      if rising_edge(clk_1mhz) then
        if (pwm_cnt <= pwm_values_latched(i)) then  -- from 1 to pwm value
          PWM_OUT(i) <= '1';
        else
          PWM_OUT(i) <= '0';
        end if;
      end if;
    end process;
  end generate g_pwm;

end architecture rtl;
