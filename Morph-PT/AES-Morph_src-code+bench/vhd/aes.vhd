------------------------------------------------------
------------------------------------------------------

library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;
library WORK;
  use WORK.params.all;

entity aes_core is 
	generic ( 
		NUMBER_OF_ROUNDS : integer := NUMBER_OF_ROUNDS_INSTANCES;
		LOG2_NUM_OF_ROUNDS : integer := BLK_IDX_SZ
		);
	port (
		clk, rst : in std_logic;
		start_cipher, load_key : in std_logic; -- active HIGH 
		data_in : in std_logic_vector( DATA_SIZE-1 downto 0 ); 
		input_key : in std_logic_vector( 127 downto 0 ); 
		-- enc_mode : in std_logic; -- 0 = ENCRYPTION, 1 = DECRYPTION
    
		rndms_in : in std_logic_vector( 5 downto 0 ); 
    enable_full_red : in std_logic; 
    enable_partial_red : in std_logic; 
    
		data_out : out std_logic_vector( DATA_SIZE-1 downto 0 ); 
		data_out_ok : out std_logic; 
		error_out : out std_logic; 
		ready_out : out std_logic -- 1 = AVAILABLE, 0 = BUSY
		); -- rst active LOW, see aes_globals.vhd
	end aes_core;


-- Architecture of the Component
architecture arch of aes_core is
  component reg_B -- registre stockant un résultat sur 8 bits
    generic( G_SIZE : integer := 8 ); 
    port (
      din : in std_logic_vector (G_SIZE-1 downto 0);
      dout : out std_logic_vector (G_SIZE-1 downto 0);
      clock, reset : in std_logic );
    end component ;  
	component reg_en -- registre 128 bits avec une entrée enable
  	generic( n : integer := 128 );
  	port( 
    	clk, rst 	: in STD_LOGIC;
    	din	: in STD_LOGIC_VECTOR (n-1 downto 0);
    	en: in STD_LOGIC;
    	dout	: out STD_LOGIC_VECTOR (n-1 downto 0) );
  	end component;
	component round 
		port (
  		data_in : in std_logic_vector( BLID_HI downto 0 ); 
  		key : in std_logic_vector( 127 downto 0 ); 
  		ctrl_dec : in T_ENCDEC;
  		enable_H_inputs : in T_ENABLE;
  		enable_shuffle, realign : in T_ENABLE; 
			set_new_mask : in T_ENABLE; 
			enable_mc  : in T_ENABLE;
			enable_mc_in : in T_ENABLE;
  		enable_key : in T_ENABLE;
			col_reloc : in std_logic_vector( 1 downto 0 ); 
			dyn_sbmap : in std_logic_vector( 2 downto 0 ); 
			lin_mask  : in std_logic_vector( 31 downto 0 ); 
  		data_out : out std_logic_vector( BLK_IDX_SZ + COL_IDX_SZ + MASK_SIZE + DATA_SIZE-1 downto 0 );
  		col_reloc_out : out std_logic_vector(1 downto 0);
  		clk, rst : in std_logic );
  	end component;
  component keyunit 
		port (
  		key_in : in std_logic_vector (127 downto 0);
  		ctrl_dec : in T_ENCDEC;
  		in_ready : in T_READY;
  		store_key, next_rcon, load_key : in T_ENABLE;
  		reset, clk : in std_logic;
  		key_out : out std_logic_vector (127 downto 0) ;
  		rewind_key : in T_ENABLE;
  		save_key : in T_ENABLE );
  	end component;
	component Control 
		port (
			-- Input commands
			load_key, start_cipher : in std_logic;
			load_rnds, activ_rnds, valid_rnds : in std_logic;
			-- Data path management
			enable_H_inputs, 
			enable_shuffle_cols, enable_shuffle_blks, 
      next_live_regs, enable_first_input, 
			realign, freeze_bus,
			enable_mc, enable_mc_in, enable_key : out T_ENABLE;
			-- Key management 
  		save_key, advance_key, advance_rcon, rewind_key : out T_ENABLE;
			-- Global nets	
			soft_reset : out std_logic;
			get_new_mask : out T_ENABLE;
			blk_out_index : out std_logic_vector( LOG2_NUM_OF_ROUNDS-1 downto 0 ); 
			-- CED 
      dfa_mode : in T_DFA_MODE;
      enable_check : out T_ENABLE;
      -- Chip outputs
			data_out_ok : out T_ENABLE;
			ready : out T_READY;
  		clk, rst : in std_logic );
  	end component;
