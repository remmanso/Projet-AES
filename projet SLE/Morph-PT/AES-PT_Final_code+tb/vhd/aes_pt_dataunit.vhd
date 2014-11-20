
library IEEE;
    use IEEE.std_logic_1164.all;
library WORK;
    use WORK.aes_pt_params.all;

entity aes_pt_dataunit is port (
    inH : in std_logic_vector( 31 downto 0 );
        pinH  : in std_logic_vector( 3 downto 0 );
    k : in std_logic_vector( 127 downto 0 );
        pk : in std_logic_vector( 15 downto 0 );
    ctrl_in  : in T_CTRL_IN;
    ctrl_key : in T_CTRL_KEY;
    ctrl_dec : in T_ENCDEC;
    ctrl_mix : in T_CTRL_MIX;
    clock, reset : in std_logic;
    broken : out std_logic_vector( 3 downto 0 );
    outH : out std_logic_vector( 31 downto 0 );
        poutH : out std_logic_vector( 3 downto 0 )       );
    end aes_pt_dataunit;


-- Architecture of the Component
architecture arch of aes_pt_dataunit is
    component aes_pt_row0 port(
        inA, inB, inC, inD, inH : in std_logic_vector( 7 downto 0 );
            pinA, pinB, pinC, pinD, pinH : in std_logic;
        kA, kB, kC, kD : in std_logic_vector( 7 downto 0 );
            pkA, pkB, pkC, pkD : in std_logic;
        inA1, inA2, inA3, inB1, inB2, inB3, inC1, inC2, inC3,
                    inD1, inD2, inD3 : std_logic_vector( 7 downto 0 );
            pinA1, pinA2, pinA3, pinB1, pinB2, pinB3, pinC1, pinC2, pinC3,
                    pinD1, pinD2, pinD3 : std_logic;
        ctrl_in  : in T_CTRL_IN;
        ctrl_key : in T_CTRL_KEY;
        ctrl_dec : in T_ENCDEC;
        ctrl_mix : in T_CTRL_MIX;
        clock, reset : in std_logic;
        broken : out std_logic;
        mixA, mixB, mixC, mixD : out std_logic_vector( 7 downto 0 );
            pmixA, pmixB, pmixC, pmixD : out std_logic ;
        outA, outB, outC, outD, outH : out std_logic_vector( 7 downto 0 );
            poutA, poutB, poutC, poutD, poutH : out std_logic   ) ;
        end component;
    component aes_pt_Row1 port (
        inA, inB, inC, inD, inH : in std_logic_vector( 7 downto 0 );
            pinA, pinB, pinC, pinD, pinH : in std_logic;
        kA, kB, kC, kD : in std_logic_vector( 7 downto 0 );
            pkA, pkB, pkC, pkD : in std_logic;
        inA0, inA2, inA3, inB0, inB2, inB3, inC0, inC2, inC3,
                    inD0, inD2, inD3 : std_logic_vector( 7 downto 0 );
            pinA0, pinA2, pinA3, pinB0, pinB2, pinB3, pinC0, pinC2, pinC3,
                    pinD0, pinD2, pinD3 : std_logic;
        ctrl_in  : in T_CTRL_IN;
        ctrl_key : in T_CTRL_KEY;
        ctrl_dec : in T_ENCDEC;
        ctrl_mix : in T_CTRL_MIX;
        clock, reset : in std_logic;
        broken : out std_logic;
        mixA, mixB, mixC, mixD : out std_logic_vector( 7 downto 0 );
            pmixA, pmixB, pmixC, pmixD : out std_logic ;
        outA, outB, outC, outD, outH : out std_logic_vector( 7 downto 0 );
            poutA, poutB, poutC, poutD, poutH : out std_logic   ) ;
        end component;
    component aes_pt_Row2 port (
        inA, inB, inC, inD, inH : in std_logic_vector( 7 downto 0 );
            pinA, pinB, pinC, pinD, pinH : in std_logic;
        kA, kB, kC, kD : in std_logic_vector( 7 downto 0 );
            pkA, pkB, pkC, pkD : in std_logic;
        inA0, inA1, inA3, inB0, inB1, inB3, inC0, inC1, inC3,
                    inD0, inD1, inD3 : std_logic_vector( 7 downto 0 );
            pinA0, pinA1, pinA3, pinB0, pinB1, pinB3, pinC0, pinC1, pinC3,
                    pinD0, pinD1, pinD3 : std_logic;
        ctrl_in  : in T_CTRL_IN;
        ctrl_key : in T_CTRL_KEY;
        ctrl_dec : in T_ENCDEC;
        ctrl_mix : in T_CTRL_MIX;
        clock, reset : in std_logic;
        broken : out std_logic;
        mixA, mixB, mixC, mixD : out std_logic_vector( 7 downto 0 );
            pmixA, pmixB, pmixC, pmixD : out std_logic ;
        outA, outB, outC, outD, outH : out std_logic_vector( 7 downto 0 );
            poutA, poutB, poutC, poutD, poutH : out std_logic   ) ;
        end component;
    component aes_pt_Row3 port (
        inA, inB, inC, inD, inH : in std_logic_vector( 7 downto 0 );
            pinA, pinB, pinC, pinD, pinH : in std_logic;
        kA, kB, kC, kD : in std_logic_vector( 7 downto 0 );
            pkA, pkB, pkC, pkD : in std_logic;
        inA0, inA1, inA2, inB0, inB1, inB2, inC0, inC1, inC2,
                    inD0, inD1, inD2 : std_logic_vector( 7 downto 0 );
            pinA0, pinA1, pinA2, pinB0, pinB1, pinB2, pinC0, pinC1, pinC2,
                    pinD0, pinD1, pinD2 : std_logic;
        ctrl_in  : in T_CTRL_IN;
        ctrl_key : in T_CTRL_KEY;
        ctrl_dec : in T_ENCDEC;
        ctrl_mix : in T_CTRL_MIX;
        clock, reset : in std_logic;
        broken : out std_logic;
        mixA, mixB, mixC, mixD : out std_logic_vector( 7 downto 0 );
            pmixA, pmixB, pmixC, pmixD : out std_logic ;
        outA, outB, outC, outD, outH : out std_logic_vector( 7 downto 0 );
            poutA, poutB, poutC, poutD, poutH : out std_logic   ) ;
        end component;
    signal inH0, inH1, inH2, inH3, outH0, outH1, outH2, outH3 : std_logic_vector( 7 downto 0 );
        signal pinH0, pinH1, pinH2, pinH3, poutH0, poutH1, poutH2, poutH3 : std_logic;
    signal kA0, kA1, kA2, kA3, kB0, kB1, kB2, kB3, kC0, kC1, kC2, kC3,
                kD0, kD1, kD2, kD3 : std_logic_vector( 7 downto 0 );
        signal pkA0, pkA1, pkA2, pkA3, pkB0, pkB1, pkB2, pkB3, pkC0, pkC1, pkC2, pkC3,
                pkD0, pkD1, pkD2, pkD3 : std_logic;
    signal inA1, inA3, inB1, inB3, inC1, inC3, inD1, inD3 : std_logic_vector( 7 downto 0 );
        signal pinA1, pinA3, pinB1, pinB3, pinC1, pinC3, pinD1, pinD3 : std_logic;
    signal mixA0, mixA1, mixA2, mixA3, mixB0, mixB1, mixB2, mixB3, mixC0, mixC1, mixC2, mixC3,
                mixD0, mixD1, mixD2, mixD3 : std_logic_vector( 7 downto 0 );
        signal pmixA0, pmixA1, pmixA2, pmixA3, pmixB0, pmixB1, pmixB2, pmixB3, pmixC0, pmixC1, pmixC2, pmixC3,
                pmixD0, pmixD1, pmixD2, pmixD3 : std_logic;
    signal outA0, outA1, outA2, outA3, outB0, outB1, outB2, outB3, outC0, outC1, outC2, outC3,
                outD0, outD1, outD2, outD3 : std_logic_vector( 7 downto 0 );
        signal poutA0, poutA1, poutA2, poutA3, poutB0, poutB1, poutB2, poutB3, poutC0, poutC1, poutC2, poutC3,
                poutD0, poutD1, poutD2, poutD3 : std_logic;
    signal broken0, broken1, broken2, broken3 : std_logic;
