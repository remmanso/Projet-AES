-- Library Declaration
library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;
library WORK;
  use WORK.params.all;

-- Entity Declaration
entity Control is port (
	-- Input commands
	load_key, start_cipher : in std_logic;
	load_rnds, activ_rnds, valid_rnds : in std_logic;
	-- Data path management
	enable_H_inputs, enable_shuffle_cols, enable_shuffle_blks, 
  next_live_regs, enable_first_input,
	realign, freeze_bus, enable_mc, enable_mc_in, enable_key : out T_ENABLE;
	-- Key management 
  save_key, advance_key, advance_rcon, rewind_key : out T_ENABLE;
	-- Global nets	
	soft_reset : out std_logic;
	get_new_mask : out T_ENABLE;
	blk_out_index : out std_logic_vector( 1 downto 0 ); 
	-- CED 
  dfa_mode : in T_DFA_MODE;
  enable_check : out T_ENABLE;
  -- Chip outputs
	data_out_ok : out T_ENABLE;
	ready : out T_READY;
  clk, rst : in std_logic );
  end Control;

-- Architecture of the Component
architecture arch of Control is
	type T_STATE is ( RESET, IDLE, WAITING_DATA, 
										SOFT, PRECHARGE, 
                  	LOADING_KEY, LOADING_RNDS, LOADING_DATA, 
										ENC_VERT, ENC_HORIZ, 
                  	OUTPUT );
  signal state : T_STATE; 
	signal enc_sub_state : integer range 0 to 7;
	signal round : integer range 0 to 14;
	signal s_ready : T_READY;
	signal s_first_H_xfer, s_enable_H_inputs, s_enable_mc, s_enable_mc_in, s_enable_key : T_ENABLE;
	signal s_enable_shuffle_cols, s_enable_shuffle_blks, s_realign, s_freeze_bus : T_ENABLE;
	signal s_enable_first_input : T_ENABLE;
	signal s_save_key, s_advance_key, s_advance_rcon, s_rewind_key, s_data_out_ok : T_ENABLE;
	signal s_next_live_regs, s_enable_check : T_ENABLE;
	-- Block management 
	signal blk_load_count, blk_out_count : std_logic_vector( 2 downto 0 );
