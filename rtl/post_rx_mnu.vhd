
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity post_rx_mnu is
  generic (
    PWM_START_CHAR : std_logic_vector (7 downto 0) := X"1C";  -- K28.0
    PWM_CHANNELS   : integer                       := 17;
    UART_CHANNELS  : integer                       := 16
    );
  port (
    clk               : in  std_logic;  -- RXUSRCLK8
    rst               : in  std_logic;
    GTP_RXDATA        : in  std_logic_vector (7 downto 0);
    GTP_CHARISK       : in  std_logic;
    GTP_BYTEISALIGNED : in  std_logic;
    USART1_RX         : out std_logic;  -- MCU UART (telemetry)
    USART1_CTS        : out std_logic;
    PWM_DATA_OUT      : out std_logic_vector (15 downto 0);
    PWM_EN_OUT        : out std_logic;
    UART_RX           : out std_logic_vector (UART_CHANNELS-1 downto 0);
    UART_CTS          : out std_logic_vector (UART_CHANNELS-1 downto 0)
    );
end entity post_rx_mnu;

architecture gtp0 of post_rx_mnu is     -- MORS link

  type post_rx_state is (comma, payload);
  signal state           : post_rx_state;
  signal usart1_rx_prev  : std_logic := '1';
  signal usart1_cts_prev : std_logic := '1';

begin

  process (clk, rst) is
  begin
    if rst = '1' then
      USART1_RX  <= '1';
      USART1_CTS <= '1';
      state      <= comma;
    elsif rising_edge(clk) then
      case state is
        when comma =>
          if (GTP_BYTEISALIGNED = '0' or GTP_CHARISK = '1') then
            state      <= comma;
            USART1_RX  <= usart1_rx_prev;
            USART1_CTS <= usart1_cts_prev;
          elsif (GTP_BYTEISALIGNED = '1' and GTP_CHARISK = '0') then
            state           <= payload;
            USART1_RX       <= GTP_RXDATA(0);
            USART1_CTS      <= GTP_RXDATA(1);
            usart1_rx_prev  <= GTP_RXDATA(0);
            usart1_cts_prev <= GTP_RXDATA(1);
          end if;
        when payload =>
          if (GTP_BYTEISALIGNED = '0' or GTP_CHARISK = '1') then
            state      <= comma;
            USART1_RX  <= usart1_rx_prev;
            USART1_CTS <= usart1_cts_prev;
          elsif (GTP_BYTEISALIGNED = '1' and GTP_CHARISK = '0') then
            state           <= payload;
            USART1_RX       <= GTP_RXDATA(0);
            USART1_CTS      <= GTP_RXDATA(1);
            usart1_rx_prev  <= GTP_RXDATA(0);
            usart1_cts_prev <= GTP_RXDATA(1);
          end if;
        when others => null;
      end case;
    end if;
  end process;

end architecture gtp0;

architecture gtp2 of post_rx_mnu is     -- MSI link

  type post_rx_state is (s_comma, s_start, s_pwmb0, s_pwmb1, s_urx0, s_urx1, s_ucts0, s_ucts1);
  signal state         : post_rx_state;
  signal pwm_data_cnt  : integer range 0 to PWM_CHANNELS-1;
  signal pwm_byte0     : std_logic_vector (7 downto 0);
  signal uart_byte0    : std_logic_vector (7 downto 0);
  signal uart_rx_prev  : std_logic_vector (UART_CHANNELS-1 downto 0);
  signal uart_cts_prev : std_logic_vector (UART_CHANNELS-1 downto 0);

begin

  process (clk, rst) is
  begin
    if rst = '1' then
      state         <= s_comma;
      PWM_DATA_OUT  <= (others => '0');
      PWM_EN_OUT    <= '0';
      uart_rx_prev  <= (others => '1');
      uart_cts_prev <= (others => '1');
      pwm_data_cnt  <= 0;
      pwm_byte0     <= (others => '0');
      uart_byte0    <= (others => '0');
    elsif rising_edge(clk) then
      -- defaults
      PWM_DATA_OUT <= (others => '0');
      PWM_EN_OUT   <= '0';
      UART_RX      <= uart_rx_prev;
      UART_CTS     <= uart_cts_prev;
      case state is
        when s_comma =>
          if (GTP_BYTEISALIGNED = '1' and GTP_CHARISK = '1' and GTP_RXDATA = PWM_START_CHAR) then
            state <= s_start;
          else
            state <= s_comma;
          end if;
        when s_start =>
          state        <= s_pwmb0;
          pwm_byte0    <= GTP_RXDATA;
          pwm_data_cnt <= 0;
        when s_pwmb0 =>
          state        <= s_pwmb1;
          PWM_DATA_OUT <= GTP_RXDATA & pwm_byte0;
          PWM_EN_OUT   <= '1';
        when s_pwmb1 =>
          if pwm_data_cnt /= PWM_CHANNELS-1 then
            state        <= s_pwmb0;
            pwm_byte0    <= GTP_RXDATA;
            pwm_data_cnt <= pwm_data_cnt + 1;
          else
            state      <= s_urx0;
            uart_byte0 <= GTP_RXDATA;
          end if;
        when s_urx0 =>
          state        <= s_urx1;
          uart_rx_prev <= GTP_RXDATA & uart_byte0;
        when s_urx1 =>
          state      <= s_ucts0;
          uart_byte0 <= GTP_RXDATA;
        when s_ucts0 =>
          state         <= s_ucts1;
          uart_cts_prev <= GTP_RXDATA & uart_byte0;
        when s_ucts1 =>
          state <= s_comma;
        when others => null;
      end case;
    end if;
  end process;

end architecture gtp2;
