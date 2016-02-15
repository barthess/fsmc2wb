library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity wb_pwm_tb is
end entity wb_pwm_tb;

architecture rtl of wb_pwm_tb is

  -- component ports
  signal rst          : std_logic;
  signal clk_gtp_tx   : std_logic;
  signal clk_gtp_rx   : std_logic;
  signal PWM_DATA_IN  : std_logic_vector(15 downto 0);
  signal PWM_EN_IN    : std_logic;
  signal PWM_DATA_OUT : std_logic_vector(15 downto 0);
  signal PWM_EN_OUT   : std_logic;
  signal clk_i        : std_logic;
  signal sel_i        : std_logic;
  signal stb_i        : std_logic;
  signal we_i         : std_logic;
  signal err_o        : std_logic;
  signal ack_o        : std_logic;
  signal adr_i        : std_logic_vector(15 downto 0);
  signal dat_o        : std_logic_vector(15 downto 0);
  signal dat_i        : std_logic_vector(15 downto 0);

  -- clock
  signal clk_gtp        : std_logic := '1';
  signal clk_wb         : std_logic := '1';
  signal clk_period_gtp : time      := 10 ns;
  signal clk_period_wb  : time      := 6 ns;

begin

  -- component instantiation
  DUT : entity work.wb_pwm
    generic map (
      PWM_CHANNELS    => 16,
      PWM_TX_INTERVAL => 1024)
    port map (
      rst          => rst,
      clk_gtp_tx   => clk_gtp_tx,
      clk_gtp_rx   => clk_gtp_rx,
      PWM_DATA_IN  => PWM_DATA_IN,
      PWM_EN_IN    => PWM_EN_IN,
      PWM_DATA_OUT => PWM_DATA_OUT,
      PWM_EN_OUT   => PWM_EN_OUT,
      clk_i        => clk_i,
      sel_i        => sel_i,
      stb_i        => stb_i,
      we_i         => we_i,
      err_o        => err_o,
      ack_o        => ack_o,
      adr_i        => adr_i,
      dat_o        => dat_o,
      dat_i        => dat_i);

  -- clock generation
  clk_gtp <= not clk_gtp after clk_period_gtp/2;
  clk_wb  <= not clk_wb  after clk_period_wb/2;

  clk_i      <= clk_wb;
  clk_gtp_tx <= clk_gtp;
  clk_gtp_rx <= clk_gtp;

  -- waveform generation
  WaveGen_Proc : process
  begin
    wait for clk_period_gtp*10;
    rst   <= '1';
    sel_i <= '0';
    stb_i <= '0';
    we_i  <= '0';
    wait for clk_period_gtp;

    rst         <= '0';
    PWM_DATA_IN <= X"1000";
    PWM_EN_IN   <= '1';
    wait for clk_period_gtp;
    PWM_EN_IN   <= '0';
    wait for clk_period_gtp;

    for i in 1 to 15 loop
      PWM_DATA_IN <= PWM_DATA_IN + 1;
      PWM_EN_IN   <= '1';
      wait for clk_period_gtp;
      PWM_EN_IN   <= '0';
      wait for clk_period_gtp;
    end loop;

    wait for clk_period_gtp*10;

    sel_i <= '1';
    stb_i <= '1';
    adr_i <= X"A123";                   --wrong address
    wait for clk_period_wb*4;

    we_i  <= '1';                       -- write cycle
    adr_i <= X"000F";
    dat_i <= X"400F";
    wait for clk_period_wb;
    for i in 1 to 15 loop
      adr_i <= adr_i - 1;
      dat_i <= dat_i - 1;
      wait for clk_period_wb;
    end loop;

    we_i  <= '0';                       -- read cycle
    adr_i <= X"0000";
    wait for clk_period_wb;
    for i in 1 to 15 loop
      adr_i <= adr_i + 1;
      wait for clk_period_wb;
    end loop;

    wait for clk_period_gtp*1000;


    wait until clk_gtp = '1';
  end process WaveGen_Proc;



end architecture rtl;
