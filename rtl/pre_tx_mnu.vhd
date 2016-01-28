library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity pre_tx_mnu is

  generic (
    COMMA_8B       : std_logic_vector (7 downto 0) := X"BC";  -- K28.5
    COMMA_INTERVAL : integer                       := 256;  -- telemetry UART send interval
    PWM_START_CHAR : std_logic_vector(7 downto 0)  := X"1C";  -- K28.0
    UART_CHANNELS  : integer                       := 16;   -- always 16
    PWM_CHANNELS   : integer                       := 16
    );

  port (
    clk           : in  std_logic;      -- TXUSRCLK8
    rst           : in  std_logic;
    USART1_TX     : in  std_logic;      -- telemetry uart
    USART1_RTS    : in  std_logic;      -- telemetry uart
    PWM_DATA_IN   : in  std_logic_vector(15 downto 0);
    PWM_EN_IN     : in  std_logic;
    UART_TX       : in  std_logic_vector(UART_CHANNELS - 1 downto 0);
    UART_RTS      : in  std_logic_vector(UART_CHANNELS - 1 downto 0);
    GTP_RESETDONE : in  std_logic;
    GTP_PLLLKDET  : in  std_logic;
    GTP_TXDATA    : out std_logic_vector (7 downto 0);
    GTP_CHARISK   : out std_logic);

end entity pre_tx_mnu;

architecture gtp0 of pre_tx_mnu is

  signal gtp_ready    : std_logic;
  signal usart1_tx_i  : std_logic;
  signal usart1_rts_i : std_logic;
  signal byte_cnt     : integer range 0 to COMMA_INTERVAL-1;

begin

  gtp_ready <= GTP_RESETDONE and GTP_PLLLKDET;

  process (clk) is
  begin
    if rising_edge(clk) then
      usart1_tx_i  <= USART1_TX;
      usart1_rts_i <= USART1_RTS;
      byte_cnt     <= byte_cnt + 1;
      if byte_cnt = 0 then
        GTP_TXDATA  <= COMMA_8B;
        GTP_CHARISK <= '1';
      else
        GTP_TXDATA  <= (0 => usart1_tx_i, 1 => usart1_rts_i, others => '0');
        GTP_CHARISK <= '0';
      end if;
    end if;
  end process;

end architecture gtp0;

architecture gtp2 of pre_tx_mnu is
  type t_state is (idle, pwm_start, pwm_b0, pwm_b1, utx_b0, utx_b1, urts_b0, urts_b1);
  signal state        : t_state;
  signal pwm_data_i   : std_logic_vector(15 downto 0);
  signal pwm_data_cnt : integer range 0 to PWM_CHANNELS - 1;
  signal gtp_ready    : std_logic;
begin

  gtp_ready <= GTP_RESETDONE and GTP_PLLLKDET;

  -- transmission order:
  -- K28.0 -> 16 words PWM (LSB first) -> 4 bytes UART (TX7:0,TX15:8,RTS7:0,RTS15:8)
  tx_proc : process(clk, rst) is
  begin
    if rst = '1' then
      state       <= idle;
      GTP_TXDATA  <= COMMA_8B;
      GTP_CHARISK <= '1';
    elsif rising_edge(clk) then
      -- default
      GTP_TXDATA  <= COMMA_8B;
      GTP_CHARISK <= '1';               -- '0' only when data is transmitted
      case state is
        when idle =>
          if PWM_EN_IN = '1' and gtp_ready = '1' then
            state      <= pwm_start;
            pwm_data_i <= PWM_DATA_IN;
            GTP_TXDATA <= PWM_START_CHAR;
          else
            state <= idle;
          end if;
        when pwm_start =>
          state        <= pwm_b0;
          pwm_data_cnt <= 0;
          GTP_TXDATA   <= pwm_data_i(7 downto 0);
          GTP_CHARISK  <= '0';
        when pwm_b0 =>
          state       <= pwm_b1;
          GTP_TXDATA  <= pwm_data_i(15 downto 8);
          GTP_CHARISK <= '0';
          pwm_data_i  <= PWM_DATA_IN;
        when pwm_b1 =>
          if pwm_data_cnt /= PWM_CHANNELS - 1 then
            state        <= pwm_b0;
            pwm_data_cnt <= pwm_data_cnt + 1;
            GTP_TXDATA   <= pwm_data_i(7 downto 0);
            GTP_CHARISK  <= '0';
          else
          -- TODO : latch all uarts on one cycle
            state       <= utx_b0;
            GTP_TXDATA  <= UART_TX(7 downto 0);
            GTP_CHARISK <= '0';
          end if;
        when utx_b0 =>
          state       <= utx_b1;
          GTP_TXDATA  <= UART_TX(15 downto 8);
          GTP_CHARISK <= '0';
        when utx_b1 =>
          state       <= urts_b0;
          GTP_TXDATA  <= UART_RTS(7 downto 0);
          GTP_CHARISK <= '0';
        when urts_b0 =>
          state       <= urts_b1;
          GTP_TXDATA  <= UART_RTS(15 downto 8);
          GTP_CHARISK <= '0';
        when urts_b1 =>
          state <= idle;
      end case;
    end if;
  end process tx_proc;
end architecture gtp2;
