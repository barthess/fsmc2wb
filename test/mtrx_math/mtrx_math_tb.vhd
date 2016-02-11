--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   18:05:09 02/07/2016
-- Design Name:   
-- Module Name:   /home/barthess/projects/xilinx/fsmc2wb/test/mtrx_math/mtrx_math_tb.vhd
-- Project Name:  fsmc2wb
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: mtrx_math
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
USE ieee.numeric_std.ALL;
 
ENTITY mtrx_math_tb IS
END mtrx_math_tb;
 
ARCHITECTURE behavior OF mtrx_math_tb IS 

  --Inputs
  signal clk_mul_i : std_logic := '0';
  signal clk_wb_i : std_logic_vector(8 downto 0) := (others => '0');
  signal sel_wb_i : std_logic_vector(8 downto 0) := (others => '0');
  signal stb_wb_i : std_logic_vector(8 downto 0) := (others => '0');
  signal we_wb_i  : std_logic_vector(8 downto 0) := (others => '0');
  signal adr_wb_i : std_logic_vector(143 downto 0);
  signal dat_wb_i : std_logic_vector(143 downto 0);

  --Outputs
  signal rdy_o : std_logic;
  signal err_wb_o : std_logic_vector(8 downto 0);
  signal ack_wb_o : std_logic_vector(8 downto 0);
  signal dat_wb_o : std_logic_vector(143 downto 0);

  -- slices for convenience
  signal dat_i : std_logic_vector(15 downto 0) := (others => '0');
  signal dat_o : std_logic_vector(15 downto 0) := (others => '0');
  signal adr_i : std_logic_vector(15 downto 0) := (others => '0');
  signal stb_i, sel_i, we_i : std_logic := '0';
  signal err_o, ack_o : std_logic;
  signal stim_rst : std_logic := '1';
  
  signal rdy_pattern : std_logic := '0';
  signal ce_pattern : std_logic := '0';

  type state_t is (SIZES_1, SIZES_2, OP_N_1, OP_N_2, ACTIVE_1, ACTIVE_2, HALT);
  signal state : state_t := SIZES_1;

  -- Clock period definitions
  constant clk_mul_i_period : time := 1 ns;
  constant clk_wb_i_period  : time := 2 ns;
  
BEGIN

  -- connect slices
  dat_wb_i(143 downto 128) <= dat_i;
  adr_wb_i(143 downto 128) <= adr_i;
  dat_o <= dat_wb_o(143 downto 128);
  stb_wb_i(8) <= stb_i;
  sel_wb_i(8) <= sel_i;
  we_wb_i(8) <= we_i;
  err_o <= err_wb_o(8);
  ack_o <= ack_wb_o(8);
  
  -- Instantiate the Unit Under Test (UUT)
  uut: entity work.wb_mtrx
  PORT MAP (
    rdy_o => rdy_o,
    clk_mul_i => clk_mul_i,
    clk_wb_i => clk_wb_i,
    sel_i => sel_wb_i,
    stb_i => stb_wb_i,
    we_i => we_wb_i,
    err_o => err_wb_o,
    ack_o => ack_wb_o,
    adr_i => adr_wb_i,
    dat_o => dat_wb_o,
    dat_i => dat_wb_i
  );

  -- Clock process definitions
  clk_mul_i_process :process
  begin
    clk_mul_i <= '0';
    wait for clk_mul_i_period/2;
    clk_mul_i <= '1';
    wait for clk_mul_i_period/2;
  end process;

  clk_wb_i_process :process
  begin
    clk_wb_i <= (others => '0');
    wait for clk_wb_i_period/2;
    clk_wb_i <= (others => '1');
    wait for clk_wb_i_period/2;
  end process;

  wait_proc: process
  begin		
    -- hold reset state for 100 ns.
    wait for 10 ns;	
    wait for clk_mul_i_period*3;
    stim_rst <= '0';
    -- insert stimulus here 
    wait;
  end process;
  



  -- Stimulus process
  stim1_proc: process(clk_wb_i(8))
    variable cnt : integer := 10;
    variable m,p,n : std_logic_vector(4 downto 0) := "00010";
  begin
    if rising_edge(clk_wb_i(8)) then
      if stim_rst = '1' then
        dat_i <= x"0000";
        adr_i <= x"0000";
        stb_i <= '0';
        sel_i <= '0';
        we_i  <= '0';
        cnt := 10;
        state <= SIZES_1;
        rdy_pattern <= '1';
      else
        case state is

        when SIZES_1 =>
          m := "00010";
          p := "00000";
          n := "00010";
          dat_i <= '0' & n & p & m;
          adr_i <= x"0001";
          stb_i <= '1';
          sel_i <= '1';
          we_i  <= '1';
          state <= OP_N_1;

        when OP_N_1 =>
          dat_i <= '1' & "00" & "0101" & "010" & "001" & "000";
          adr_i <= x"0000";
          state <= ACTIVE_1;
        
        when ACTIVE_1 =>
          stb_i <= '0';
          sel_i <= '0';
          we_i  <= '0';
          if cnt > 0 then
            cnt := cnt - 1;
          else
            if rdy_o = '1' then
              state <= SIZES_2;
            end if;
          end if;

          
        when SIZES_2 =>
          cnt := 10;
          m := "00010";
          p := "00000";
          n := "00001";
          dat_i <= '0' & n & p & m;
          adr_i <= x"0001";
          stb_i <= '1';
          sel_i <= '1';
          we_i  <= '1';
          state <= OP_N_2;

        when OP_N_2 =>
          dat_i <= '1' & "00" & "0011" & "010" & "001" & "000";
          adr_i <= x"0000";
          state <= ACTIVE_2;
        
        when ACTIVE_2 =>
          stb_i <= '0';
          sel_i <= '0';
          we_i  <= '0';
          if cnt > 0 then
            cnt := cnt - 1;
          else
            if rdy_o = '1' then
              state <= HALT;
            end if;
          end if;

        
        when HALT =>
          state <= HALT;
        end case;

      end if; -- rst
    end if; --clk
  end process;

   
   
   
   
   
END;