--	component Round_Reloc_Table 
--		port (
--			-- 4 Buses, 24 configs
--			rnd_line : in std_logic_vector( 4 downto 0 ); 
--			ctrl_config : out std_logic_vector( 15 downto 0 )
--  		); 
--  	end component;
	component Round_Reloc_Table 
		-- 4 Buses, 24 configs
		generic (
			MATRIX_SIZE : integer := 4;
			RANDOM_SIZE : integer := 2 -- = log2( MATRIX_SIZE ) -- to be compliant to tower_matrix
			);
		port (
		-- 4 Buses, 24 configs -- number depends on FACT( MATRIX_SIZE )
			clk, rst : in std_logic;
			start, get_new_mask : in std_logic;
			rnd_seed : in std_logic_vector( RANDOM_SIZE-1 downto 0 ); 
			is_busy : out std_logic;
			ctrl_config : out std_logic_vector( MATRIX_SIZE*MATRIX_SIZE-1 downto 0 )
		); 
		end component;
	component Tower_Matrix 
		generic (
			MATRIX_SIZE : integer := 4;
			RANDOM_SIZE : integer := LOG2_NUM_OF_ROUNDS -- = log2( MATRIX_SIZE )
			);
		port (
			clk, rst : in std_logic;
			start, get_new_mask : in std_logic;
			rnd_seed : in std_logic_vector( RANDOM_SIZE-1 downto 0 ); 
			is_busy : out std_logic;
			ctrl_config : out std_logic_vector( MATRIX_SIZE*MATRIX_SIZE-1 downto 0 )
  		); 
  		end component;
	component enable_countermeasures 
	-- blk_reloc / col_reloc / dyn mapping / linear mask
		port (
			clk, rst : in std_logic;
			load : in std_logic;
			rnds : in std_logic_vector( 5 downto 0 ); 
			key, IV : in std_logic_vector( 79 downto 0 );
      valid : out std_logic;
			rnd_mask_out : out std_logic_vector( 31 downto 0 );
			rnd_map_out : out std_logic_vector( 2 downto 0 );
			rnd_colreloc_out : out std_logic_vector( 2*NUMBER_OF_ROUNDS_INSTANCES-1 downto 0 );
			rnd_blkreloc_out : out std_logic_vector( BLK_IDX_SZ-1 downto 0 );
      rnd_dfa_select : out std_logic_vector( 1 downto 0 );
      enable_bus_noise : out T_ENABLE
			);
		end component;
	component bus_map  
		port (
			prev_bus_config : in std_logic_vector( 1 to 4 );
			transf_matrix : in std_logic_vector( 15 downto 0 );
			next_bus_config : out std_logic_vector( 1 to 4 )
			);
		end component;
	component get123  
		port (
			d_in : in std_logic_vector( 1 to 4 ); 
			first, second, third : out std_logic_vector( 1 to 4 )
			); 
		end component;
	component checker 
		port(
			clk, rst : in std_logic; 
			enc_started : in std_logic; 
			bus_1, bus_2 : in std_logic_vector( BLID_HI downto 0 ); 
			enable_check : in T_ENABLE;
			alarm : out T_ENABLE
			);
		end component;
	component detect_code
		port(
			data_in : in std_logic_vector( BLID_HI downto 0 ); 
			key : in std_logic_vector( 127 downto 0 ); 
			ctrl_dec : in T_ENCDEC;
			enable_H_inputs : in T_ENABLE;
			enable_shuffle, realign : in T_ENABLE; 
			set_new_mask : in T_ENABLE; 
			enable_mc  : in T_ENABLE;
			enable_key : in T_ENABLE;
			start_cipher : in std_logic;
			-- rnd_seed_in  : in std_logic_vector( 13 downto 0 );
			col_reloc : in std_logic_vector( BLK_IDX_SZ-1 downto 0 ); 
			dyn_sbmap : in std_logic_vector( 2 downto 0 ); 
			lin_mask  : in std_logic_vector( MASK_SIZE-1 downto 0 ); 
			data_out : out std_logic_vector( 15 downto 0 );
			clk, rst : in std_logic ;
			alarm : out T_ENABLE
			);
		end component;
  -- Input filtering
	signal start_cipher_filtered, start_cipher_delayed : std_logic;
	signal data_in_filtered : std_logic_vector( DATA_SIZE-1 downto 0 );
  -- Random signals & countermeasures
	signal s_rndms_in : std_logic_vector( 5 downto 0 );
	signal s_load_rndms, s_activ_counter : std_logic; 
	signal s_valid_random_stream : std_logic;
  signal col_reloc : std_logic_vector( NUMBER_OF_ROUNDS*COL_IDX_SZ-1 downto 0 ); 
	signal blk_reloc : std_logic_vector( BLK_IDX_SZ-1 downto 0 ); 
	signal dyn_sbmap : std_logic_vector( 2 downto 0 ); 
	signal lin_mask  : std_logic_vector( MASK_SIZE-1 downto 0 ); 
  -- Data signals
  signal s_key_reg : std_logic_vector( 127 downto 0 );
  signal s_round_key  : std_logic_vector( 127 downto 0 );
	signal data_in_reg : std_logic_vector( DATA_SIZE-1 downto 0 );
  signal masked_data_out : std_logic_vector( DATA_SIZE-1 downto 0 );
  signal mask_out : std_logic_vector( MASK_SIZE-1 downto 0 );
	-- Header signals
	signal word_header : std_logic_vector( 1 downto 0 );
	signal blk_header  : std_logic_vector( BLK_IDX_SZ-1 downto 0 );
	signal mask_header : std_logic_vector( MASK_SIZE-1 downto 0 );
	-- Bus signals
	type 	 t_data_bus is array( 1 to NUMBER_OF_ROUNDS ) of 
				 -- std_logic_vector( BLK_IDX_SZ + COL_IDX_SZ + MASK_SIZE + DATA_SIZE-1 downto 0 );
         std_logic_vector( BLID_HI downto 0 );
  signal s_data_bus, s_round_out : t_data_bus;
  	type t_signal_bi  is array(1 to NUMBER_OF_ROUNDS) of
  		std_logic_vector(1 downto 0);
  	signal t_col_reloc_out : t_signal_bi;
	type   t_bus_ctrls is array( 1 to NUMBER_OF_ROUNDS ) of std_logic_vector( 0 to NUMBER_OF_ROUNDS );
  signal bus_ctrls : t_bus_ctrls;
	signal s_ctrl_bus : std_logic_vector( NUMBER_OF_ROUNDS*NUMBER_OF_ROUNDS-1 downto 0 );
	signal bus_in : -- std_logic_vector( BLK_IDX_SZ + COL_IDX_SZ + MASK_SIZE + DATA_SIZE-1 downto 0 ); 
                  std_logic_vector( BLID_HI downto 0 ); 
  signal s_enable_bus_noise : T_ENABLE;
	-- Control signals
	signal c_soft_rst : std_logic;
	signal c_ctrl_dec : T_ENCDEC;
  signal c_enable_H_inputs, c_ctrl_key, c_ctrl_mc, c_ctrl_mc_in, s_realign, s_freeze_bus,
				 c_next_live_regs, c_shuffle_cols,  c_shuffle_blks, c_get_new_mask : T_ENABLE; 
	signal s_enable_first_input : T_ENABLE;
	signal c_save_key, c_advance_key, c_advance_rcon, c_rewind_key : T_ENABLE;
	signal c_blk_out_index : std_logic_vector( LOG2_NUM_OF_ROUNDS-1 downto 0 );
  signal c_data_out_ok, c_data_out_ok_del : T_ENABLE;
	signal c_enable_check : T_ENABLE;
  signal s_ready : T_READY;
  	-- Detector code signals
  	signal s_data_in_detec : std_logic_vector(BLID_HI downto 0);
  	signal s_data_out_detec : std_logic_vector(15 downto 0);
  	signal s_col_reloc_detec : std_logic_vector(BLK_IDX_SZ - 1 downto 0);
  	signal alarm_detect : T_ENABLE;
	-- DFA redundancy
  signal s_dfa_mode : T_DFA_MODE;
  signal dfa_select, dfa_select_filtered : std_logic_vector( 1 downto 0 );
	signal s_live_rounds_reg, s_prev_live_rounds_reg, s_next_live_rounds : std_logic_vector( 1 to NUMBER_OF_ROUNDS_INSTANCES );
	signal s_dest_src_round_reg, s_dest_round_reg_memory, s_avail_rounds : std_logic_vector( 1 to NUMBER_OF_ROUNDS_INSTANCES );
  signal s_src_round, s_src_round_reg, s_prev_src_round, s_dest_src_round : std_logic_vector( 1 to NUMBER_OF_ROUNDS_INSTANCES );
	signal s_dest_round, s_dest_round_reg, s_prev_dest_round : std_logic_vector( 1 to NUMBER_OF_ROUNDS_INSTANCES );
	signal s_1st_used, s_2nd_used, s_3rd_used : std_logic_vector( 1 to NUMBER_OF_ROUNDS_INSTANCES );
	signal s_1st_avail, s_2nd_avail, s_3rd_avail : std_logic_vector( 1 to NUMBER_OF_ROUNDS_INSTANCES );
	signal s_bus2check_1, s_bus2check_2 : std_logic_vector( BLID_HI downto 0 ); 
	signal s_alarm : T_ENABLE;
