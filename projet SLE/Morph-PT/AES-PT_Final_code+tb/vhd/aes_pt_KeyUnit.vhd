
library IEEE;
    use IEEE.std_logic_1164.all;
library WORK;
    use WORK.aes_pt_params.all;

entity aes_pt_keyunit is port (
    key_in : in std_logic_vector (127 downto 0);
    ctrl_dec : in T_ENCDEC;
    in_ready : in T_READY;
    load_key : in std_logic;
    store_key, next_rcon, reset, clk : in std_logic;
    key_out : out std_logic_vector (127 downto 0);
    pkey_out : out std_logic_vector (15 downto 0)  ) ;
    end aes_pt_keyunit;

architecture a_keyunit of aes_pt_keyunit is
    component parity port(
        data_in : in std_logic_vector(127 downto 0);
        parity_out : out std_logic_vector(15 downto 0)     );
        end component;
    component aes_pt_rcon port (
        next_value : in std_logic;
        ctrl_dec : in T_ENCDEC;
        reset, clock : in std_logic;
        rcon_byte : out std_logic_vector (7 downto 0);
        rcon_pbit : out std_logic       );
        end component;
    component aes_pt_sbox port (
        b_in : in std_logic_vector (7 downto 0);
        p_in : in std_logic;
        ctrl_dec : T_ENCDEC;
        clock, reset : in std_logic;
        b_out : out std_logic_vector (7 downto 0);
        p_out : out std_logic );
        end component;
    signal regs_out, next_key : std_logic_vector( 127 downto 0 );
        signal pkey_in, pregs_out, pnext_key : std_logic_vector( 15 downto 0 );
    signal sbox_in, sbox_out, rcon_in, rcon_out : std_logic_vector( 31 downto 0 );
        signal psbox_in, psbox_out, prcon_in, prcon_out : std_logic_vector( 3 downto 0 );
    signal RCon_byte : std_logic_vector( 7 downto 0 );
    signal rcon_pt : std_logic;
    signal S_ENCODE : T_ENCDEC;
begin
    S_ENCODE <= S_ENC;
    parity_init : parity port map( key_in, pkey_in );
    key_reg_pr : process( reset, clk )
    begin
        if ( reset=RESET_ACTIVE ) then
            regs_out <= ( others=>'0' );
            pregs_out <= ( others=>'0' );
        elsif ( clk'event and clk='1' ) then
            if ( in_ready=C_READY ) then
                if ( load_key='1' ) then
                    regs_out <= key_in;
                    pregs_out <= pkey_in;
                    end if;
            elsif ( store_key='1' ) then
                regs_out <= next_key;
                pregs_out <= pnext_key;
                end if;
            end if;
        end process;

    key_out <= regs_out;
    pkey_out <= pregs_out;

    sbox_in <= ( regs_out( 23 downto 0 ) & regs_out( 31 downto 24 ) ) when ( ctrl_dec=S_ENC ) else
                ( next_key( 23 downto 0 ) & next_key( 31 downto 24 ) );
    psbox_in <= (   pregs_out( 2 downto 0 ) & pregs_out(3) ) when ( ctrl_dec=S_ENC ) else
                ( pnext_key( 2 downto 0 ) & pnext_key( 3 ) );
    ks0 : aes_pt_sbox port map( sbox_in(31 downto 24), psbox_in(3), S_ENCODE, clk, reset,
                        sbox_out(31 downto 24), psbox_out(3) );
    ks1 : aes_pt_sbox port map( sbox_in(23 downto 16), psbox_in(2), S_ENCODE, clk, reset,
                        sbox_out(23 downto 16), psbox_out(2) );
    ks2 : aes_pt_sbox port map( sbox_in(15 downto  8), psbox_in(1), S_ENCODE, clk, reset,
                        sbox_out(15 downto  8), psbox_out(1) );
    ks3 : aes_pt_sbox port map( sbox_in( 7 downto  0), psbox_in(0), S_ENCODE, clk, reset,
                        sbox_out( 7 downto  0), psbox_out(0) );

    Sbox_out_proc : process( clk, reset )
    begin
        if ( reset=RESET_ACTIVE ) then
            rcon_in <= ( others=>'0' );
            prcon_in <= ( others=>'0' );
        elsif ( clk'event and clk='1' ) then
            rcon_in <= sbox_out;
            prcon_in <= psbox_out;
            end if;
        end process;

    RCon_inst : aes_pt_RCon port map ( next_RCon, ctrl_dec, reset, clk, RCon_byte, rcon_pt );
    rcon_out <= rcon_in xor ( RCon_byte & X"000000");
    prcon_out <= prcon_in xor ( rcon_pt & "000" );

    next_key( 127 downto 96 ) <= regs_out( 127 downto 96 ) xor rcon_out;
        pnext_key( 15 downto 12 ) <= pregs_out( 15 downto 12 ) xor prcon_out;
    next_key(  95 downto 64 ) <= ( regs_out(  95 downto 64 ) xor next_key( 127 downto 96 ) ) when ( ctrl_dec=S_ENC ) else
                                ( regs_out(  95 downto 64 ) xor regs_out( 127 downto 96 ) );
        pnext_key( 11 downto  8 ) <= ( pregs_out( 11 downto  8 ) xor pnext_key( 15 downto 12 ) ) when ( ctrl_dec=S_ENC ) else
                                ( pregs_out( 11 downto  8 ) xor pregs_out( 15 downto 12 ) );
    next_key(  63 downto 32 ) <= ( regs_out(  63 downto 32 ) xor next_key(  95 downto 64 ) ) when ( ctrl_dec=S_ENC ) else
                                ( regs_out(  63 downto 32 ) xor regs_out(  95 downto 64 ) );
        pnext_key(  7 downto  4 ) <= ( pregs_out(  7 downto  4 ) xor pnext_key( 11 downto  8 ) ) when ( ctrl_dec=S_ENC ) else
                                ( pregs_out(  7 downto  4 ) xor pregs_out( 11 downto  8 ) );
    next_key(  31 downto  0 ) <= ( regs_out(  31 downto  0 ) xor next_key(  63 downto 32 ) ) when ( ctrl_dec=S_ENC ) else
                                ( regs_out(  31 downto  0 ) xor regs_out(  63 downto 32 ) );
        pnext_key(  3 downto  0 ) <= ( pregs_out(  3 downto  0 ) xor pnext_key(  7 downto  4 ) ) when ( ctrl_dec=S_ENC ) else
                                ( pregs_out(  3 downto  0 ) xor pregs_out(  7 downto  4 ) );
    end a_keyunit;
