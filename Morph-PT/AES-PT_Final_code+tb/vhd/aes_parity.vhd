------------------------------------------------------
------------------------------------------------------

library IEEE;
    use IEEE.std_logic_1164.all;
library WORK;
    use WORK.aes_pt_params.all;

entity aes_parity is port (
    data_inH : in std_logic_vector( 31 downto 0 );
    input_key : in std_logic_vector( 127 downto 0 );
    go_cipher, go_key, enc_command : in std_logic;
    data_outH : out std_logic_vector( 31 downto 0 );
    data_out_ok : out std_logic;
    ready_out : out std_logic;
    error_out : out std_logic_vector( 3 downto 0 );
    rst, ck : in std_logic      );
    end aes_parity;


-- Architecture of the Component
architecture arch of aes_parity is
	component aes_pt_dataunit port (
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
		end component;
	component aes_pt_control port(
		go_crypt, go_key, encdec : in std_logic;
		ready_out : out T_READY;
		data_out_ok : out std_logic;
		ctrl_dec : out T_ENCDEC;
		ctrl_mix : out T_CTRL_MIX;
		ctrl_in : out T_CTRL_IN;
		ctrl_key : out T_CTRL_KEY;
		next_key, next_rcon : out std_logic;
		reset, clk : in std_logic
		);
		end component;
	component aes_pt_keyunit port (
		key_in : in std_logic_vector (127 downto 0);
		ctrl_dec : in T_ENCDEC;
		in_ready : in T_READY;
		load_key : in std_logic;
		store_key, next_rcon, reset, clk : in std_logic;
		key_out : out std_logic_vector (127 downto 0);
		pkey_out : out std_logic_vector (15 downto 0)  ) ;
		end component;
	signal din_r : std_logic_vector( 31 downto 0 );
	signal kin_r : std_logic_vector( 127 downto 0 );
	signal goc_r, gok_r, enc_r : std_logic;

	signal s_data_inH, s_data_outH : std_logic_vector( 31 downto 0 );
		signal pdata_inH, ps_data_inH, ps_data_outH, actual_ptH : std_logic_vector( 3 downto 0 );
	signal s_round_key : std_logic_vector( 127 downto 0 );
		signal ps_round_key : std_logic_vector( 15 downto 0 );
	signal s_data_out_ok, s_next_key, s_next_rcon : std_logic;
	signal s_broken : std_logic_vector( 3 downto 0 );
	signal sig_ready : T_READY;
	signal s_ctrl_dec : T_ENCDEC;
	signal s_ctrl_mix : T_CTRL_MIX;
	signal s_ctrl_in  : T_CTRL_IN;
	signal s_ctrl_key : T_CTRL_KEY;
begin
  in_regs : process( ck )
  begin
    if ( ck'event and ck='1' ) then
      kin_r <= input_key;
      din_r <= data_inH; 
      goc_r <= go_cipher;
      gok_r <= go_key;
      enc_r <= enc_command; 
      end if;
    end process;
--      kin_r <= input_key;
--      din_r <= data_inH; 
--      goc_r <= go_cipher;
--      gok_r <= go_key;
--      enc_r <= enc_command; 

    -- input parity generation, for data and initialization vector:
    init_pt01 : for I in 3 downto 0 generate
--        pdata_inH( I ) <= data_inH( 8*I+7 ) xor data_inH( 8*I+6 ) xor data_inH( 8*I+5 ) xor data_inH( 8*I+4 ) xor
--                            data_inH( 8*I+3 ) xor data_inH( 8*I+2 ) xor data_inH( 8*I+1 ) xor data_inH( 8*I );
        pdata_inH( I ) <= din_r( 8*I+7 ) xor din_r( 8*I+6 ) xor din_r( 8*I+5 ) xor din_r( 8*I+4 ) xor
                            din_r( 8*I+3 ) xor din_r( 8*I+2 ) xor din_r( 8*I+1 ) xor din_r( 8*I );
        end generate;

    s_data_inH <= din_r; -- data_inH;
        ps_data_inH <= pdata_inH;

    DU : aes_pt_DataUnit port map( s_data_inH, ps_data_inH, s_round_key, ps_round_key,
                            s_ctrl_in, s_ctrl_key, s_ctrl_dec, s_ctrl_mix, ck, rst,
                            s_broken,
                            s_data_outH, ps_data_outH );
    CU : aes_pt_control port map( -- go_cipher, go_key, enc_command, 
                            goc_r, gok_r, enc_r,
														sig_ready, s_data_out_ok,
                            s_ctrl_dec, s_ctrl_mix, s_ctrl_in, s_ctrl_key,
                            s_next_key, s_next_rcon,
                            rst, ck );
    KU : aes_pt_KeyUnit port map( kin_r, -- input_key,
                            s_ctrl_dec, sig_ready, gok_r, -- go_key, 
														s_next_key, s_next_rcon, rst, ck,
                            s_round_key, ps_round_key );

    init_pt03 : for I in 3 downto 0 generate
        actual_ptH( I ) <= s_data_outH( 8*I+7 ) xor s_data_outH( 8*I+6 ) xor s_data_outH( 8*I+5 ) xor s_data_outH( 8*I+4 ) xor
                            s_data_outH( 8*I+3 ) xor s_data_outH( 8*I+2 ) xor s_data_outH( 8*I+1 ) xor s_data_outH( 8*I );
        end generate;
		data_outH <= s_data_outH when ( s_data_out_ok='1' ) else ( others=>'0' );
		data_out_ok <= s_data_out_ok;
		error_out <= s_broken; -- '1' when ( ps_data_outH=actual_ptH ) else '0';
		ready_out <= '0' when ( sig_ready=C_BUSY ) else '1';

    end arch;
