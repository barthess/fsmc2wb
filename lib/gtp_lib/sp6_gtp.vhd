
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;


--***************************** Entity Declaration ****************************

entity sp6_gtp is
generic
(
    -- Simulation attributes
    WRAPPER_SIM_GTPRESET_SPEEDUP    : integer   := 0; -- Set to 1 to speed up sim reset
    WRAPPER_CLK25_DIVIDER_0         : integer   := 10;
    WRAPPER_CLK25_DIVIDER_1         : integer   := 10;
    WRAPPER_PLL_DIVSEL_FB_0         : integer   := 2;
    WRAPPER_PLL_DIVSEL_FB_1         : integer   := 2;
    WRAPPER_PLL_DIVSEL_REF_0        : integer   := 1;
    WRAPPER_PLL_DIVSEL_REF_1        : integer   := 1;
    WRAPPER_SIMULATION              : integer   := 0  -- Set to 1 for simulation    
);
port
(
    
    --_________________________________________________________________________
    --_________________________________________________________________________
    --TILE0  (X0_Y1)

 
    --------------------------------- PLL Ports --------------------------------
    TILE0_CLK00_IN                          : in   std_logic;
    TILE0_CLK01_IN                          : in   std_logic;
    TILE0_GTPRESET0_IN                      : in   std_logic;
    TILE0_GTPRESET1_IN                      : in   std_logic;
    TILE0_PLLLKDET0_OUT                     : out  std_logic;
    TILE0_PLLLKDET1_OUT                     : out  std_logic;
    TILE0_RESETDONE0_OUT                    : out  std_logic;
    TILE0_RESETDONE1_OUT                    : out  std_logic;
    ----------------------- Receive Ports - 8b10b Decoder ----------------------
    TILE0_RXCHARISCOMMA0_OUT                : out  std_logic;
    TILE0_RXCHARISCOMMA1_OUT                : out  std_logic;
    TILE0_RXCHARISK0_OUT                    : out  std_logic;
    TILE0_RXCHARISK1_OUT                    : out  std_logic;
    TILE0_RXDISPERR0_OUT                    : out  std_logic;
    TILE0_RXDISPERR1_OUT                    : out  std_logic;
    TILE0_RXNOTINTABLE0_OUT                 : out  std_logic;
    TILE0_RXNOTINTABLE1_OUT                 : out  std_logic;
    --------------- Receive Ports - Comma Detection and Alignment --------------
    TILE0_RXBYTEISALIGNED0_OUT              : out  std_logic;
    TILE0_RXBYTEISALIGNED1_OUT              : out  std_logic;
    TILE0_RXBYTEREALIGN0_OUT                : out  std_logic;
    TILE0_RXBYTEREALIGN1_OUT                : out  std_logic;
    TILE0_RXENMCOMMAALIGN0_IN               : in   std_logic;
    TILE0_RXENMCOMMAALIGN1_IN               : in   std_logic;
    TILE0_RXENPCOMMAALIGN0_IN               : in   std_logic;
    TILE0_RXENPCOMMAALIGN1_IN               : in   std_logic;
    ------------------- Receive Ports - RX Data Path interface -----------------
    TILE0_RXDATA0_OUT                       : out  std_logic_vector(7 downto 0);
    TILE0_RXDATA1_OUT                       : out  std_logic_vector(7 downto 0);
    TILE0_RXRECCLK0_OUT                     : out  std_logic;
    TILE0_RXRECCLK1_OUT                     : out  std_logic;
    TILE0_RXUSRCLK0_IN                      : in   std_logic;
    TILE0_RXUSRCLK1_IN                      : in   std_logic;
    TILE0_RXUSRCLK20_IN                     : in   std_logic;
    TILE0_RXUSRCLK21_IN                     : in   std_logic;
    ------- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR ------
    TILE0_RXN0_IN                           : in   std_logic;
    TILE0_RXN1_IN                           : in   std_logic;
    TILE0_RXP0_IN                           : in   std_logic;
    TILE0_RXP1_IN                           : in   std_logic;
    ----------- Receive Ports - RX Elastic Buffer and Phase Alignment ----------
    TILE0_RXBUFSTATUS0_OUT                  : out  std_logic_vector(2 downto 0);
    TILE0_RXBUFSTATUS1_OUT                  : out  std_logic_vector(2 downto 0);
    ---------------------------- TX/RX Datapath Ports --------------------------
    TILE0_GTPCLKOUT0_OUT                    : out  std_logic_vector(1 downto 0);
    TILE0_GTPCLKOUT1_OUT                    : out  std_logic_vector(1 downto 0);
    ------------------- Transmit Ports - 8b10b Encoder Control -----------------
    TILE0_TXCHARISK0_IN                     : in   std_logic;
    TILE0_TXCHARISK1_IN                     : in   std_logic;
    --------------- Transmit Ports - TX Buffer and Phase Alignment -------------
    TILE0_TXBUFSTATUS0_OUT                  : out  std_logic_vector(1 downto 0);
    TILE0_TXBUFSTATUS1_OUT                  : out  std_logic_vector(1 downto 0);
    ------------------ Transmit Ports - TX Data Path interface -----------------
    TILE0_TXDATA0_IN                        : in   std_logic_vector(7 downto 0);
    TILE0_TXDATA1_IN                        : in   std_logic_vector(7 downto 0);
    TILE0_TXUSRCLK0_IN                      : in   std_logic;
    TILE0_TXUSRCLK1_IN                      : in   std_logic;
    TILE0_TXUSRCLK20_IN                     : in   std_logic;
    TILE0_TXUSRCLK21_IN                     : in   std_logic;
    --------------- Transmit Ports - TX Driver and OOB signalling --------------
    TILE0_TXN0_OUT                          : out  std_logic;
    TILE0_TXN1_OUT                          : out  std_logic;
    TILE0_TXP0_OUT                          : out  std_logic;
    TILE0_TXP1_OUT                          : out  std_logic


);


