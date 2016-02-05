library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

--
--
--
entity mtrx_mov_iter is
  Generic (
    MTRX_AW : positive := 5 -- 2**MTRX_AW = max matrix index
  );
  Port (
    -- control interface
    clk_i  : in  std_logic;
    rst_i  : in  std_logic; -- active high. Must be used before every new operation because it stores new sizes in registers
    m_size : in  std_logic_vector(MTRX_AW-1 downto 0);
    n_size : in  std_logic_vector(MTRX_AW-1 downto 0);

    -- operation select
    trn_not_eye : in std_logic;

    adr_a_o   : out std_logic_vector(2*MTRX_AW-1 downto 0);
    adr_c_o   : out std_logic_vector(2*MTRX_AW-1 downto 0);
    valid_a_o : out std_logic;
    valid_c_o : out std_logic;
    end_a_o   : out std_logic;
    end_c_o   : out std_logic;
    ce_a_i    : in  std_logic;
    ce_c_i    : in  std_logic;

    eye_stb_o : out std_logic  -- active high when element must be overwritten by 1
  );
end mtrx_mov_iter;


-----------------------------------------------------------------------------

architecture beh of mtrx_mov_iter is
  
  -- operand and result addresses registers
  constant ZERO  : std_logic_vector(MTRX_AW-1   downto 0) := (others => '0');
  constant ZERO2 : std_logic_vector(2*MTRX_AW-1 downto 0) := (others => '0');
  signal adr_trn, adr_eye : std_logic_vector(2*MTRX_AW-1 downto 0) := (others => '0');
  signal end_trn, end_eye : std_logic := '0';
  signal dv_trn,  dv_eye : std_logic := '0';
  signal ce_trn,  ce_eye : std_logic := '0';

begin
  
  -- sequential address generator for 
  -- A address
  -- connected directly to output without muxers
  iter_seq : entity work.mtrx_iter_seq
  generic map (
    MTRX_AW => MTRX_AW
  )
  port map (
    rst_i  => rst_i,
    clk_i  => clk_i,
    m_i    => m_size,
    n_i    => n_size,
    ce_i   => ce_a_i,
    end_o  => end_a_o,
    dv_o   => valid_a_o,
    adr_o  => adr_a_o
  );

  -- CE demuxer for transpose and eye
  trn_not_eye_ce_demuxer : entity work.demuxer
  generic map(
    AW => 1,
    DW => 1,
    default => '0'
  )
  port map(
    A(0)  => trn_not_eye,
    di(0) => ce_c_i,
    do(1) => ce_trn,
    do(0) => ce_eye
  );
  
  -- transposed address generator for 
  -- C address
  -- output must be connected via muxer
  iter_trn : entity work.mtrx_iter_trn
  generic map (
    MTRX_AW => MTRX_AW
  )
  port map (
    rst_i  => rst_i,
    clk_i  => clk_i,
    m_i    => m_size,
    n_i    => n_size,
    ce_i   => ce_trn,
    end_o  => end_trn,
    dv_o   => dv_trn,
    adr_o  => adr_trn
  );

  -- transposed address generator for 
  -- C address
  -- output must be connected via muxer
  -- Suitable for:
  -- CPY, EYE, SET
  iter_cpy_eye_set : entity work.mtrx_iter_eye
  generic map (
    MTRX_AW => MTRX_AW
  )
  port map (
    rst_i  => rst_i,
    clk_i  => clk_i,
    m_i    => m_size,
    n_i    => n_size,
    ce_i   => ce_eye,
    end_o  => end_eye,
    dv_o   => dv_eye,
    eye_o  => eye_stb_o,
    adr_o  => adr_eye
  );
  
  -- resolution function for 2 ready signals
  end_c_o   <= end_trn or end_eye;
  valid_c_o <= dv_trn  or dv_eye;

  -- switch outputs between trn and eye
  adr_c_o <= adr_trn when (trn_not_eye = '1') else adr_eye;


end beh;






