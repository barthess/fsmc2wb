----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:11:00 01/19/2016 
-- Design Name: 
-- Module Name:    acc_link - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity dadd_link is
  Generic (
    -- Width of register used for state tracking
    -- As a result the link able to accumulate 2**WIDTH numbers
    WIDTH : positive := 5
  );
  Port (
    clk_i : in  STD_LOGIC;
    rst_i : in  STD_LOGIC;  -- also used for latch cnt_i value
                            -- use it every time you change cnt_i
    nd_i  : in  STD_LOGIC;
    cnt_i : in  STD_LOGIC_VECTOR (WIDTH-1 downto 0);-- number of input values for state tracking
                                                    -- NOTE: 0 denotes single input value
    dat_i : in  STD_LOGIC_VECTOR (63 downto 0);
    dat_o : out STD_LOGIC_VECTOR (63 downto 0);
    rdy_o : out STD_LOGIC
  );
end dadd_link;


architecture Behavioral of dadd_link is
  constant ZERO : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
  signal cnt    : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
  signal a_buf  : std_logic_vector(63 downto 0) := (others => '0');
  signal b_buf  : std_logic_vector(63 downto 0) := (others => '0');
  signal sum_nd : std_logic := '0';
  
  signal rst_buf : std_logic := '1'; 
  signal cnt_buf : std_logic_vector(WIDTH-1 downto 0);
  
  signal   state  : std_logic := '0';
  constant LOAD_A : std_logic := '0';
  constant LOAD_B : std_logic := '1';
begin
  
  dadd : entity work.dadd
    port map (
      clk     => clk_i,
      ce      => '1',
      a       => a_buf,
      b       => b_buf,
      result  => dat_o,
      rdy     => rdy_o,
      operation => (others => '0'),
      operation_nd => sum_nd
    );




  rst_delay : entity work.delay
  generic map (
    LAT => 1,
    WIDTH => 1,
    default => '1'
  )
  port map (
    clk   => clk_i,
    ce    => '1',
    di(0) => rst_i,
    do(0) => rst_buf
  );

  cnt_delay : entity work.delay
  generic map (
    LAT => 1,
    WIDTH => WIDTH,
    default => '1'
  )
  port map (
    clk   => clk_i,
    ce    => '1',
    di    => cnt_i,
    do    => cnt_buf
  );

  state_switcher : process(clk_i)
    variable cnt_latch : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
  begin
    if rising_edge(clk_i) then
      if rst_buf = '1' then
        state <= LOAD_A;
        cnt   <= cnt_buf;
        cnt_latch := cnt_buf;
      else
        if (nd_i = '1') then
          if (cnt = ZERO) then
            cnt   <= cnt_latch;
            state <= LOAD_A;
          else
            cnt   <= std_logic_vector(unsigned(cnt) - 1);
            state <= not state;
          end if;
        end if;
      end if;
    end if;
  end process;


  nd_tracker : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if rst_buf = '1' then
        sum_nd <= '0';
      else
        if nd_i = '1' and (cnt = ZERO or state = LOAD_B) then
          sum_nd <= '1';
        else
          sum_nd <= '0';
        end if;
      end if;
    end if;
  end process;

  data_buffering : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if rst_buf = '0' then
        if (nd_i = '1') then
          if (state = LOAD_A) then
            a_buf <= dat_i;
            b_buf <= (others => '0');
          else
            b_buf <= dat_i;
          end if;
        end if;
      end if;
    end if;
  end process;


end Behavioral;