begin
	-- INPUT FILTERING ==========================================================
	START_R : reg_B generic map( G_SIZE => 1 ) 
								port map( din(0) => start_cipher, 
													dout(0) => start_cipher_filtered, 
													clock => clk, 
													reset => rst );
	DATA_R  : reg_B generic map( DATA_SIZE ) port map( data_in, data_in_filtered, clk, rst );
	-- start_cipher_filtered <= start_cipher;
	-- data_in_filtered <= data_in;

	-- RANDOM GENERATOR AND COUNTERMEASURE ACTIVATION ===========================
	-- s_rndms_in <= rndms_in; -- 20130103
  RND_R : reg_B generic map( 6 ) port map( rndms_in, s_rndms_in, clk, rst ); -- 20130103
	s_load_rndms <= s_rndms_in(5);
	process( clk )
	begin
		if ( clk'event and clk='1' ) then 
			if ( rst=RESET_ACTIVE ) then 
				s_activ_counter <= '0';
			elsif ( rndms_in(5)='1' ) then -- ( s_load_rndms='1' ) then 
				s_activ_counter <= rndms_in(4) or rndms_in(3) or rndms_in(2) or rndms_in(1) or rndms_in(0);
				end if; -- rst, load_key
			end if; -- clk
		end process;
	COUNTER_EN : enable_countermeasures port map(
							 clk => clk, 
							 rst => rst,
							 load => s_load_rndms, -- 20130103 -- rndms_in(4), -- 20120611 s_load_rndms,
							 rnds => s_rndms_in,
               key => input_key( 79 downto 0 ),
               IV => data_in( 79 downto 0 ),
							 valid => s_valid_random_stream,
							 rnd_mask_out => lin_mask,
							 rnd_map_out => dyn_sbmap,
							 rnd_colreloc_out => col_reloc, 
							 rnd_blkreloc_out => blk_reloc,
               rnd_dfa_select => dfa_select,
               enable_bus_noise => s_enable_bus_noise
               );

	-- CONTROL ==================================================================
	c_ctrl_dec <= C_ENC;
	CONTROLLER : Control port map(
			load_key => load_key, 
			start_cipher => start_cipher_filtered,
			load_rnds => s_load_rndms,
			activ_rnds => s_activ_counter,
			valid_rnds => s_valid_random_stream,
			enable_H_inputs => c_enable_H_inputs,
			enable_shuffle_cols => c_shuffle_cols, 
			enable_shuffle_blks => c_shuffle_blks, 
      next_live_regs => c_next_live_regs,
      		enable_first_input => s_enable_first_input,
			realign => s_realign,
			freeze_bus => s_freeze_bus,
			enable_mc => c_ctrl_mc, 
			enable_mc_in => c_ctrl_mc_in,

			enable_key => c_ctrl_key,
			save_key => c_save_key,
			advance_key => c_advance_key, 
			advance_rcon => c_advance_rcon, 
			rewind_key => c_rewind_key,

			soft_reset => c_soft_rst,
			get_new_mask => c_get_new_mask,
      
			dfa_mode => s_dfa_mode,
      enable_check => c_enable_check,
      
			data_out_ok => c_data_out_ok,
			blk_out_index => c_blk_out_index,
			ready => s_ready, 
			clk => clk,
			rst => rst );

	-- KEY UNIT =================================================================
	KEY_R : reg_en generic map( 128 ) 
								 port map( clk, rst, input_key, load_key, s_key_reg );

  KEY_SCHEDULE : keyunit 
		port map(
  		key_in => s_key_reg, 
  		ctrl_dec => c_ctrl_dec, 
  		in_ready => s_ready, 
			load_key => c_save_key,
  		store_key => c_advance_key, 
			next_rcon => c_advance_rcon, 
  		rewind_key => c_rewind_key, 
  		reset => rst,
			clk => clk, 
  		key_out => s_round_key,
  		save_key => c_save_key  
			);

	-- HEADER GENERATION ========================================================
	DATA_OK_REG : reg_B generic map( C_CTRL_SIGNAL_SIZE )
										port map( din   => c_data_out_ok,
															dout  => c_data_out_ok_del,
														  clock => clk, 
														  reset => rst );
	
  word_header <= "00";

	BLK_HDR_PROC : process( clk )
	begin
		if ( clk'event and clk='1' ) then
			if ( rst=RESET_ACTIVE ) then 
				blk_header <= ( others=>'1' );
			elsif ( start_cipher_filtered='1' ) then
				blk_header <= std_logic_vector( unsigned( blk_header ) + 1 );
			elsif ( c_data_out_ok=C_DISABLED and c_data_out_ok_del=C_ENABLED ) then
				blk_header <= ( others=>'1' );
				end if;
			end if;
		end process BLK_HDR_PROC;

	mask_header <= ( others=>'0' );
	
	-- INPUT LAYER
	INPUT_REG : reg_en generic map( DATA_SIZE )
										 port map( clk, rst, data_in_filtered, start_cipher_filtered, data_in_reg );
										 
	-- BUS INPUTS & ROUNDS ======================================================
	bus_in <= blk_header & word_header & mask_header & data_in_reg; 
	round_for : for I in 1 to 4 generate
		ROUND_I : round port map(
  			data_in => s_data_bus( I ), 
  			key => s_round_key,
  			ctrl_dec => c_ctrl_dec, 
  			enable_H_inputs => c_enable_H_inputs,
  			enable_shuffle => c_shuffle_cols, 
				realign => s_realign,
				set_new_mask => c_get_new_mask,
				enable_mc  => c_ctrl_mc, 
				enable_mc_in => c_ctrl_mc_in,
  			enable_key => c_ctrl_key, 
				col_reloc => col_reloc( 2*I-1 downto 2*(I-1) ),
				dyn_sbmap => dyn_sbmap,
				lin_mask  => lin_mask,
  			data_out => s_round_out( I ), 
  			col_reloc_out => t_col_reloc_out(I),
  			clk => clk, 
				rst => c_soft_rst );
		end generate round_for;

	-- CED MANAGEMENT ===========================================================
  s_dfa_mode <= FULL_RED when ( enable_full_red='1' and enable_partial_red='0' )
           else PARTIAL_RED when ( enable_full_red='0' and enable_partial_red='1' )
           else NONE;
	DFA_SEL_REG : reg_en generic map( 2 )
											 port map( clk, rst, 
																 dfa_select, Enable2to1( c_shuffle_blks ), 
																 dfa_select_filtered );
	NEXT_LIVE_MAP : bus_map port map(
			prev_bus_config => s_live_rounds_reg,
			transf_matrix => s_ctrl_bus,
			next_bus_config => s_next_live_rounds
			);
	LIVE_REG_PROC : process( clk )
		variable v_blk_reloc : std_logic_vector( 1 downto 0 ); --20121215
	begin
		if ( clk'event and clk='1' ) then
			if ( c_soft_rst=RESET_ACTIVE ) then
				s_live_rounds_reg <= ( others=>'0' );
			elsif ( start_cipher_filtered='1' and  word_header="00" ) then 
				if ( start_cipher_delayed='0' ) then
					v_blk_reloc := blk_reloc( 1 downto 0 );
					end if;
				case ( v_blk_reloc( 1 downto 0 ) ) is 
					when "00" => 	s_live_rounds_reg <= '1' & s_live_rounds_reg( 1 to 3 );
					when "01" => 	s_live_rounds_reg <= s_live_rounds_reg( 4 ) & '1' & s_live_rounds_reg( 2 to 3 );
					when "10" => 	s_live_rounds_reg <= s_live_rounds_reg( 4 ) & s_live_rounds_reg( 1 ) & '1' & s_live_rounds_reg( 3 );
					when "11" => 	s_live_rounds_reg <= s_live_rounds_reg( 4 ) & s_live_rounds_reg( 1 to 2 ) & '1';
					when others => null;
					end case;
			elsif ( c_data_out_ok=C_DISABLED and c_data_out_ok_del=C_ENABLED ) then 
				s_live_rounds_reg <= ( others=>'0' );
			elsif ( c_next_live_regs=C_ENABLED ) then 
				s_live_rounds_reg <= s_next_live_rounds;
				end if;
			end if;
		end process LIVE_REG_PROC;
  PREV_LIVE_REG : reg_en generic map( 4 ) 
												 port map( clk, rst, s_live_rounds_reg, Enable2to1( c_enable_H_inputs ),
																	 s_prev_live_rounds_reg );
  GET_USED : get123 port map( s_prev_live_rounds_reg, s_1st_used, s_2nd_used, s_3rd_used );  
  s_src_round <= s_1st_used when ( count( s_live_rounds_reg )=1 ) 
            else s_3rd_used when ( count( s_live_rounds_reg )=3 and dfa_select_filtered(1)='1' ) 
            else s_1st_used when ( dfa_select_filtered(0)='0' ) 
            else s_2nd_used; -- when ( dfa_select_filtered(0)='1' )
  s_avail_rounds <= not s_live_rounds_reg;
	GET_AVAIL : get123 port map( s_avail_rounds, s_1st_avail, s_2nd_avail, s_3rd_avail ); 
  s_dest_round <= s_1st_avail when ( count( s_live_rounds_reg )=3 )
             else s_3rd_avail when ( count( s_live_rounds_reg )=1 and dfa_select_filtered(1)='1' )
             else s_1st_avail when ( dfa_select_filtered(0)='0' )
             else s_2nd_avail; -- when ( dfa_select_filtered(0)='1' )
	NEXT_SRC_MAP : bus_map  port map(
			prev_bus_config => s_src_round,
			transf_matrix => s_ctrl_bus,
			next_bus_config => s_dest_src_round
			);
	NEXT_SRC_MAP_REG : reg_en generic map( 4 )
														port map( clk, rst, 
																			s_dest_src_round, Enable2to1( c_enable_H_inputs ), 
																			s_dest_src_round_reg );
  DEST_REG : reg_en generic map( 4 ) 
									  port map( clk, rst, 
														  s_dest_round, Enable2to1( c_enable_H_inputs ), 
														  s_dest_round_reg );

  s_bus2check_1 <= s_round_out( 1 ) when ( s_dfa_mode=PARTIAL_RED and s_dest_src_round_reg="1000" ) 
							else s_round_out( 2 ) when ( s_dfa_mode=PARTIAL_RED and s_dest_src_round_reg="0100" ) 
							else s_round_out( 3 ) when ( s_dfa_mode=PARTIAL_RED and s_dest_src_round_reg="0010" ) 
							else s_round_out( 4 ) when ( s_dfa_mode=PARTIAL_RED and s_dest_src_round_reg="0001" ) 
							else s_round_out( 1 ) when ( s_dfa_mode=FULL_RED and s_prev_live_rounds_reg( 1 )='1' 
																						and s_round_out( 1 )( BLID_HI downto BLID_LO )=c_blk_out_index )
							else s_round_out( 2 ) when ( s_dfa_mode=FULL_RED and s_prev_live_rounds_reg( 2 )='1' 
																						and s_round_out( 2 )( BLID_HI downto BLID_LO )=c_blk_out_index )
							else s_round_out( 3 ) when ( s_dfa_mode=FULL_RED and s_prev_live_rounds_reg( 3 )='1' 
																						and s_round_out( 3 )( BLID_HI downto BLID_LO )=c_blk_out_index )
							else s_round_out( 4 ) when ( s_dfa_mode=FULL_RED and s_prev_live_rounds_reg( 4 )='1' 
																						and s_round_out( 4 )( BLID_HI downto BLID_LO )=c_blk_out_index )
							else ( others=>'0' );
	s_bus2check_2 <= s_round_out( 1 ) when ( s_dfa_mode=PARTIAL_RED and s_dest_round_reg="1000" ) 
							else s_round_out( 2 ) when ( s_dfa_mode=PARTIAL_RED and s_dest_round_reg="0100" ) 
							else s_round_out( 3 ) when ( s_dfa_mode=PARTIAL_RED and s_dest_round_reg="0010" ) 
							else s_round_out( 4 ) when ( s_dfa_mode=PARTIAL_RED and s_dest_round_reg="0001" ) 
							else s_round_out( 1 ) when ( s_dfa_mode=FULL_RED and s_prev_live_rounds_reg( 1 )='0'
																						and s_round_out( 1 )( BLID_HI downto BLID_LO )=c_blk_out_index )
							else s_round_out( 2 ) when ( s_dfa_mode=FULL_RED and s_prev_live_rounds_reg( 2 )='0'
																						and s_round_out( 2 )( BLID_HI downto BLID_LO )=c_blk_out_index )
							else s_round_out( 3 ) when ( s_dfa_mode=FULL_RED and s_prev_live_rounds_reg( 3 )='0'
																						and s_round_out( 3 )( BLID_HI downto BLID_LO )=c_blk_out_index )
							else s_round_out( 4 ) when ( s_dfa_mode=FULL_RED and s_prev_live_rounds_reg( 4 )='0' -- s_avail_rounds( 4 )='1' 
																						and s_round_out( 4 )( BLID_HI downto BLID_LO )=c_blk_out_index )
							else ( others=>'0' );

  CHECKER_INST : checker port map(
			clk => clk,
			rst => rst,
			enc_started => start_cipher_filtered,
			bus_1 => s_bus2check_1, 
			bus_2 => s_bus2check_2,
			enable_check => c_enable_check,
			alarm => s_alarm
			);


  -- Detector code ==============================================================

  					
  		s_data_in_detec <= 	bus_in when (s_enable_first_input = C_ENABLED)
  					else 	s_round_out(1) when (s_dfa_mode=PARTIAL_RED and (c_enable_H_inputs = C_ENABLED or c_ctrl_mc_in = C_ENABLED) and s_dest_src_round_reg = "1000")
  					else 	s_round_out(2) when (s_dfa_mode=PARTIAL_RED and (c_enable_H_inputs = C_ENABLED or c_ctrl_mc_in = C_ENABLED) and s_dest_src_round_reg = "0100")
  					else 	s_round_out(3) when (s_dfa_mode=PARTIAL_RED and (c_enable_H_inputs = C_ENABLED or c_ctrl_mc_in = C_ENABLED) and s_dest_src_round_reg = "0010")
  					else 	s_round_out(4) when (s_dfa_mode=PARTIAL_RED and (c_enable_H_inputs = C_ENABLED or c_ctrl_mc_in = C_ENABLED) and s_dest_src_round_reg = "0001")
  					else (others => '0');

 		s_col_reloc_detec <= 	t_col_reloc_out(1) when s_dest_src_round_reg = "1000"
 				else 		t_col_reloc_out(2) when s_dest_src_round_reg = "0100"
 				else 		t_col_reloc_out(3) when s_dest_src_round_reg = "0010"
 				else 		t_col_reloc_out(4) when s_dest_src_round_reg = "0001"
 			else (others => '0');

 		--s_data_in_detec <= 	bus_in when (s_enable_first_input = C_ENABLED)
  		--			else 	s_round_out(1) when (s_dfa_mode=PARTIAL_RED and (c_enable_H_inputs = C_ENABLED or c_ctrl_mc_in = C_ENABLED) and s_dest_round_reg = "1000")
  		--			else 	s_round_out(2) when (s_dfa_mode=PARTIAL_RED and (c_enable_H_inputs = C_ENABLED or c_ctrl_mc_in = C_ENABLED) and s_dest_round_reg = "0100")
  		--			else 	s_round_out(3) when (s_dfa_mode=PARTIAL_RED and (c_enable_H_inputs = C_ENABLED or c_ctrl_mc_in = C_ENABLED) and s_dest_round_reg = "0010")
  		--			else 	s_round_out(4) when (s_dfa_mode=PARTIAL_RED and (c_enable_H_inputs = C_ENABLED or c_ctrl_mc_in = C_ENABLED) and s_dest_round_reg = "0001")
  		--			else (others => '0');
--
-- 		--s_col_reloc_detec <= 	t_col_reloc_out(1) when s_dest_round_reg = "1000"
-- 		--		else 		t_col_reloc_out(2) when s_dest_round_reg = "0100"
-- 		--		else 		t_col_reloc_out(3) when s_dest_round_reg = "0010"
-- 		--		else 		t_col_reloc_out(4) when s_dest_round_reg = "0001"
 		--	else (others => '0');

 		
 DETECTOR_CODE : detect_code port map (
  			data_in => s_data_in_detec,
			key => s_round_key,
			ctrl_dec => c_ctrl_dec,
			enable_H_inputs => c_enable_H_inputs,
			enable_shuffle => c_shuffle_cols,
			realign => s_realign,
			set_new_mask => c_get_new_mask,
			enable_mc => c_ctrl_mc,
			enable_key => c_ctrl_key,
			start_cipher => start_cipher_filtered,
			-- rnd_seed_in  : in std_logic_vector( 13 downto 0 );
			col_reloc => s_col_reloc_detec,
			dyn_sbmap => dyn_sbmap,
			lin_mask => lin_mask,
			data_out => s_data_out_detec,
			clk => clk, 
			rst => rst,
			alarm => alarm_detect
 			);
	
	-- BUS CONTROL ==============================================================
	-- Reloc_Table : Round_Reloc_Table port map( col_reloc( 4 downto 0 ), s_ctrl_bus );
	Reloc_Table : Round_Reloc_Table -- Tower_Matrix -- 
								generic map( 4, 2 ) 
								port map( 
									-- CLK2X for tower, CLK for table:
									clk => clk, -- clk => clk2x, -- 
									rst => rst, 
									start => s_valid_random_stream,
									get_new_mask => c_get_new_mask(0), 
									rnd_seed => blk_reloc, 
									is_busy => open, 
									ctrl_config => s_ctrl_bus );
	DELAYED_START_PROC : process( clk )
	begin
		if ( clk'event and clk='1' ) then
			start_cipher_delayed <= start_cipher_filtered;
			end if;
		end process DELAYED_START_PROC;
	BUS_CTRL_PROC : process( clk )
		variable v_bus_ctrls : t_bus_ctrls;
	begin
    if ( clk'event and clk='1' ) then
			if ( c_soft_rst=RESET_ACTIVE ) then
				bus_ctrls(1) <= "00000"; -- ( others=>'0' );
				bus_ctrls(2) <= "00000"; -- ( others=>'0' );
				bus_ctrls(3) <= "00000"; -- ( others=>'0' );
				bus_ctrls(4) <= "00000"; -- ( others=>'0' );
			elsif ( start_cipher_filtered='1' and start_cipher_delayed='0' ) then
        if ( s_dfa_mode=NONE or s_dfa_mode=PARTIAL_RED ) then
          case ( blk_reloc( 1 downto 0 ) ) is
            when "00" => 	bus_ctrls(1) <= "10000"; 
                          bus_ctrls(2) <= "01000";
                          bus_ctrls(3) <= "00100";
                          bus_ctrls(4) <= "00010";
            when "01" =>  bus_ctrls(1) <= "00001";
                          bus_ctrls(2) <= "10000";
                          bus_ctrls(3) <= "00100";
                          bus_ctrls(4) <= "00010";
            when "10" =>  bus_ctrls(1) <= "00001";
                          bus_ctrls(2) <= "01000";
                          bus_ctrls(3) <= "10000";
                          bus_ctrls(4) <= "00010";
            when "11" =>  bus_ctrls(1) <= "00001";
                          bus_ctrls(2) <= "01000";
                          bus_ctrls(3) <= "00100";
                          bus_ctrls(4) <= "10000";
            when others => null;
            end case;
        elsif ( s_dfa_mode=FULL_RED ) then
          case ( blk_reloc( 1 downto 0 ) ) is
            when "00" => 	bus_ctrls(1) <= "10000"; 
                          bus_ctrls(2) <= "01000";
                          bus_ctrls(3) <= "10000";
                          bus_ctrls(4) <= "00010";
            when "01" =>  bus_ctrls(1) <= "00001";
                          bus_ctrls(2) <= "10000";
                          bus_ctrls(3) <= "00100";
                          bus_ctrls(4) <= "10000";
            when "10" =>  bus_ctrls(1) <= "10000";
                          bus_ctrls(2) <= "01000";
                          bus_ctrls(3) <= "10000";
                          bus_ctrls(4) <= "00010";
            when "11" =>  bus_ctrls(1) <= "00001";
                          bus_ctrls(2) <= "10000";
                          bus_ctrls(3) <= "00100";
                          bus_ctrls(4) <= "10000";
            when others => null;
            end case;
          end if; -- s_dfa_mode
			elsif ( s_freeze_bus=C_ENABLED ) then --5
        bus_ctrls(1) <= "01000";
        bus_ctrls(2) <= "00100";
        bus_ctrls(3) <= "00010";
        bus_ctrls(4) <= "00001";
      elsif ( c_shuffle_blks=C_ENABLED ) then  -- 20121204
				bus_ctrls(1) <= '0' & s_ctrl_bus( 15 downto 12 );
				bus_ctrls(2) <= '0' & s_ctrl_bus( 11 downto  8 );
				bus_ctrls(3) <= '0' & s_ctrl_bus(  7 downto  4 );
				bus_ctrls(4) <= '0' & s_ctrl_bus(  3 downto  0 );
				end if; -- -- start_cipher_filtered, c_shuffle_blks, s_freeze_bus
      end if; -- clk
		end process BUS_CTRL_PROC;
		
	-- BUS ======================================================================
  bus_for : for I in 1 to 4 generate -- FIXME !!!
		-- ASIC BUS GENERATION
--    s_data_bus( I ) <= bus_in  when ( bus_ctrls(I)(0)='1' ) else ( others=>'Z' );
--    s_data_bus( I ) <= s_round_out( 1 ) when ( bus_ctrls(I)(1)='1' ) else ( others=>'Z' );
--    s_data_bus( I ) <= s_round_out( 2 ) when ( bus_ctrls(I)(2)='1' ) else ( others=>'Z' );
--    s_data_bus( I ) <= s_round_out( 3 ) when ( bus_ctrls(I)(3)='1' ) else ( others=>'Z' );
--    s_data_bus( I ) <= s_round_out( 4 ) when ( bus_ctrls(I)(4)='1' ) else ( others=>'Z' );
--    s_data_bus( I ) <= x"F00000000" & lin_mask when ( bus_ctrls(I)(5)='1' ) else ( others=>'Z' );
    -- FPGA BUS GENERATION
		s_data_bus( I ) <= bus_in  					when ( c_enable_H_inputs=C_ENABLED and ( bus_ctrls(I)(0)='1' ) )  -- 20130111
									else s_round_out( 1 ) when ( c_enable_H_inputs=C_ENABLED and 
                                          ( ( bus_ctrls(I)(1)='1' and ( s_prev_live_rounds_reg(1)='1' or s_dfa_mode/=PARTIAL_RED ) ) -- 20130114 
																					or ( s_dfa_mode=PARTIAL_RED and s_src_round(1)='1' and s_dest_round(I)='1' ) ) ) -- 20130111 and s_prev_live_rounds_reg(1)='1' -- 20130114b
									else s_round_out( 2 ) when ( c_enable_H_inputs=C_ENABLED and 
                                          ( ( bus_ctrls(I)(2)='1' and ( s_prev_live_rounds_reg(2)='1' or s_dfa_mode/=PARTIAL_RED ) ) -- 20130114 
																					or ( s_dfa_mode=PARTIAL_RED and s_src_round(2)='1' and s_dest_round(I)='1' ) ) ) -- 20130111 and s_prev_live_rounds_reg(2)='1' -- 20130114b
    							else s_round_out( 3 ) when ( c_enable_H_inputs=C_ENABLED and 
                                          ( ( bus_ctrls(I)(3)='1' and ( s_prev_live_rounds_reg(3)='1' or s_dfa_mode/=PARTIAL_RED ) ) -- 20130114 
																					or ( s_dfa_mode=PARTIAL_RED and s_src_round(3)='1' and s_dest_round(I)='1' ) ) ) -- 20130111 and s_prev_live_rounds_reg(3)='1' -- 20130114b
    							else s_round_out( 4 ) when ( c_enable_H_inputs=C_ENABLED and 
                                          ( ( bus_ctrls(I)(4)='1' and ( s_prev_live_rounds_reg(4)='1' or s_dfa_mode/=PARTIAL_RED ) ) -- 20130114 
																					or ( s_dfa_mode=PARTIAL_RED and s_src_round(4)='1' and s_dest_round(I)='1' ) ) ) -- 20130111 and s_prev_live_rounds_reg(4)='1' -- 20130114b
									else ( x"F00000000" & lin_mask & lin_mask & lin_mask & lin_mask ) when ( s_enable_bus_noise=C_ENABLED and s_ready=C_BSY )
                  else ( BLID_HI downto BLID_LO => '1', others=>'0' );
    end generate bus_for;

	-- OUTPUT ===================================================================
  masked_data_out <= s_data_bus( 1 )( DATA_HI downto DATA_LO ) 
              when ( s_data_bus( 1 )( BLID_HI downto BLID_LO )=c_blk_out_index and c_data_out_ok=C_ENABLED )
				else  s_data_bus( 2 )( DATA_HI downto DATA_LO ) 
							when ( s_data_bus( 2 )( BLID_HI downto BLID_LO )=c_blk_out_index and c_data_out_ok=C_ENABLED )
				else  s_data_bus( 3 )( DATA_HI downto DATA_LO ) 
							when ( s_data_bus( 3 )( BLID_HI downto BLID_LO )=c_blk_out_index and c_data_out_ok=C_ENABLED )
				else  s_data_bus( 4 )( DATA_HI downto DATA_LO ) 
							when ( s_data_bus( 4 )( BLID_HI downto BLID_LO )=c_blk_out_index and c_data_out_ok=C_ENABLED )
				else  ( others=>'0' );
  mask_out <= s_data_bus( 1 )( MASK_HI downto MASK_LO )
							when ( s_data_bus( 1 )( BLID_HI downto BLID_LO )=c_blk_out_index and c_data_out_ok=C_ENABLED )
				else  s_data_bus( 2 )( MASK_HI downto MASK_LO ) 
							when ( s_data_bus( 2 )( BLID_HI downto BLID_LO )=c_blk_out_index and c_data_out_ok=C_ENABLED )
				else  s_data_bus( 3 )( MASK_HI downto MASK_LO )
							when ( s_data_bus( 3 )( BLID_HI downto BLID_LO )=c_blk_out_index and c_data_out_ok=C_ENABLED )
				else  s_data_bus( 4 )( MASK_HI downto MASK_LO )
							when ( s_data_bus( 4 )( BLID_HI downto BLID_LO )=c_blk_out_index and c_data_out_ok=C_ENABLED )
				else  ( others=>'0' );

  data_out <= masked_data_out xor ExpandMask( mask_out );
	data_out_ok <= '1' when ( c_data_out_ok=C_ENABLED ) else '0';
	ready_out <= '1' when ( s_ready=C_RDY ) else '0';
	error_out <= '0' when ( s_alarm=C_DISABLED ) else '1';

  end arch;