begin
    inH0 <= inH( 31 downto 24 );            pinH0 <= pinH( 3 );
    inH1 <= inH( 23 downto 16 );            pinH1 <= pinH( 2 );
    inH2 <= inH( 15 downto  8 );            pinH2 <= pinH( 1 );
    inH3 <= inH(  7 downto  0 );            pinH3 <= pinH( 0 );
    -- Row-wise key vector: 127..96|95..64|63..32|31..0
    kA0 <= k( 127 downto 120 );             pkA0 <= pk( 15 );
    kA1 <= k( 119 downto 112 );             pkA1 <= pk( 14 );
    kA2 <= k( 111 downto 104 );             pkA2 <= pk( 13 );
    kA3 <= k( 103 downto  96 );             pkA3 <= pk( 12 );
    kB0 <= k(  95 downto  88 );             pkB0 <= pk( 11 );
    kB1 <= k(  87 downto  80 );             pkB1 <= pk( 10 );
    kB2 <= k(  79 downto  72 );             pkB2 <= pk(  9 );
    kB3 <= k(  71 downto  64 );             pkB3 <= pk(  8 );
    kC0 <= k(  63 downto  56 );             pkC0 <= pk(  7 );
    kC1 <= k(  55 downto  48 );             pkC1 <= pk(  6 );
    kC2 <= k(  47 downto  40 );             pkC2 <= pk(  5 );
    kC3 <= k(  39 downto  32 );             pkC3 <= pk(  4 );
    kD0 <= k(  31 downto  24 );             pkD0 <= pk(  3 );
    kD1 <= k(  23 downto  16 );             pkD1 <= pk(  2 );
    kD2 <= k(  15 downto   8 );             pkD2 <= pk(  1 );
    kD3 <= k(   7 downto   0 );             pkD3 <= pk(  0 );
    ------------------------------------------------------------------------------------------------------
    inst_row0 : aes_pt_row0 port map(
        outA0, outB0, outC0, outD0, inH0, poutA0, poutB0, poutC0, poutD0, pinH0,
        kA0, kB0, kC0, kD0, pkA0, pkB0, pkC0, pkD0,
        mixA1, mixA2, mixA3, mixB1, mixB2, mixB3, mixC1, mixC2, mixC3, mixD1, mixD2, mixD3,
            pmixA1, pmixA2, pmixA3, pmixB1, pmixB2, pmixB3, pmixC1, pmixC2, pmixC3, pmixD1, pmixD2, pmixD3,
        ctrl_in, ctrl_key, ctrl_dec, ctrl_mix, clock, reset, broken0,
        mixA0, mixB0, mixC0, mixD0, pmixA0, pmixB0, pmixC0, pmixD0,
        outA0, outB0, outC0, outD0, outH0, poutA0, poutB0, poutC0, poutD0, poutH0   ) ;
    ------------------------------------------------------------------------------------------------------
    inA1   <= outB1 when ( ctrl_dec=S_ENC ) else outD1; pinA1   <= poutB1 when ( ctrl_dec=S_ENC ) else poutD1;
    inB1   <= outC1 when ( ctrl_dec=S_ENC ) else outA1; pinB1   <= poutC1 when ( ctrl_dec=S_ENC ) else poutA1;
    inC1   <= outD1 when ( ctrl_dec=S_ENC ) else outB1; pinC1   <= poutD1 when ( ctrl_dec=S_ENC ) else poutB1;
    inD1   <= outA1 when ( ctrl_dec=S_ENC ) else outC1; pinD1   <= poutA1 when ( ctrl_dec=S_ENC ) else poutC1;
    inst_row1 : aes_pt_row1 port map(
        inA1, inB1, inC1, inD1, inH1, pinA1, pinB1, pinC1, pinD1, pinH1,
        kA1, kB1, kC1, kD1, pkA1, pkB1, pkC1, pkD1,
        mixA0, mixA2, mixA3, mixB0, mixB2, mixB3, mixC0, mixC2, mixC3, mixD0, mixD2, mixD3,
            pmixA0, pmixA2, pmixA3, pmixB0, pmixB2, pmixB3, pmixC0, pmixC2, pmixC3, pmixD0, pmixD2, pmixD3,
        ctrl_in, ctrl_key, ctrl_dec, ctrl_mix, clock, reset, broken1,
        mixA1, mixB1, mixC1, mixD1, pmixA1, pmixB1, pmixC1, pmixD1,
        outA1, outB1, outC1, outD1, outH1, poutA1, poutB1, poutC1, poutD1, poutH1   ) ;
    ------------------------------------------------------------------------------------------------------
    inst_row2 : aes_pt_row2 port map(
        outC2, outD2, outA2, outB2, inH2, poutC2, poutD2, poutA2, poutB2, pinH2,
        kA2, kB2, kC2, kD2, pkA2, pkB2, pkC2, pkD2,
        mixA0, mixA1, mixA3, mixB0, mixB1, mixB3, mixC0, mixC1, mixC3, mixD0, mixD1, mixD3,
            pmixA0, pmixA1, pmixA3, pmixB0, pmixB1, pmixB3, pmixC0, pmixC1, pmixC3, pmixD0, pmixD1, pmixD3,
        ctrl_in, ctrl_key, ctrl_dec, ctrl_mix, clock, reset, broken2,
        mixA2, mixB2, mixC2, mixD2, pmixA2, pmixB2, pmixC2, pmixD2,
        outA2, outB2, outC2, outD2, outH2, poutA2, poutB2, poutC2, poutD2, poutH2   ) ;
    ------------------------------------------------------------------------------------------------------
    inA3 <= outD3 when ( ctrl_dec=S_ENC ) else outB3; pinA3 <= poutD3 when ( ctrl_dec=S_ENC ) else poutB3;
    inB3 <= outA3 when ( ctrl_dec=S_ENC ) else outC3; pinB3 <= poutA3 when ( ctrl_dec=S_ENC ) else poutC3;
    inC3 <= outB3 when ( ctrl_dec=S_ENC ) else outD3; pinC3 <= poutB3 when ( ctrl_dec=S_ENC ) else poutD3;
    inD3 <= outC3 when ( ctrl_dec=S_ENC ) else outA3; pinD3 <= poutC3 when ( ctrl_dec=S_ENC ) else poutA3;
    inst_row3 : aes_pt_row3 port map(
        inA3, inB3, inC3, inD3, inH3, pinA3, pinB3, pinC3, pinD3, pinH3,
        kA3, kB3, kC3, kD3, pkA3, pkB3, pkC3, pkD3,
        mixA0, mixA1, mixA2, mixB0, mixB1, mixB2, mixC0, mixC1, mixC2, mixD0, mixD1, mixD2,
            pmixA0, pmixA1, pmixA2, pmixB0, pmixB1, pmixB2, pmixC0, pmixC1, pmixC2, pmixD0, pmixD1, pmixD2,
        ctrl_in, ctrl_key, ctrl_dec, ctrl_mix, clock, reset, broken3,
        mixA3, mixB3, mixC3, mixD3, pmixA3, pmixB3, pmixC3, pmixD3,
        outA3, outB3, outC3, outD3, outH3, poutA3, poutB3, poutC3, poutD3, poutH3   ) ;
    ------------------------------------------------------------------------------------------------------
    outH <= outH0 & outH1 & outH2 & outH3;
    poutH <= poutH0 & poutH1 & poutH2 & poutH3;
    broken <= broken0 & broken1 & broken2 & broken3;
    end arch;
