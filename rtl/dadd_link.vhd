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
    WIDTH : positive := 5
  );
  Port (
    clk_i : in  STD_LOGIC;
    rst_i : in  STD_LOGIC;
    ce_i  : in  STD_LOGIC;
    nd_i  : in  STD_LOGIC;
    -- number of input values for state tracking
    -- NOTE: 0 denotes 1 input value
    cnt_i : in  STD_LOGIC_VECTOR (WIDTH-1 downto 0);
    dat_i : in  STD_LOGIC_VECTOR (63 downto 0);
    dat_o : out STD_LOGIC_VECTOR (63 downto 0);
    rdy_o : out STD_LOGIC
  );
end dadd_link;


architecture Behavioral of dadd_link is
  constant ZERO : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
  signal cnt   : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
  signal a_buf : std_logic_vector(63 downto 0) := (others => '0');
  signal b_buf : std_logic_vector(63 downto 0) := (others => '0');
  signal sum_nd : std_logic := '0';
  
  signal   state  : std_logic := '0';
  constant LOAD_A : std_logic := '0';
  constant LOAD_B : std_logic := '1';
begin
  
  dadd : entity work.dadd
    port map (
      clk     => clk_i,
      ce      => ce_i,
      a       => a_buf,
      b       => b_buf,
      result  => dat_o,
      rdy     => rdy_o,
      operation_nd => sum_nd
    );


  state_switcher : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if rst_i = '1' then
        state <= LOAD_A;
        cnt   <= cnt_i;
      else
        if (ce_i = '1') and (nd_i = '1') then
          if (cnt = ZERO) then
            cnt   <= cnt_i;
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
      if rst_i = '1' then
        sum_nd <= '0';
      else
        if (ce_i = '1') then
          if nd_i = '1' and (cnt = ZERO or state = LOAD_B) then
            sum_nd <= '1';
          else
            sum_nd <= '0';
          end if;
        end if;
      end if;
    end if;
  end process;

  
  dat2buf : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if rst_i = '0' then
        if (nd_i = '1') and (ce_i = '1') then
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

