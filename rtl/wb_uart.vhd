library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
library uart_lib;

entity wb_uart is

  generic (
    UART_CHANNELS : positive := 2);

  port (
    UART_TX  : out std_logic_vector(UART_CHANNELS-1 downto 0);
    UART_RTS : out std_logic_vector(UART_CHANNELS-1 downto 0);
    UART_RX  : in  std_logic_vector(UART_CHANNELS-1 downto 0);
    UART_CTS : in  std_logic_vector(UART_CHANNELS-1 downto 0);

    -- Wishbone signals
    clk_i : in  std_logic;
    sel_i : in  std_logic;
    stb_i : in  std_logic;
    we_i  : in  std_logic;
    err_o : out std_logic;
    ack_o : out std_logic;
    adr_i : in  std_logic_vector(15 downto 0);
    dat_o : out std_logic_vector(15 downto 0);
    dat_i : in  std_logic_vector(15 downto 0));

end entity wb_uart;

architecture rtl of wb_uart is

  signal uart_cs           : std_logic_vector(UART_CHANNELS-1 downto 0);
  signal uart_wr           : std_logic;  -- common for all uarts
  signal uart_rd           : std_logic;  -- common for all uarts
  signal uart_addr         : std_logic_vector(3 downto 0);
  signal uart_di           : std_logic_vector(7 downto 0);
  type t_uart_do is array (0 to UART_CHANNELS-1) of std_logic_vector(7 downto 0);
  signal uart_do           : t_uart_do;
  signal uart_irqs         : std_logic_vector(UART_CHANNELS-1 downto 0);
  signal uart_resets       : std_logic_vector(UART_CHANNELS-1 downto 0) := (others => '1');
  signal uart_16x_baudclk  : std_logic_vector(UART_CHANNELS-1 downto 0);
  signal irqs_rd           : std_logic;  -- wishbone reads irqs register
  signal resets_wr         : std_logic;  -- wishbone writes resets register
  signal resets_rd         : std_logic;  -- wishbone reads resets register
  signal illegal_op        : std_logic;  -- illegal operation
  shared variable uart_num : natural;

begin

  -- Address space --
  -- bits 3:0 are UART register address
  -- when reading IRQs register, bits 3:0 can be anything
  -- when writing/reading resets register, bits 3:0 can be anything
  -- upper bits are for UART selection (0 to UART_CHANNELS-1)
  -- UART_CHANNELS value is used for IRQs register reading
  -- UART_CHANNELS+1 value is used for resets register writing/reading

  uart_di <= dat_i(7 downto 0);

  -- asynchronous generation of flags and signals for uart
  process (sel_i, stb_i, we_i, adr_i, dat_i) is
  begin
    -- default values
    uart_cs    <= (others => '0');
    uart_wr    <= '0';
    uart_rd    <= '0';
    illegal_op <= '0';
    irqs_rd    <= '0';
    resets_wr  <= '0';
    resets_rd  <= '0';
    uart_addr  <= adr_i(3 downto 0);

    uart_num := to_integer(unsigned(adr_i(15 downto 4)));
    -- bits 3:0 of adr_i are UART register address

    if (sel_i = '1' and stb_i = '1') then
      if uart_num <= UART_CHANNELS-1 then    -- any UART channel
        uart_cs(uart_num) <= '1';
        if we_i = '0' then
          uart_rd <= '1';
        else
          uart_wr <= '1';
        end if;
      elsif uart_num = UART_CHANNELS then    -- irqs register
        if we_i = '0' then
          irqs_rd <= '1';
        else
          illegal_op <= '1';                 -- write to irqs register illegal
        end if;
      elsif uart_num = UART_CHANNELS+1 then  -- resets register
        if we_i = '0' then
          resets_rd <= '1';
        else
          resets_wr <= '1';
        end if;
      else
        illegal_op <= '1';                   -- illegal address
      end if;
      if dat_i(15 downto 8) /= X"00" then
        illegal_op <= '1';                   -- illegal input data
      end if;
    end if;
  end process;

  -- synchronous operations
  process (clk_i) is
    constant zeros : std_logic_vector(15 downto 0) := X"0000";
  begin
    if rising_edge(clk_i) then
      if illegal_op = '1' then
        err_o <= '1';
        ack_o <= '0';
        dat_o <= (others => '0');
      else
        err_o <= '0';
        ack_o <= '1';
        if uart_rd = '1' then
          dat_o <= zeros(15 downto 8) & uart_do(uart_num);
        elsif irqs_rd = '1' then
          dat_o <= zeros(15 downto UART_CHANNELS) & uart_irqs;
        elsif resets_rd = '1' then
          dat_o <= zeros(15 downto UART_CHANNELS) & uart_resets;
        elsif resets_wr = '1' then
          uart_resets <= dat_i(UART_CHANNELS-1 downto 0);
        else
          dat_o <= (others => '0');
        end if;
      end if;
    end if;
  end process;

  uarts : for i in 0 to UART_CHANNELS-1 generate
    uart_16750_i : entity uart_lib.uart_16750
      port map (
        CLK      => clk_i,
        RST      => uart_resets(i),
        BAUDCE   => '1',
        CS       => uart_cs(i),
        WR       => uart_wr,
        RD       => uart_rd,
        A        => uart_addr,
        DIN      => uart_di,
        DOUT     => uart_do(i),
        DDIS     => open,
        INT      => uart_irqs(i),
        OUT1N    => open,
        OUT2N    => open,
        RCLK     => uart_16x_baudclk(i),
        BAUDOUTN => uart_16x_baudclk(i),
        RTSN     => UART_RTS(i),
        DTRN     => open,
        CTSN     => UART_CTS(i),
        DSRN     => '1',
        DCDN     => '1',
        RIN      => '1',
        SIN      => UART_RX(i),
        SOUT     => UART_TX(i));
  end generate uarts;

end architecture rtl;
