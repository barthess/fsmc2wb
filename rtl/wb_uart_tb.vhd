-------------------------------------------------------------------------------
-- Title      : Testbench for design "wb_uart"
-- Project    : 
-------------------------------------------------------------------------------
-- File       : wb_uart_tb.vhd
-- Author     : pilgrim  <pilgrim@pilgrim-x86>
-- Company    : 
-- Created    : 2016-02-03
-- Last update: 2016-02-05
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2016 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2016-02-03  1.0      pilgrim Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

-------------------------------------------------------------------------------

entity wb_uart_tb is

end entity wb_uart_tb;

-------------------------------------------------------------------------------

architecture tb of wb_uart_tb is

  -- component generics
  constant UART_CHANNELS : positive := 2;
  constant clk_period    : time     := 10 ns;

  -- component ports
  signal rst      : std_logic;
  signal UART_TX  : std_logic_vector(UART_CHANNELS-1 downto 0);
  signal UART_RTS : std_logic_vector(UART_CHANNELS-1 downto 0);
  signal UART_RX  : std_logic_vector(UART_CHANNELS-1 downto 0);
  signal UART_CTS : std_logic_vector(UART_CHANNELS-1 downto 0);
  signal clk_i    : std_logic := '1';
  signal sel_i    : std_logic;
  signal stb_i    : std_logic;
  signal we_i     : std_logic;
  signal err_o    : std_logic;
  signal ack_o    : std_logic;
  signal adr_i    : std_logic_vector(15 downto 0);
  signal dat_o    : std_logic_vector(15 downto 0);
  signal dat_i    : std_logic_vector(15 downto 0);


begin

  -- component instantiation
  DUT : entity work.wb_uart
    generic map (
      UART_CHANNELS => UART_CHANNELS)
    port map (
      rst      => rst,
      UART_TX  => UART_TX,
      UART_RTS => UART_RTS,
      UART_RX  => UART_RX,
      UART_CTS => UART_CTS,
      clk_i    => clk_i,
      sel_i    => sel_i,
      stb_i    => stb_i,
      we_i     => we_i,
      err_o    => err_o,
      ack_o    => ack_o,
      adr_i    => adr_i,
      dat_o    => dat_o,
      dat_i    => dat_i);

  -- clock generation
  clk_i <= not clk_i after clk_period/2;

  -- waveform generation
  WaveGen_Proc : process
  begin
    sel_i <= '0';
    wait for clk_period*10;
    rst <= '1';
    wait for clk_period*10;
    rst <= '0';
    wait for clk_period*20;
    sel_i <= '1';
    we_i <= '1';
    adr_i <= X"0012";
    wait for clk_period;
    adr_i <= X"0003";
    dat_i <= X"0003";
    wait for clk_period;
    adr_i <= X"0002";
    dat_i <= X"0001";
    wait for clk_period*2;
    adr_i <= X"0000";
    dat_i <= X"0055";
    wait for clk_period;
    dat_i <= X"0002";
    wait for clk_period;
    we_i <= '0';
    adr_i <= X"0002";
    wait for clk_period;
    adr_i <= X"0000";
    wait for clk_period;
    adr_i <= X"0034";
    wait for clk_period;
    adr_i <= X"0015";
    wait for clk_period;
    sel_i <= '0';
    wait for clk_period*1000;

    wait until clk_i = '1';
  end process WaveGen_Proc;



end architecture tb;
