
library IEEE;
    use IEEE.std_logic_1164.all;
library WORK;
    use WORK.aes_pt_params.all;

entity aes_pt_datacell3 is port(
    in_v, in_h : std_logic_vector (7 downto 0);             -- main inputs
        p_in_v, p_in_h : std_logic;
    in_0, in_1, in_2 : in std_logic_vector (7 downto 0);    -- mixc inputs
        p_in_0, p_in_1, p_in_2 : in std_logic;
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
    end aes_pt_datacell3;

architecture a_datacell3 of aes_pt_datacell3 is
--    /----*     /----*     INH-*     /----*
--   -|    *-----|    *------   *-----|    *----ST
--    \-XK-*     \-MC-*      \--*     \-XK-*
--         CK'     ED CM        CI         CK'
    component aes_pt_mixcolumn3 port (
        in_0, in_1, in_2, in_3 : in std_logic_vector (7 downto 0);
        pin0, pin1, pin2, pin3 : in std_logic;
        ctrl_dec : in T_ENCDEC;
        b_out : out std_logic_vector (7 downto 0);
        pout : out std_logic ) ;
        end component;
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
    signal mc_layer_in, mc_out, mc_layer_out, in_selection,
                state_in, state_out : std_logic_vector( 7 downto 0 );
        signal p_mc_layer_in, p_mc_out, p_mc_layer_out, p_in_selection,
                p_state_in, P_state_out : std_logic;
begin
    mc_layer_in <= in_v when ( ctrl_dec = S_ENC ) else ( in_v xor key );
        p_mc_layer_in <= p_in_v when ( ctrl_dec = S_ENC ) else ( p_in_v xor p_key );
    mix_out <= mc_layer_in;
        p_mix_out <= p_mc_layer_in;
    mc : aes_pt_mixcolumn3 port map( in_0, in_1, in_2, mc_layer_in,
                            p_in_0, p_in_1, p_in_2, p_mc_layer_in,
                            ctrl_dec,
                            mc_out, p_mc_out );
    mc_layer_out <= mc_out when ( ctrl_mix = S_MIX ) else mc_layer_in;
        p_mc_layer_out <= p_mc_out when ( ctrl_mix = S_MIX ) else p_mc_layer_in;
    in_selection <= in_h when ( ctrl_in = S_H_IN ) else mc_layer_out;
        p_in_selection <= p_in_h when ( ctrl_in = S_H_IN ) else p_mc_layer_out;
    state_in <= in_selection when ( ctrl_key = S_NOKEY ) else
                ( in_selection xor key );
        p_state_in <= p_in_selection when ( ctrl_key = S_NOKEY ) else
                ( p_in_selection xor p_key );

    state : reg generic map( 8 ) port map( clock, reset, state_in, state_out );
	 pstate : regbit port map( clock, reset, p_state_in, p_state_out );

    b_out <= state_out;
        p_b_out <= p_state_out;
    error <= state_out(7) xor state_out(6) xor state_out(5) xor state_out(4) xor state_out(3) xor
            state_out(2) xor state_out(1) xor state_out(0) xor p_state_out;
    end a_datacell3;
