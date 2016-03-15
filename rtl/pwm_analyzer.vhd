library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity pwm_analyzer is

  generic (
    CLKIN_FREQ : integer := 80;         -- MHz
    PWM_PERIOD : integer := 22000);     -- us

  port (
    clk          : in  std_logic;
    rst          : in  std_logic;       -- active high
    PWM_IN       : in  std_logic;
    PWM_DATA_OUT : out std_logic_vector (15 downto 0));  -- MSB is 'channel off'

end entity pwm_analyzer;

architecture ch_pwm of pwm_analyzer is  -- regular pwm channels

  signal clk_1mhz   : std_logic;
  signal clkdiv_cnt : integer range 0 to (CLKIN_FREQ/2 - 1);

  signal pwm_prev : std_logic_vector (1 downto 0);  -- previous values for edge detection
  type t_edge is (rising, falling, none);
  signal edge     : t_edge := none;     -- pwm edge

  signal pwm_cnt : std_logic_vector (14 downto 0);
  type t_state is (idle, count);
  signal state   : t_state;

  signal wd_cnt          : integer range 0 to PWM_PERIOD-1;  -- pwm watchdog
  signal transition_flag : std_logic;
  signal pwm_chan_off    : std_logic;

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

  process (clk_1mhz) is                 -- edge detection
  begin
    if rising_edge(clk_1mhz) then
      if (pwm_prev = "01") then
        edge <= rising;
      elsif (pwm_prev = "10") then
        edge <= falling;
      else
        edge <= none;
      end if;
      -- two stages prevent occasional misdetection
      pwm_prev(0) <= PWM_IN;
      pwm_prev(1) <= pwm_prev(0);
    end if;
  end process;

  process (clk_1mhz, rst) is            -- pwm counter
  begin
    if rst = '1' then
      state   <= idle;
      pwm_cnt <= (others => '0');
    elsif rising_edge(clk_1mhz) then
      case state is
        when idle =>
          if edge = rising then
            state   <= count;
            pwm_cnt <= (0 => '1', others => '0');
          else
            state   <= idle;
            pwm_cnt <= (others => '0');
          end if;
        when count =>
          if edge = falling then
            state        <= idle;
            PWM_DATA_OUT <= pwm_chan_off & pwm_cnt;  -- MSB flag
            pwm_cnt      <= (others => '0');
          else
            state   <= count;
            pwm_cnt <= pwm_cnt + 1;
          end if;
      end case;
    end if;
  end process;

  process (clk_1mhz) is                 -- pwm watchdog
  begin  -- detects if pwm is present
    if rising_edge(clk_1mhz) then
      if wd_cnt = PWM_PERIOD-1 then
        wd_cnt <= 0;
        if transition_flag = '1' then
          pwm_chan_off <= '0';
        else
          pwm_chan_off <= '1';
        end if;
        transition_flag <= '0';
      else
        wd_cnt <= wd_cnt + 1;
        if edge = rising then
          transition_flag <= '1';
        end if;
      end if;
    end if;
  end process;

end architecture ch_pwm;

architecture ch_3 of pwm_analyzer is    -- channel 3 for futaba-off detection

  signal clk_1mhz     : std_logic;
  signal clkdiv_cnt   : integer range 0 to (CLKIN_FREQ/2 - 1);
  signal ch3_edge_smp : std_logic_vector (1 downto 0);
  signal ch3_prd_cnt  : std_logic_vector (15 downto 0);

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

  -- measures period of channel 3
  process (clk_1mhz) is
  begin
    if rising_edge(clk_1mhz) then
      ch3_edge_smp <= ch3_edge_smp(0) & PWM_IN;
      if ch3_edge_smp = "01" then
        PWM_DATA_OUT <= ch3_prd_cnt;    -- no MSB flag
        ch3_prd_cnt  <= (others => '0');
      else
        ch3_prd_cnt <= ch3_prd_cnt + 1;
      end if;
    end if;
  end process;

end architecture ch_3;
