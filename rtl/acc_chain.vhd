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

entity acc_chain is
  Generic (
    -- bypass input directly to output for testing of previouse levels
    --bypass : std_logic := 0;
    -- length of accumulator chain. Chain able to accumulate 2**LEN numbers
    LEN : positive := 5
  );
  Port (
    clk_i : in  STD_LOGIC;
    rst_i : in  STD_LOGIC;
    ce_i  : in  STD_LOGIC;
    nd_i  : in  STD_LOGIC;
    len_i : in  STD_LOGIC_VECTOR (LEN-1 downto 0); -- number of input arguments - 1
    dat_i : in  STD_LOGIC_VECTOR (63 downto 0);
    dat_o : out STD_LOGIC_VECTOR (63 downto 0);
    rdy_o : out STD_LOGIC
  );
end acc_chain;

architecture Behavioral of acc_chain is
  
  -- Link counter regitsters
  type link_cnt_t is array(LEN-1 downto 0) of std_logic_vector(LEN-1 downto 0);
  signal link_cnt : link_cnt_t;
  
  -- Link connection registers
  type link_dat_t is array(LEN downto 0) of std_logic_vector(63 downto 0);
  signal link_dat : link_dat_t;
  signal nd_rdy : std_logic_vector (LEN downto 0);
  
--  signal len4 : std_logic_vector (LEN-1 downto 0) := (others => '0'); -- 32 to 16
--  signal len3 : std_logic_vector (LEN-1 downto 0) := (others => '0'); -- 16 to 8
--  signal len2 : std_logic_vector (LEN-1 downto 0) := (others => '0'); -- 8 to 4
--  signal len1 : std_logic_vector (LEN-1 downto 0) := (others => '0'); -- 4 to 2
--  signal len0 : std_logic_vector (LEN-1 downto 0) := (others => '0'); -- 2 to 1
begin

  -- Очень важно для каждого звена загрузить правильное значение счетчика.
  -- При продвижении от входа к выходу, на кажом звене счетчик должен 
  -- сдвигаться вправо на 1 бит без переноса (по сути, делиться на 2).
  link_cnt(0) <= len_i;
  brams2mul : for n in 1 to LEN-1 generate 
  begin
    link_cnt(n)(LEN-1-n downto 0) <= len_i(LEN-1 downto n);
    link_cnt(n)(LEN-1 downto LEN-n) <= (others => '0');
  end generate;

  -- input  - link #0
  -- output - link #LEN-1  
  nd_rdy(0) <= nd_i;
  link_dat(0) <= dat_i;
  dat_o <= link_dat(LEN);
  
  acc_chain : for n in 0 to LEN-1 generate 
  begin
    acc_link : entity work.acc_link
      generic map (
        WIDTH => LEN
      )
      port map (
        clk_i => clk_i,
        rst_i => rst_i,
        ce_i  => ce_i,
        cnt_i => link_cnt(n),
        
        dat_i => link_dat(n),
        dat_o => link_dat(n+1),
        
        nd_i  => nd_rdy(n),
        rdy_o => nd_rdy(n+1)
      );
  end generate;


end Behavioral;