end sp6_gtp;

architecture RTL of sp6_gtp is
  attribute CORE_GENERATION_INFO           : string;
  attribute CORE_GENERATION_INFO of RTL    : architecture is "sp6_gtp,s6_gtpwizard_v1_11,{gtp0_protocol_file=Start_from_scratch,gtp1_protocol_file=Use_GTP0_settings}";

--***************************** Signal Declarations *****************************

    -- ground and tied_to_vcc_i signals
    signal  tied_to_ground_i                :   std_logic;
    signal  tied_to_ground_vec_i            :   std_logic_vector(63 downto 0);
    signal  tied_to_vcc_i                   :   std_logic;
    
    signal  tile0_plllkdet0_i       :   std_logic;  
    signal  tile0_plllkdet1_i       :   std_logic;  

    signal  tile0_plllkdet0_i2       :   std_logic; 
    signal  count00                  :   std_logic_vector(4 downto 0);
    signal  tile0_plllkdet1_i2       :   std_logic;  
    signal  count10                  :   std_logic_vector(4 downto 0);
     

--*************************** Component Declarations **************************

component sp6_gtp_tile 
generic
(
    -- Simulation attributes
    TILE_SIM_GTPRESET_SPEEDUP    : integer   := 0; -- Set to 1 to speed up sim reset 
    TILE_CLK25_DIVIDER_0         : integer   := 10; 
    TILE_CLK25_DIVIDER_1         : integer   := 10;
    TILE_PLL_DIVSEL_FB_0         : integer   := 2;
    TILE_PLL_DIVSEL_FB_1         : integer   := 2;
    TILE_PLL_DIVSEL_REF_0        : integer   := 1;
    TILE_PLL_DIVSEL_REF_1        : integer   := 1;
 
    --
    TILE_PLL_SOURCE_0            : string    := "PLL0";
    TILE_PLL_SOURCE_1            : string    := "PLL1"    
);
port 
(   
    --------------------------------- PLL Ports --------------------------------
    CLK00_IN                                : in   std_logic;
    CLK01_IN                                : in   std_logic;
    GTPRESET0_IN                            : in   std_logic;
    GTPRESET1_IN                            : in   std_logic;
    PLLLKDET0_OUT                           : out  std_logic;
    PLLLKDET1_OUT                           : out  std_logic;
    RESETDONE0_OUT                          : out  std_logic;
    RESETDONE1_OUT                          : out  std_logic;
    ----------------------- Receive Ports - 8b10b Decoder ----------------------
    RXCHARISCOMMA0_OUT                      : out  std_logic;
    RXCHARISCOMMA1_OUT                      : out  std_logic;
    RXCHARISK0_OUT                          : out  std_logic;
    RXCHARISK1_OUT                          : out  std_logic;
    RXDISPERR0_OUT                          : out  std_logic;
    RXDISPERR1_OUT                          : out  std_logic;
    RXNOTINTABLE0_OUT                       : out  std_logic;
    RXNOTINTABLE1_OUT                       : out  std_logic;
    --------------- Receive Ports - Comma Detection and Alignment --------------
    RXBYTEISALIGNED0_OUT                    : out  std_logic;
    RXBYTEISALIGNED1_OUT                    : out  std_logic;
    RXBYTEREALIGN0_OUT                      : out  std_logic;
    RXBYTEREALIGN1_OUT                      : out  std_logic;
    RXENMCOMMAALIGN0_IN                     : in   std_logic;
    RXENMCOMMAALIGN1_IN                     : in   std_logic;
    RXENPCOMMAALIGN0_IN                     : in   std_logic;
    RXENPCOMMAALIGN1_IN                     : in   std_logic;
    ------------------- Receive Ports - RX Data Path interface -----------------
    RXDATA0_OUT                             : out  std_logic_vector(7 downto 0);
    RXDATA1_OUT                             : out  std_logic_vector(7 downto 0);
    RXRECCLK0_OUT                           : out  std_logic;
    RXRECCLK1_OUT                           : out  std_logic;
    RXUSRCLK0_IN                            : in   std_logic;
    RXUSRCLK1_IN                            : in   std_logic;
    RXUSRCLK20_IN                           : in   std_logic;
    RXUSRCLK21_IN                           : in   std_logic;
    ------- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR ------
    RXN0_IN                                 : in   std_logic;
    RXN1_IN                                 : in   std_logic;
    RXP0_IN                                 : in   std_logic;
    RXP1_IN                                 : in   std_logic;
    ----------- Receive Ports - RX Elastic Buffer and Phase Alignment ----------
    RXBUFSTATUS0_OUT                        : out  std_logic_vector(2 downto 0);
    RXBUFSTATUS1_OUT                        : out  std_logic_vector(2 downto 0);
    ---------------------------- TX/RX Datapath Ports --------------------------
    GTPCLKOUT0_OUT                          : out  std_logic_vector(1 downto 0);
    GTPCLKOUT1_OUT                          : out  std_logic_vector(1 downto 0);
    ------------------- Transmit Ports - 8b10b Encoder Control -----------------
    TXCHARISK0_IN                           : in   std_logic;
    TXCHARISK1_IN                           : in   std_logic;
    --------------- Transmit Ports - TX Buffer and Phase Alignment -------------
    TXBUFSTATUS0_OUT                        : out  std_logic_vector(1 downto 0);
    TXBUFSTATUS1_OUT                        : out  std_logic_vector(1 downto 0);
    ------------------ Transmit Ports - TX Data Path interface -----------------
    TXDATA0_IN                              : in   std_logic_vector(7 downto 0);
    TXDATA1_IN                              : in   std_logic_vector(7 downto 0);
    TXUSRCLK0_IN                            : in   std_logic;
    TXUSRCLK1_IN                            : in   std_logic;
    TXUSRCLK20_IN                           : in   std_logic;
    TXUSRCLK21_IN                           : in   std_logic;
    --------------- Transmit Ports - TX Driver and OOB signalling --------------
    TXN0_OUT                                : out  std_logic;
    TXN1_OUT                                : out  std_logic;
    TXP0_OUT                                : out  std_logic;
    TXP1_OUT                                : out  std_logic


);
end component;


