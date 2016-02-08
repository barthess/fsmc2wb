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

  -- Clock period definitions
  constant clk_mul_i_period : time := 1 ns;
  constant clk_wb_i_period  : time := 1 ns;

  -- slices for convenience
  signal dat_i : std_logic_vector(15 downto 0) := (others => '0');
  signal dat_o : std_logic_vector(15 downto 0) := (others => '0');
  signal adr_i : std_logic_vector(15 downto 0) := (others => '0');
  signal stb_i, sel_i, we_i : std_logic := '0';
  signal err_o, ack_o : std_logic;
  signal stim_rst : std_logic := '1';
  
  signal rdy_pattern : std_logic := '0';
  signal ce_pattern : std_logic := '0';

  type state_t is (IDLE, SIZES1, SIZES2, OP_N, ACTIVE, HALT);
  signal state : state_t := IDLE;
  
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
  


  -- Fill brams with recognizable patterns
--  watermark_proc : process(clk_wb_i(8))
--    variable cnt : std_logic_vector(7 downto 0) := (others => '0');
--    variable tmp : std_logic_vector(2 downto 0);
--  begin
--    if rising_edge(clk_wb_i(8)) then
--      if (ce_pattern = '1') then
--        if (cnt /= "11111111") then
--          rdy_pattern <= '0';
--          sel_wb_i(7 downto 0) <= (others => '1');
--          stb_wb_i(7 downto 0) <= (others => '1');
--          we_wb_i(7 downto 0)  <= (others => '1');
--          
--          for n in 0 to 7 loop
--            tmp := std_logic_vector(to_unsigned(n, 3));
--            dat_wb_i((n+1)*16-1 downto n*16) <= tmp & "00000" & cnt;
--            adr_wb_i((n+1)*16-1 downto n*16) <= "00000000" & cnt;
--          end loop;
--
--          cnt := cnt + 1;
--        else
--          rdy_pattern <= '1';
--          sel_wb_i(7 downto 0) <= (others => '0');
--          stb_wb_i(7 downto 0) <= (others => '0');
--          we_wb_i(7 downto 0)  <= (others => '0');
--        end if;
--      else
--        sel_wb_i(7 downto 0) <= (others => '0');
--        stb_wb_i(7 downto 0) <= (others => '0');
--        we_wb_i(7 downto 0)  <= (others => '0');
--        rdy_pattern <= '0';
--      end if;
--    end if; -- clk
--  end process;



  -- Stimulus process
  stim_proc: process(clk_wb_i(8))
    variable m,p,n : std_logic_vector(4 downto 0) := "00010";
  begin
    if rising_edge(clk_wb_i(8)) then
      if stim_rst = '1' then
        dat_i <= x"0000";
        adr_i <= x"0000";
        stb_i <= '0';
        sel_i <= '0';
        we_i  <= '0';
        state <= IDLE;
        rdy_pattern <= '1';
      else
        case state is
        when IDLE =>
          ce_pattern<= '1';
          if rdy_pattern = '1' then
            ce_pattern <= '0';
            state <= SIZES1;
          end if;
          
        when SIZES1 =>
          state <= SIZES2;
          
        when SIZES2 =>
          dat_i <= '0' & n & p & m;
          --dat_i <= '0' & n & "00000" & m;
          adr_i <= x"0001";
          stb_i <= '1';
          sel_i <= '1';
          we_i  <= '1';
          state <= OP_N;

        when OP_N =>
          dat_i <= '1' & "00" & "1000" & "010" & "001" & "000";
          adr_i <= x"0000";
          state <= ACTIVE;
        
        when ACTIVE =>
          stb_i <= '0';
          sel_i <= '0';
          we_i  <= '0';
          if rdy_o = '1' then
            state <= HALT;
          end if;
        
        when HALT =>
          state <= HALT;
        end case;

      end if; -- rst
    end if; --clk
  end process;

   
   
   
   
   
END;
