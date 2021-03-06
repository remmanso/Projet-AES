------------------------------------------------------
------------------------------------------------------

library IEEE;
    use IEEE.std_logic_1164.all;
library WORK;
    use WORK.aes_pt_params.all;

entity aes_pt_Row2 is port (
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
    end aes_pt_row2;

architecture arch of aes_pt_row2 is
	component reg 
		generic( SIZE : integer := 8 );
		port(
			clk, rst : in std_logic;
			din  : in std_logic_vector( SIZE-1 downto 0 );
			dout : out std_logic_vector( SIZE-1 downto 0 ) );
		end component;
	component regbit 
		port(
			clk, rst : in std_logic;
			din  : in std_logic;
			dout : out std_logic );
		end component;
    component aes_pt_sbox port (
        b_in : in std_logic_vector (7 downto 0);
        p_in : in std_logic;
        ctrl_dec : T_ENCDEC;
        clock, reset : in std_logic;
        b_out : out std_logic_vector (7 downto 0);
        p_out : out std_logic );
        end component;
    component aes_pt_datacell2 port(
        in_v, in_h : std_logic_vector (7 downto 0);
            p_in_v, p_in_h : std_logic;
        in_0, in_1, in_3 : in std_logic_vector (7 downto 0);
            p_in_0, p_in_1, p_in_3 : in std_logic;
        key : in std_logic_vector (7 downto 0);
            p_key : in std_logic;
        ctrl_in  : in T_CTRL_IN;
        ctrl_key : in T_CTRL_KEY;
        ctrl_dec : in T_ENCDEC;
        ctrl_mix : in T_CTRL_MIX;
        clock, reset    : in std_logic;
        b_out, mix_out : out std_logic_vector (7 downto 0);
            p_b_out, p_mix_out : out std_logic;
        error : out std_logic );
        end component;
    component trigger port (
        switch, clock, reset : in std_logic;
        value : out std_logic );
        end component;
    signal sbA_in, sbA_out, sbB_in, sbB_out, sbC_in, sbC_out, sbD_in, sbD_out : std_logic_vector( 7 downto 0 );
        signal psbA_in, psbA_out, psbB_in, psbB_out, psbC_in, psbC_out, psbD_in, psbD_out : std_logic;
    signal dcA_in, dcA_out, dcB_in, dcB_out, dcC_in, dcC_out, dcD_in, dcD_out : std_logic_vector( 7 downto 0 );
        signal pdcA_in, pdcA_out, pdcB_in, pdcB_out, pdcC_in, pdcC_out, pdcD_in, pdcD_out : std_logic;
    signal inAftH, inBftH, inCftH, inDftH : std_logic_vector( 7 downto 0 );
        signal pinAftH, pinBftH, pinCftH, pinDftH : std_logic;
    signal inAft0, inAft1, inAft3, inBft0, inBft1, inBft3, inCft0, inCft1, inCft3,
                inDft0, inDft1, inDft3 : std_logic_vector( 7 downto 0 );
        signal pinAft0, pinAft1, pinAft3, pinBft0, pinBft1, pinBft3, pinCft0, pinCft1, pinCft3,
                pinDft0, pinDft1, pinDft3 : std_logic;
    signal dcA_mix, dcB_mix, dcC_mix, dcD_mix : std_logic_vector( 7 downto 0 );
        signal pdcA_mix, pdcB_mix, pdcC_mix, pdcD_mix : std_logic;
    signal keyAft, keyBft, keyCft, keyDft : std_logic_vector( 7 downto 0 );
        signal pkeyAft, pkeyBft, pkeyCft, pkeyDft : std_logic;
    signal errorA, errorB, errorC, errorD : std_logic;
    signal faultA, faultB, faultC, faultD : std_logic;
begin
    sbA_in <= inA;                      psbA_in <= pinA;
    inAftH <= dcB_out;					        pinAftH <= pdcB_out;
    inAft0 <= inA0;                     pinAft0 <= pinA0;
    inAft1 <= inA1;                     pinAft1 <= pinA1;
    inAft3 <= inA3;                     pinAft3 <= pinA3;
    keyAft <= kA;                       pkeyAft <= pkA;
    SB_A : aes_pt_sbox port map( sbA_in, psbA_in, ctrl_dec, clock, reset, sbA_out, psbA_out );
	  A_reg : reg generic map( 8 ) port map( clock, reset, sbA_out, dcA_in );
	  Ap_reg : regbit port map( clock, reset, psbA_out, pdcA_in );
    DC_A : aes_pt_datacell2 port map( dcA_in, inAftH, pdcA_in, pinAftH,
                    inAft0, inAft1, inAft3, pinAft0, pinAft1, pinAft3,
                    keyAft, pkeyAft,
                    ctrl_in, ctrl_key, ctrl_dec, ctrl_mix, clock, reset,
                    dcA_out, dcA_mix, pdcA_out, pdcA_mix, errorA );
    trA : trigger port map( errorA, clock, reset, faultA );
    ----------------------------------------------------------------------------------
    sbB_in <= inB;
        psbB_in <= pinB;
    inBftH <= dcC_out;
        pinBftH <= pdcC_out;
    inBft0 <= inB0;
        pinBft0 <= pinB0;
    inBft1 <= inB1;
        pinBft1 <= pinB1;
    inBft3 <= inB3;
        pinBft3 <= pinB3;
    keyBft <= kB;
        pkeyBft <= pkB;
    SB_B : aes_pt_sbox port map( sbB_in, psbB_in, ctrl_dec, clock, reset, sbB_out, psbB_out );
	  B_reg : reg generic map( 8 ) port map( clock, reset, sbB_out, dcB_in );
	  Bp_reg : regbit port map( clock, reset, psbB_out, pdcB_in );
    DC_B : aes_pt_datacell2 port map( dcB_in, inBftH, pdcB_in, pinBftH,
                    inBft0, inBft1, inBft3, pinBft0, pinBft1, pinBft3,
                    keyBft, pkeyBft,
                    ctrl_in, ctrl_key, ctrl_dec, ctrl_mix, clock, reset,
                    dcB_out, dcB_mix, pdcB_out, pdcB_mix, errorB );
    trB : trigger port map( errorB, clock, reset, faultB );
    ----------------------------------------------------------------------------------
    sbC_in <= inC;
        psbC_in <= pinC;
    inCftH <= dcD_out;
        pinCftH <= pdcD_out;
    inCft0 <= inC0;
        pinCft0 <= pinC0;
    inCft1 <= inC1;
        pinCft1 <= pinC1;
    inCft3 <= inC3;
        pinCft3 <= pinC3;
    keyCft <= kC;
        pkeyCft <= pkC;
    SB_C : aes_pt_sbox port map( sbC_in, psbC_in, ctrl_dec, clock, reset, sbC_out, psbC_out );
	  C_reg : reg generic map( 8 ) port map( clock, reset, sbC_out, dcC_in );
	  Cp_reg : regbit port map( clock, reset, psbC_out, pdcC_in );
    DC_C : aes_pt_datacell2 port map( dcC_in, inCftH, pdcC_in, pinCftH,
                    inCft0, inCft1, inCft3, pinCft0, pinCft1, pinCft3,
                    keyCft, pkeyCft,
                    ctrl_in, ctrl_key, ctrl_dec, ctrl_mix, clock, reset,
                    dcC_out, dcC_mix, pdcC_out, pdcC_mix, errorC );
    trC : trigger port map( errorC, clock, reset, faultC );
    ----------------------------------------------------------------------------------
    sbD_in <= inD;
        psbD_in <= pinD;
    inDftH <= inH;
        pinDftH <= pinH;
    inDft0 <= inD0;
        pinDft0 <= pinD0;
    inDft1 <= inD1;
        pinDft1 <= pinD1;
    inDft3 <= inD3;
        pinDft3 <= pinD3;
    keyDft <= kD;
        pkeyDft <= pkD;
    SB_D : aes_pt_sbox port map( sbD_in, psbD_in, ctrl_dec, clock, reset, sbD_out, psbD_out );
	  D_reg : reg generic map( 8 ) port map( clock, reset, sbD_out, dcD_in );
	  Dp_reg : regbit port map( clock, reset, psbD_out, pdcD_in );
    DC_D : aes_pt_datacell2 port map( dcD_in, inDftH, pdcD_in, pinDftH,
                    inDft0, inDft1, inDft3, pinDft0, pinDft1, pinDft3,
                    keyDft, pkeyDft,
                    ctrl_in, ctrl_key, ctrl_dec, ctrl_mix, clock, reset,
                    dcD_out, dcD_mix, pdcD_out, pdcD_mix, errorD );
    trD : trigger port map( errorD, clock, reset, faultD );
    ----------------------------------------------------------------------------------
    broken <= faultA or faultB or faultC or faultD;
    outA <= dcA_out ;        poutA <= pdcA_out ;
    outB <= dcB_out ;        poutB <= pdcB_out ;
    outC <= dcC_out ;        poutC <= pdcC_out ;
    outD <= dcD_out ;        poutD <= pdcD_out ;
    mixA <= dcA_mix ;        pmixA <= pdcA_mix ;
    mixB <= dcB_mix ;        pmixB <= pdcB_mix ;
    mixC <= dcC_mix ;        pmixC <= pdcC_mix ;
    mixD <= dcD_mix ;        pmixD <= pdcD_mix ;
    outH <= dcA_out ;        poutH <= pdcA_out ;
    end arch;