--********************************* Main Body of Code**************************

begin                       

    tied_to_ground_vec_i(63 downto 0)   <= (others => '0');

simulation : if WRAPPER_SIMULATION = 1 generate

    TILE0_PLLLKDET0_OUT                     <= tile0_plllkdet0_i2;

process(TILE0_CLK00_IN,TILE0_GTPRESET0_IN)
begin
  if (TILE0_GTPRESET0_IN = '1') then    
    count00 <= "00000";
  elsif(TILE0_CLK00_IN'event and TILE0_CLK00_IN ='1') then
    if((count00 = "10100") or (tile0_plllkdet0_i = '0')) then
      count00 <= "00000";
    else
      count00 <= count00 + "00001";      
    end if;     
  end if;
end process; 

process(TILE0_CLK00_IN,tile0_plllkdet0_i)
begin
  if(tile0_plllkdet0_i = '0') then
    tile0_plllkdet0_i2 <= '0';
  elsif(TILE0_CLK00_IN'event and TILE0_CLK00_IN ='1') then
    if((count00 = "10100") and (tile0_plllkdet0_i = '1')) then
      tile0_plllkdet0_i2 <= '1';
    end if;     
  end if;
end process; 

    TILE0_PLLLKDET1_OUT                     <= tile0_plllkdet1_i2;

process(TILE0_CLK01_IN,TILE0_GTPRESET1_IN)
begin
  if (TILE0_GTPRESET1_IN = '1') then    
    count10 <= "00000";
  elsif(TILE0_CLK01_IN'event and TILE0_CLK01_IN ='1') then
    if((count10 = "10100") or (tile0_plllkdet1_i = '0')) then
      count10 <= "00000";
    else
      count10 <= count10 + "00001";
    end if;     
  end if;
end process; 

process(TILE0_CLK01_IN,tile0_plllkdet1_i)
begin
  if(tile0_plllkdet1_i = '0') then
    tile0_plllkdet1_i2 <= '0';
  elsif(TILE0_CLK01_IN'event and TILE0_CLK01_IN ='1') then
    if((count10 = "10100") and (tile0_plllkdet1_i = '1')) then 
      tile0_plllkdet1_i2 <= '1';
    end if;
  end if;
end process; 
  


end generate simulation;

implementation : if WRAPPER_SIMULATION = 0 generate

    TILE0_PLLLKDET0_OUT                     <= tile0_plllkdet0_i;
    TILE0_PLLLKDET1_OUT                     <= tile0_plllkdet1_i;

end generate implementation;

    --------------------------- Tile Instances  -------------------------------   


    --_________________________________________________________________________
    --_________________________________________________________________________
    --TILE0  (X0_Y1)

    tile0_sp6_gtp_i : sp6_gtp_tile
    generic map
    (
        -- Simulation attributes
        TILE_SIM_GTPRESET_SPEEDUP    => WRAPPER_SIM_GTPRESET_SPEEDUP,
        TILE_CLK25_DIVIDER_0         => WRAPPER_CLK25_DIVIDER_0,
        TILE_CLK25_DIVIDER_1         => WRAPPER_CLK25_DIVIDER_1,
        TILE_PLL_DIVSEL_FB_0         => WRAPPER_PLL_DIVSEL_FB_0,
        TILE_PLL_DIVSEL_FB_1         => WRAPPER_PLL_DIVSEL_FB_1,
        TILE_PLL_DIVSEL_REF_0        => WRAPPER_PLL_DIVSEL_REF_0,
        TILE_PLL_DIVSEL_REF_1        => WRAPPER_PLL_DIVSEL_REF_1,
        
        -- 
        TILE_PLL_SOURCE_0            => "PLL0",
        TILE_PLL_SOURCE_1            => "PLL1"
    )
    port map
    (
        --------------------------------- PLL Ports --------------------------------
        CLK00_IN                        =>      TILE0_CLK00_IN,
        CLK01_IN                        =>      TILE0_CLK01_IN,
        GTPRESET0_IN                    =>      TILE0_GTPRESET0_IN,
        GTPRESET1_IN                    =>      TILE0_GTPRESET1_IN,
        PLLLKDET0_OUT                   =>      tile0_plllkdet0_i,
        PLLLKDET1_OUT                   =>      tile0_plllkdet1_i,
        RESETDONE0_OUT                  =>      TILE0_RESETDONE0_OUT,
        RESETDONE1_OUT                  =>      TILE0_RESETDONE1_OUT,
        ----------------------- Receive Ports - 8b10b Decoder ----------------------
        RXCHARISCOMMA0_OUT              =>      TILE0_RXCHARISCOMMA0_OUT,
        RXCHARISCOMMA1_OUT              =>      TILE0_RXCHARISCOMMA1_OUT,
        RXCHARISK0_OUT                  =>      TILE0_RXCHARISK0_OUT,
        RXCHARISK1_OUT                  =>      TILE0_RXCHARISK1_OUT,
        RXDISPERR0_OUT                  =>      TILE0_RXDISPERR0_OUT,
        RXDISPERR1_OUT                  =>      TILE0_RXDISPERR1_OUT,
        RXNOTINTABLE0_OUT               =>      TILE0_RXNOTINTABLE0_OUT,
        RXNOTINTABLE1_OUT               =>      TILE0_RXNOTINTABLE1_OUT,
        --------------- Receive Ports - Comma Detection and Alignment --------------
        RXBYTEISALIGNED0_OUT            =>      TILE0_RXBYTEISALIGNED0_OUT,
        RXBYTEISALIGNED1_OUT            =>      TILE0_RXBYTEISALIGNED1_OUT,
        RXBYTEREALIGN0_OUT              =>      TILE0_RXBYTEREALIGN0_OUT,
        RXBYTEREALIGN1_OUT              =>      TILE0_RXBYTEREALIGN1_OUT,
        RXENMCOMMAALIGN0_IN             =>      TILE0_RXENMCOMMAALIGN0_IN,
        RXENMCOMMAALIGN1_IN             =>      TILE0_RXENMCOMMAALIGN1_IN,
        RXENPCOMMAALIGN0_IN             =>      TILE0_RXENPCOMMAALIGN0_IN,
        RXENPCOMMAALIGN1_IN             =>      TILE0_RXENPCOMMAALIGN1_IN,
        ------------------- Receive Ports - RX Data Path interface -----------------
        RXDATA0_OUT                     =>      TILE0_RXDATA0_OUT,
        RXDATA1_OUT                     =>      TILE0_RXDATA1_OUT,
        RXRECCLK0_OUT                   =>      TILE0_RXRECCLK0_OUT,
        RXRECCLK1_OUT                   =>      TILE0_RXRECCLK1_OUT,
        RXUSRCLK0_IN                    =>      TILE0_RXUSRCLK0_IN,
        RXUSRCLK1_IN                    =>      TILE0_RXUSRCLK1_IN,
        RXUSRCLK20_IN                   =>      TILE0_RXUSRCLK20_IN,
        RXUSRCLK21_IN                   =>      TILE0_RXUSRCLK21_IN,
        ------- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR ------
        RXN0_IN                         =>      TILE0_RXN0_IN,
        RXN1_IN                         =>      TILE0_RXN1_IN,
        RXP0_IN                         =>      TILE0_RXP0_IN,
        RXP1_IN                         =>      TILE0_RXP1_IN,
        ----------- Receive Ports - RX Elastic Buffer and Phase Alignment ----------
        RXBUFSTATUS0_OUT                =>      TILE0_RXBUFSTATUS0_OUT,
        RXBUFSTATUS1_OUT                =>      TILE0_RXBUFSTATUS1_OUT,
        ---------------------------- TX/RX Datapath Ports --------------------------
        GTPCLKOUT0_OUT                  =>      TILE0_GTPCLKOUT0_OUT,
        GTPCLKOUT1_OUT                  =>      TILE0_GTPCLKOUT1_OUT,
        ------------------- Transmit Ports - 8b10b Encoder Control -----------------
        TXCHARISK0_IN                   =>      TILE0_TXCHARISK0_IN,
        TXCHARISK1_IN                   =>      TILE0_TXCHARISK1_IN,
        --------------- Transmit Ports - TX Buffer and Phase Alignment -------------
        TXBUFSTATUS0_OUT                =>      TILE0_TXBUFSTATUS0_OUT,
        TXBUFSTATUS1_OUT                =>      TILE0_TXBUFSTATUS1_OUT,
        ------------------ Transmit Ports - TX Data Path interface -----------------
        TXDATA0_IN                      =>      TILE0_TXDATA0_IN,
        TXDATA1_IN                      =>      TILE0_TXDATA1_IN,
        TXUSRCLK0_IN                    =>      TILE0_TXUSRCLK0_IN,
        TXUSRCLK1_IN                    =>      TILE0_TXUSRCLK1_IN,
        TXUSRCLK20_IN                   =>      TILE0_TXUSRCLK20_IN,
        TXUSRCLK21_IN                   =>      TILE0_TXUSRCLK21_IN,
        --------------- Transmit Ports - TX Driver and OOB signalling --------------
        TXN0_OUT                        =>      TILE0_TXN0_OUT,
        TXN1_OUT                        =>      TILE0_TXN1_OUT,
        TXP0_OUT                        =>      TILE0_TXP0_OUT,
        TXP1_OUT                        =>      TILE0_TXP1_OUT

    );

     
end RTL;