begin
	FSM_PROC : process( clk ) 
	begin
		if ( clk'event and clk='1' ) then
			if ( rst=RESET_ACTIVE ) then 
				state <= RESET;
			else
				case state is
					when RESET => 				enc_sub_state <= 0;
																if ( load_rnds='1' ) then
																	state <= LOADING_RNDS;
																	end if;
					when LOADING_RNDS => 	-- if ( activ_rnds='0' ) then
																-- 	state <= IDLE;
																-- elsif ( valid_rnds='1' ) then 
																if ( valid_rnds='1' ) then 
																	state <= IDLE;
																	end if;
					when IDLE => 					enc_sub_state <= 0;
																if ( load_rnds='1' ) then
																	state <= LOADING_RNDS;
																elsif ( load_key='1' ) then
																	state <= LOADING_KEY;
																	end if;
					when LOADING_KEY => 	state <= SOFT; 
					when SOFT        => 	state <= PRECHARGE;
					when PRECHARGE   => 	enc_sub_state <= 0;
																state <= WAITING_DATA;
					when WAITING_DATA => if ( load_rnds='1' ) then
																	state <= LOADING_RNDS;
																elsif ( load_key='1' ) then
																	state <= LOADING_KEY;
																elsif ( start_cipher='1' ) then
																	state <= LOADING_DATA;
																	end if;
					when LOADING_DATA => 	enc_sub_state <= 0;
																if ( start_cipher='0' ) then
																	state <= ENC_HORIZ; 
																	end if;
          when ENC_HORIZ => 		enc_sub_state <= 0;
                                if ( round=0 ) then
                                  state <= OUTPUT;
                                else 
                                  state <= ENC_VERT;
                                  end if; -- round
					when ENC_VERT => 			if ( enc_sub_state=5 ) then
																	enc_sub_state <= 0;
																	state <= ENC_HORIZ;
																else
																	enc_sub_state <= enc_sub_state + 1;
																	end if; -- enc_sub_state=5
					when OUTPUT => 				if ( blk_load_count=blk_out_count ) then
																	state <= SOFT; 
																	end if;
					when others => null;
					end case;
				end if; -- reset
			end if; -- clk
		end process FSM_PROC;

	ITER_PROC : process( clk )
	begin
		if ( clk'event and clk='1' ) then
			if ( state=RESET ) then 
				round <= 0;
			else
				if ( s_ready=C_BSY ) then
					if ( state=ENC_VERT and enc_sub_state=0 ) then
						round <= round-1;
						end if; -- state
				elsif ( load_key='1' or start_cipher='1' ) then -- READY
					round <= 10;
					end if; -- s_ready, load_key
				end if; -- reset
			end if; -- clk
		end process ITER_PROC;
		
	BLK_IN_CNT_PROC : process( clk )
	begin
		if ( clk'event and clk='1' ) then
			if ( state=IDLE or state=WAITING_DATA ) then 
				blk_load_count <= ( others=>'0' );
			elsif ( start_cipher='1' ) then
				blk_load_count <= std_logic_vector( unsigned( blk_load_count ) + 1 );
				end if;
			end if;
		end process BLK_IN_CNT_PROC;

	BLK_OUT_CNT_PROC : process( clk )
	begin
		if ( clk'event and clk='1' ) then
			if ( state=IDLE or state=WAITING_DATA ) then 
				blk_out_count <= ( others=>'0' );
			elsif ( state=OUTPUT ) then
				blk_out_count <= std_logic_vector( unsigned( blk_out_count ) + 1 );
				end if;
			end if;
		end process BLK_OUT_CNT_PROC;

	s_enable_H_inputs <= C_ENABLED when ( state=ENC_HORIZ or state=LOADING_DATA or state=OUTPUT or state=PRECHARGE ) else C_DISABLED;
	s_enable_first_input <= C_ENABLED when ((state = ENC_HORIZ or state=LOADING_DATA) and round = 10) else C_DISABLED; 
  s_enable_shuffle_cols <= C_ENABLED when ( state=LOADING_DATA ) or 
                                          ( state=ENC_VERT and enc_sub_state=5 ) 
                      else C_DISABLED;
	s_enable_shuffle_blks <= C_ENABLED when ( ( state=ENC_VERT and enc_sub_state=4 ) 
																				or  ( state=LOADING_DATA and start_cipher='0' ) ) 
											else C_DISABLED;

  s_next_live_regs <= C_ENABLED when ( ( state=ENC_VERT and enc_sub_state=3 ) or  ( state=LOADING_DATA and start_cipher='0' ) ) 
                  else C_DISABLED;
  s_realign <= C_ENABLED when ( state=OUTPUT ) else C_DISABLED;
	s_freeze_bus <= C_ENABLED when ( ( state=ENC_HORIZ and round=0 ) ) else C_DISABLED; 
	s_enable_mc <= C_ENABLED when ( state=ENC_HORIZ and round>0 and round<10 ) else C_DISABLED;
	s_enable_mc_in <= C_ENABLED when ( state = ENC_VERT and round > 0 and round < 10 and enc_sub_state = 5)
								else C_DISABLED;
	s_enable_key <= C_ENABLED when ( state=ENC_HORIZ ) else C_DISABLED;

	s_save_key <= C_ENABLED when ( state=LOADING_KEY ) else C_DISABLED; 
	s_advance_key  <= C_ENABLED when ( state=ENC_VERT and enc_sub_state=0 ) else C_DISABLED;
	s_advance_rcon <= C_ENABLED when ( state=ENC_VERT and enc_sub_state=0 ) else C_DISABLED;
	s_rewind_key <= C_ENABLED when ( state=OUTPUT ) else C_DISABLED;

	s_enable_check <= C_ENABLED when ( ( state=ENC_HORIZ and round<10 ) or ( state=OUTPUT and dfa_mode=FULL_RED ) ) else C_DISABLED; 
	s_ready <= C_RDY when ( state=IDLE or state=WAITING_DATA or state=LOADING_KEY ) else C_BSY;
	s_data_out_ok <= C_ENABLED when ( state=OUTPUT ) else C_DISABLED;

	-- OUTPUT CONTROLS
	enable_first_input <= s_enable_first_input;
	enable_H_inputs <= s_enable_H_inputs;
	enable_shuffle_cols <= s_enable_shuffle_cols;
	enable_shuffle_blks <= s_enable_shuffle_blks;
  next_live_regs <= s_next_live_regs;
	realign <= s_realign;
	freeze_bus <= s_freeze_bus;
	enable_mc <= s_enable_mc;
	enable_mc_in <= s_enable_mc_in;
	enable_key <= s_enable_key;

  save_key <= s_save_key;
	advance_key <= s_advance_key;
	advance_rcon <= s_advance_rcon;
	rewind_key <= s_rewind_key;
	
	get_new_mask <= C_ENABLED when ( state=ENC_VERT and enc_sub_state=0 ) 
	                            or ( state=WAITING_DATA ) --*** -- 20121129
	           else C_DISABLED; --5*
	blk_out_index <= blk_out_count( 1 downto 0 );
	enable_check <= s_enable_check;
	ready <= s_ready;
	soft_reset <= RESET_ACTIVE when ( state=SOFT or rst=RESET_ACTIVE ) else ( not RESET_ACTIVE ); -- 20130218
	data_out_ok <= s_data_out_ok;
	
	end arch;
