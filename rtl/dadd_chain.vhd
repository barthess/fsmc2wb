----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    09:53:39 01/21/2016 
-- Design Name: 
-- Module Name:    acc_chain - Behavioral 
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity dadd_chain is
  Generic (
    -- length of accumulator chain. Zero forbidden.
    -- As a result the chain able to accumulate 2**LEN numbers
    LEN : positive := 5
  );
  Port (
    clk_i : in  STD_LOGIC;
    rst_i : in  STD_LOGIC;
    nd_i  : in  STD_LOGIC; -- input data valid
    cnt_i : in  STD_LOGIC_VECTOR (LEN-1 downto 0); -- Number of input arguments. 0 denotes single argument.
    dat_i : in  STD_LOGIC_VECTOR (63 downto 0);
    dat_o : out STD_LOGIC_VECTOR (63 downto 0);
    rdy_o : out STD_LOGIC -- output data valid
  );
end dadd_chain;

architecture Behavioral of dadd_chain is
  
  -- Link counter regitsters
--  type link_cnt_t is array(LEN-1 downto 0) of std_logic_vector(LEN-1 downto 0);
--  signal link_cnt : link_cnt_t;
  
  -- Link connection registers
  type link_dat_t is array(LEN downto 0) of std_logic_vector(63 downto 0);
  signal link_dat : link_dat_t;
  signal nd2rdy : std_logic_vector (LEN downto 0);

begin

  -- Очень важно для каждого звена загрузить правильное значение счетчика.
  -- При продвижении от входа к выходу, на кажом звене счетчик должен 
  -- сдвигаться вправо на 1 бит без переноса (по сути, делиться на 2).
--  link_cnt(0) <= cnt_i;
--  brams2mul : for n in 1 to LEN-1 generate 
--  begin
--    link_cnt(n)(LEN-1-n downto 0) <= cnt_i(LEN-1 downto n);
--    link_cnt(n)(LEN-1 downto LEN-n) <= (others => '0');
--  end generate;

  -- input  - link #0
  -- output - link #LEN-1  
  nd2rdy(0) <= nd_i;
  link_dat(0) <= dat_i;
  dat_o <= link_dat(LEN);
  rdy_o <= nd2rdy(LEN);
  
  dadd_chain : for n in 0 to LEN-1 generate 
  begin
    dadd_link : entity work.dadd_link
      generic map (
        WIDTH => LEN - n
      )
      port map (
        clk_i => clk_i,
        rst_i => rst_i,
        cnt_i => cnt_i(LEN-1 downto n),

        dat_i => link_dat(n),
        dat_o => link_dat(n+1),
        
        nd_i  => nd2rdy(n),
        rdy_o => nd2rdy(n+1)
      );
  end generate;


end Behavioral;


