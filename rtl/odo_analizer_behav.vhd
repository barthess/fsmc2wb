--
-- VHDL Architecture monoblock.ram_to_pwm.behav
--
-- Created:
--          by - muaddib.UNKNOWN (AMSTERDAM)
--          at - 10:27:58 09.11.2015
--
-- using Mentor Graphics HDL Designer(TM) 2012.1 (Build 6)
--

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
USE ieee.numeric_std.all;
USE ieee.std_logic_unsigned.all;

entity odo_analizer is
 generic (divider : integer := 1600;  --1600 for 50kHz on 80Mhz clock
          timeout : integer := 160;
          glitch : integer := 127);
 port(
      rst       : in  std_logic;
      clk       : in  std_logic;
      odo_in    : in  std_logic;
      odo_do    : out std_logic_vector(15 downto 0);
      pulses    : out std_logic_vector(31 downto 0)   
     );
end entity odo_analizer;

--
ARCHITECTURE behav OF odo_analizer IS
  type state_t is (reset, idle, measure);
  type sig_state_t is (z, re, fe, o);
  type timer_t is (idle, timer, no_glitch);
  
  signal timer_state : timer_t;  
  signal state : state_t;
  signal sig_state : sig_state_t;
    
  signal edge_smpl   : std_logic_vector(1 downto 0);
  signal cnt_div     : std_logic_vector(10 downto 0);
  signal prd_cnt     : std_logic_vector(15 downto 0);
  signal cnt_div_lim : std_logic_vector(10 downto 0);
  signal prd_cnt_lim : std_logic_vector(15 downto 0);
  
  signal prd_cnt_rst : std_logic;
  signal cnt_div_rst : std_logic;
  signal pulses_int  : std_logic_vector(31 downto 0);
  
  signal timer_cnt   : std_logic_vector(9 downto 0);
  
BEGIN
  prd_cnt_lim <= std_logic_vector(to_unsigned(timeout,16));
  cnt_div_lim <= std_logic_vector(to_unsigned(divider,11));
  
-----timer state machine-----------
  timer_state_proc : process(rst, clk) is
  begin
    if rst = '1' then
      timer_state <= idle;
    elsif rising_edge(clk) then
      case timer_state is
		    when idle =>
		      if sig_state = fe then
		        timer_state <= timer;
		      end if;
        when timer =>
          if sig_state = re or sig_state = o then
            timer_state <= idle;  
          else
            if timer_cnt = std_logic_vector(to_unsigned(glitch,10)) then
              timer_state <= no_glitch; 
            end if;
          end if;
        when no_glitch =>
            timer_state <= idle; 
        when others =>
          timer_state <= idle;
      end case;
    end if;
  end process timer_state_proc;
-----------------------------

-----data output-----
  odo_do_proc : process(rst, clk) is
  begin
    if rst = '1' then
      odo_do <= (others => '0');
    elsif rising_edge(clk) then
      if state = measure then
        if timer_state = no_glitch then
          odo_do <= prd_cnt;
        end if;
      else
        odo_do <= (others => '0');
      end if;
    end if;
  end process odo_do_proc;
  
---- pulsese counter
  pulses_cnt_proc : process(rst, clk) is
  begin
    if rst = '1' then
      pulses_int <= (others => '0');
    elsif rising_edge(clk) then
      if timer_state = no_glitch then
        pulses_int <= pulses_int + "1";
      end if;
    end if;
  end process pulses_cnt_proc;
  pulses <= pulses_int;
  
-----edge detection---------
  edge_det_proc : process(rst, clk) is
  begin
    if rst = '1' then
      edge_smpl <= "00";
    elsif rising_edge(clk) then
      edge_smpl <= edge_smpl(0)&odo_in;
    end if;
  end process edge_det_proc;         
-----------------------------   

-----state machine-----------
  state_proc : process(rst, clk) is
  begin
    if rst = '1' then
      state <= reset;
    elsif rising_edge(clk) then
      case state is
		    when reset =>
		      state <= idle;
        when idle =>
          if timer_state = no_glitch then
            state <= measure; 
          end if;  
        when measure => 
          if prd_cnt = prd_cnt_lim then
            state <= idle;
          end if;
        when others =>
          state <= idle;
      end case;
    end if;
  end process state_proc;
-----------------------------

-----signal state machine-----------
  sig_state <= z  when edge_smpl = "00" else
               re when edge_smpl = "01" else
               o  when edge_smpl = "11" else
               fe when edge_smpl = "10" else
               z;
-----------------------------

-----state counter-----------   
  prd_cnt_rst <= '1' when state = idle or timer_state = no_glitch else
                 '0';  
                   
  prd_cnt_proc : process(rst, clk) is
  begin
    if rst = '1' then
      prd_cnt <= (others => '0');
    elsif rising_edge(clk) then
      if prd_cnt_rst = '1' then
        prd_cnt <= (others => '0');
      else
        if cnt_div = "00000000000" then 
          prd_cnt <= prd_cnt + "1";
        end if;
      end if;
    end if;  
  end process prd_cnt_proc; 
  
-----divided counter----------- 
  cnt_div_rst <= '1' when state = idle or cnt_div = cnt_div_lim else
                 '0';
                 
  cnt_div_proc : process(rst, clk) is
  begin
    if rst = '1' then
      cnt_div <= (others => '0');
    elsif rising_edge(clk) then
      if cnt_div_rst = '1' then
        cnt_div <= (others => '0');
      else
        cnt_div <= cnt_div + "1";
      end if;
    end if;  
  end process cnt_div_proc; 

-----timer counter----------- 
                 
  timer_cnt_proc : process(rst, clk) is
  begin
    if rst = '1' then
      timer_cnt <= (others => '0');
    elsif rising_edge(clk) then
      if timer_state = idle then
        timer_cnt <= (others => '0');
      else
        timer_cnt <= timer_cnt + "1";
      end if;
    end if;  
  end process timer_cnt_proc;
    
END ARCHITECTURE behav;

