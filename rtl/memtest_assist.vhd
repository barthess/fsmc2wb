library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;


entity memtest_assist is
  generic (
    AW : positive;
    DW : positive
  );
	port(
		clk_i       : in  std_logic;

    BRAM_FILL   : in std_logic;
    BRAM_DBG    : out std_logic;
    
		BRAM_CLK    : out std_logic;   -- memory clock
		BRAM_A      : out std_logic_vector(AW-1 downto 0); -- memory address
		BRAM_DO     : out std_logic_vector(DW-1 downto 0); -- memory data in
		BRAM_DI     : in  std_logic_vector(DW-1 downto 0); -- memory data out
		BRAM_EN     : out std_logic;   -- memory enable
		BRAM_WE     : out std_logic_vector(0    downto 0)    -- memory write enable
  );
end entity memtest_assist;


architecture rtl of memtest_assist is
  signal addr_cnt : std_logic_vector (AW-1 downto 0) := (others => '0');
  signal a_reg  : std_logic_vector(AW-1 downto 0);
  signal do_reg : std_logic_vector(AW-1 downto 0);
  signal di_reg : std_logic_vector(DW-1 downto 0);
  signal we_reg : std_logic_vector(0 downto 0);
begin
	BRAM_CLK <= clk_i;
  BRAM_EN  <= '1';
  BRAM_DO(DW-1 downto AW) <= (others => '0');  
  BRAM_A <= a_reg;
  BRAM_DO(AW-1 downto 0) <= do_reg;
  BRAM_WE  <= we_reg;

  --
  --
  --
	main : process(clk_i) is
	begin
    if rising_edge(clk_i) then
      if (BRAM_FILL = '0') then
        we_reg <= "0";
        a_reg <= (others => '0');
        addr_cnt <= (others => '0');
        di_reg <= BRAM_DI;
        if (di_reg = x"55AA66BB") then
          BRAM_DBG <= '1';
        else
          BRAM_DBG <= '0';
        end if;
      else
        we_reg <= "1";
        addr_cnt <= addr_cnt + 1;
        a_reg    <= addr_cnt(AW-1 downto 0);
        do_reg <= addr_cnt;
      end if;
    end if;
	end process;
  
end architecture rtl;


