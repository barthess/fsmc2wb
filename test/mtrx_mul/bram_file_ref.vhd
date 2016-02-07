----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:13:10 01/28/2016 
-- Design Name: 
-- Module Name:    pseudo_bram_r - Behavioral 
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
USE ieee.std_logic_1164.ALL;
use ieee.std_logic_textio.all;
use std.textio.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity bram_file_ref is
  Generic (
    PREFIX  : string (1 to 1)
  );
  Port (
    clk_i : in  STD_LOGIC;
    ce_i  : in  STD_LOGIC;
    we_i  : in  std_logic;
    adr_i : in  STD_LOGIC_VECTOR (9  downto 0);
    dat_i : in  STD_LOGIC_VECTOR (63 downto 0);
    -- this values needs to open correct file
    m_i   : in  integer;
    p_i   : in  integer;
    n_i   : in  integer
    );
end bram_file_ref;



architecture Behavioral of bram_file_ref is
begin
  
  main : process(clk_i)
    file f : text;
    variable l : line;
    variable fpath : string(1 to 19) := "test/mtrx_mul/stim/";
    variable adr_cnt : integer;
    variable dat_read : std_logic_vector(63 downto 0);
  begin
    if rising_edge(clk_i) then
      if ce_i = '1' then
        file_close(f);
        file_open(f, 
                  fpath & PREFIX     & "_" &
                  integer'image(m_i) & "_" &
                  integer'image(p_i) & "_" & 
                  integer'image(n_i) & ".txt", 
                  READ_MODE);
        adr_cnt := to_integer(unsigned(adr_i));

        if (we_i = '1') then
          -- find specified string in file
          loop
            readline(f, l);
            hread(l, dat_read);
            if (adr_cnt = 0) then
              exit;
            end if;
            adr_cnt := adr_cnt - 1;
          end loop;

          -- check and compare
          --assert (dat_read = dat_i) report "Result incorrect!" severity failure;
        end if;
        
      end if;
    end if; -- clk
  end process;

end Behavioral;

