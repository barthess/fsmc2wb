
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity pwm_analyzer_multichannel is

  generic (
    PWM_CHANNELS      : integer := 16;
    PWM_SEND_INTERVAL : integer := 1024
    );

  port (
    clk          : in  std_logic;       -- gtp parallel clock
    rst          : in  std_logic;
    PWM_IN       : in  std_logic_vector (PWM_CHANNELS-1 downto 0);
    ODO_IN       : in  std_logic;       -- odometer ("pwm channel 17")
    PWM_DATA_OUT : out std_logic_vector (15 downto 0);
    PWM_EN_OUT   : out std_logic);

end entity pwm_analyzer_multichannel;

architecture rtl of pwm_analyzer_multichannel is

  type t_pwm_data_array is array (0 to PWM_CHANNELS + 2) of std_logic_vector (15 downto 0);
  signal pwm_data_array : t_pwm_data_array;
  type t_pwm_send_state is (idle, send, pause);
  signal pwm_send_state : t_pwm_send_state;
  signal pwm_send_cnt   : integer range 0 to PWM_SEND_INTERVAL-1;  -- pwm send counter

begin

  pwm_analyzer_gen : for i in 0 to PWM_CHANNELS-1 generate

    ch_3 : if i = 2 generate            -- channel 3
      pwm_analyzer_ch3 : entity work.pwm_analyzer(ch_3)
        generic map (
          CLKIN_FREQ => 100,            -- MHz
          PWM_PERIOD => 22000)          -- us
        port map (
          clk          => clk,
          rst          => rst,
          PWM_IN       => PWM_IN (i),
          PWM_DATA_OUT => pwm_data_array(i));
    end generate ch_3;

    ch_pwm : if i /= 2 generate
      pwm_analyzer_pwm : entity work.pwm_analyzer(ch_pwm)
        generic map (
          CLKIN_FREQ => 100,            -- MHz
          PWM_PERIOD => 22000)          -- us
        port map (
          clk          => clk,
          rst          => rst,
          PWM_IN       => PWM_IN (i),
          PWM_DATA_OUT => pwm_data_array(i));
    end generate ch_pwm;

  end generate pwm_analyzer_gen;

  odo_analizer_1 : entity work.odo_analizer
    generic map (
      divider => 2000,                  -- divider for 100 MHz
      glitch  => 900,
      timeout => 50000)                 -- 1 second
    port map (
      rst                  => rst,
      clk                  => clk,
      odo_in               => ODO_IN,
      pulses(15 downto 0)  => pwm_data_array(PWM_CHANNELS + 1),
      pulses(31 downto 16) => pwm_data_array(PWM_CHANNELS + 2),
      odo_do               => pwm_data_array(PWM_CHANNELS));
  -- odo_do maps to pwm channel 17, pulse count maps to channels 18-19

  -- pwm data send (pre_tx interface)
  process (clk) is
  begin
    if rising_edge(clk) then
      -- default
      PWM_DATA_OUT <= (others => '0');
      PWM_EN_OUT   <= '0';
      case pwm_send_state is
        when idle =>
          if pwm_send_cnt = PWM_SEND_INTERVAL-1 then
            pwm_send_state <= send;
            pwm_send_cnt   <= 0;
            PWM_EN_OUT     <= '1';
            PWM_DATA_OUT   <= pwm_data_array (0);
          else
            pwm_send_state <= idle;
            pwm_send_cnt   <= pwm_send_cnt + 1;
          end if;
        when send =>
          pwm_send_state <= pause;
        when pause =>
          if pwm_send_cnt = PWM_CHANNELS + 2 then
            pwm_send_state <= idle;
            pwm_send_cnt   <= 0;
          else
            pwm_send_state <= send;
            pwm_send_cnt   <= pwm_send_cnt + 1;
            PWM_EN_OUT     <= '1';
            PWM_DATA_OUT   <= pwm_data_array (pwm_send_cnt + 1);
          end if;
        when others => null;
      end case;
    end if;
  end process;

end architecture rtl;
