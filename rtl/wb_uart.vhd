library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
library uart_lib;

entity wb_uart is

  generic (
    UART_CHANNELS : positive := 2);

  port (
    rst : in std_logic;

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

  signal uart_cs          : std_logic_vector(UART_CHANNELS-1 downto 0);
  signal uart_wr          : std_logic;  -- common for all uarts
  signal uart_rd          : std_logic;  -- common for all uarts
  signal uart_addr        : std_logic_vector(2 downto 0);
  signal uart_di          : std_logic_vector(7 downto 0);
  type t_uart_do is array (0 to UART_CHANNELS-1) of std_logic_vector(7 downto 0);
  signal uart_do          : t_uart_do;
  signal uart_irqs        : std_logic_vector(UART_CHANNELS-1 downto 0);
  signal uart_16x_baudclk : std_logic_vector(UART_CHANNELS-1 downto 0);
  signal illegal_op       : std_logic;  -- illegal operation

begin

  -- Address space --
  -- bits 2:0 are UART register address
  -- when reading IRQs register, bits 2:0 can be anything
  -- upper bits are for UART selection (0 to UART_CHANNELS-1)
  -- UART_CHANNELS value is used for IRQs register reading

  uart_di <= dat_i(7 downto 0);

  -- asynchronous generation of flags and signals for uart
  process (sel_i, we_i, adr_i, uart_do, uart_irqs) is
    variable uart_num : natural;
    constant zeros    : std_logic_vector(15 downto 0) := X"0000";
  begin
    -- default values
    uart_cs    <= (others => '0');
    uart_wr    <= '0';
    uart_rd    <= '0';
    illegal_op <= '0';
    uart_addr  <= adr_i(2 downto 0);
    dat_o      <= (others => 'Z');

    uart_num := to_integer(unsigned(adr_i(15 downto 3)));  -- bits 2:0 are UART
                                                           -- register address
    if sel_i = '1' then
      if uart_num <= UART_CHANNELS-1 then  -- any UART channel
        uart_cs(uart_num) <= '1';
        if we_i = '0' then
          uart_rd <= '1';
          dat_o   <= zeros(15 downto 8) & uart_do(uart_num);
        else
          uart_wr <= '1';
        end if;
      elsif uart_num = UART_CHANNELS then  -- irqs register (end of address space)
        if we_i = '0' then
          dat_o <= zeros(15 downto UART_CHANNELS) & uart_irqs;
        else
          illegal_op <= '1';            -- write to irqs register illegal
        end if;
      else
        illegal_op <= '1';              -- illegal address
      end if;
    end if;
  end process;

  -- synchronous operations
  process (clk_i) is
  begin
    if rising_edge(clk_i) then
      if illegal_op = '1' then
        err_o <= '1';
        ack_o <= '0';
      else
        err_o <= '0';
        ack_o <= '1';
      end if;
    end if;
  end process;

  uarts : for i in 0 to UART_CHANNELS-1 generate
    uart_16750_i : entity uart_lib.uart_16750
      port map (
        CLK      => clk_i,
        RST      => rst,
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
