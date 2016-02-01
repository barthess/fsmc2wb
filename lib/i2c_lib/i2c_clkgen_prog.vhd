
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity i2c_clkgen_prog is
  port (
    CLK : in    std_logic;
    RST : in    std_logic;
    SDA : inout std_logic;
    SCL : inout std_logic);
end entity i2c_clkgen_prog;

architecture rtl of i2c_clkgen_prog is
  signal i2c_ena      : std_logic;
  signal i2c_data_wr  : std_logic_vector(7 downto 0);
  signal i2c_busy     : std_logic;
  signal i2c_data_ptr : integer range 0 to 91;

  type fsm is (idle, cmd, stop);
  signal state : fsm;

  type t_i2cdata is array (0 to 90) of std_logic_vector (7 downto 0);
  constant i2c_data : t_i2cdata :=
    (
      X"10",                            --0x10 (RAM register start address)
      -- 90 bytes of config data
      -- OUT0: LVCMOS25 24.84 MHz
      -- OUT1: LVDS25 100 MHz
      -- OUT2: LVDS25 100 MHz
      X"80", X"0C", X"81", X"80", X"00", X"17", X"8C", X"06",
      X"F0", X"00", X"00", X"00", X"9F", X"FF", X"E0", X"80",
      X"00", X"81", X"03", X"25", X"11", X"9C", X"00", X"00",
      X"00", X"00", X"04", X"00", X"01", X"00", X"D0", X"00",
      X"00", X"0C", X"03", X"A4", X"3F", X"E4", X"00", X"00",
      X"00", X"00", X"04", X"00", X"00", X"00", X"D0", X"00",
      X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
      X"00", X"00", X"04", X"00", X"00", X"00", X"00", X"00",
      X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
      X"00", X"00", X"04", X"00", X"00", X"00", X"00", X"00",
      X"73", X"01", X"73", X"01", X"73", X"00", X"73", X"00",
      X"FE", X"E4"
      );

  component i2c_master is
    generic (
      input_clk : integer;
      bus_clk   : integer);
    port (
      clk       : in     std_logic;
      reset_n   : in     std_logic;
      ena       : in     std_logic;
      addr      : in     std_logic_vector(6 downto 0);
      rw        : in     std_logic;
      data_wr   : in     std_logic_vector(7 downto 0);
      busy      : out    std_logic;
      data_rd   : out    std_logic_vector(7 downto 0);
      ack_error : buffer std_logic;
      sda       : inout  std_logic;
      scl       : inout  std_logic);
  end component i2c_master;

begin  -- architecture rtl
  
  i2c_data_wr <= i2c_data (i2c_data_ptr);

  i2c_master_1 : i2c_master
    generic map (
      input_clk => 24_840_000,
      bus_clk   => 248_400)
    port map (
      clk       => clk,
      reset_n   => not rst,             --active low reset
      ena       => i2c_ena,
      addr      => "1101010",           --i2c address 0xD4
      rw        => '0',                 --always write
      data_wr   => i2c_data_wr,
      busy      => i2c_busy,
      data_rd   => open,
      ack_error => open,
      sda       => SDA,
      scl       => SCL);

  process (clk, rst) is
  begin  -- process
    if rst = '1' then
      state        <= idle;
      i2c_data_ptr <= 0;
      i2c_ena      <= '0';
    elsif rising_edge(clk) then
      case state is
        when idle =>
          if i2c_data_ptr >= 90 then
            state <= stop;
          elsif (i2c_busy = '1') then
            state <= idle;
          else
            state   <= cmd;
            i2c_ena <= '1';
          end if;
        when cmd =>
          if i2c_busy = '0' then
            state   <= cmd;
            i2c_ena <= '1';
          else
            state        <= idle;
            i2c_data_ptr <= i2c_data_ptr + 1;
            i2c_ena      <= '1';
          end if;
        when stop =>
          i2c_ena <= '0';
        when others => null;
      end case;
    end if;
  end process;

end architecture rtl;
