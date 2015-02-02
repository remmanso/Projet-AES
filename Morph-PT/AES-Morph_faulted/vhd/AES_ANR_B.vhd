library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;
library WORK;
  use WORK.params.all;

entity AES_ANR_B is 
	port (
    -- Inputs :
    CLK         : in std_logic;
    RESETN      : in std_logic;
    KEY         : in std_logic_vector( 127 downto 0 ); 
    DIN         : in std_logic_vector( 127 downto 0 ); 
    E_D         : in std_logic;
    START       : in std_logic;
    CONFIGREG   : in std_logic_vector( 15 downto 0 ); -- Static setting at chip reset
    SPAREIN     : in std_logic_vector( 2 downto 0 ); -- Dynamic settings
    TST_SCANEN  : in std_logic;
    TST_SCANIN  : in std_logic_vector( 5 downto 0 ); 
    -- Outputs :
    DOUT        : out std_logic_vector( 127 downto 0 ); 
    BUSY        : out std_logic;
    SPAREOUT    : out std_logic_vector( 5 downto 0 ); 
    TST_SCANOUT : out std_logic_vector( 5 downto 0 )
		); 
	end AES_ANR_B;

  
architecture arch of AES_ANR_B is
  constant C_LASER_500NS : std_logic := '0';
	constant C_LASER_200US : std_logic := '1';
  component aes_core  
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
      error_detector : out std_logic;
      ready_out : out std_logic -- 1 = AVAILABLE, 0 = BUSY
      ); -- rst active LOW, see aes_globals.vhd
    end component;
  type T_state is ( RESET_ST, IDLE, 
                    WAIT11, WAIT12, WAIT13, 
										INIT_RNDMS, WAIT_RNDMS, 
                    SEND_KEY, WAIT_KEY_LOAD, WAIT_SYNC,
										SEND_PTX, SEND_PTX_K, 
										WAIT1, WAIT2, WAIT3, WAIT_RES, GET_RESULT );
	signal ed_r, start_r : std_logic;
	signal spare_r : std_logic_vector( 2 downto 0 ); 
	signal fsm_state : T_state;
  signal s_sel_laser : std_logic; -- 0 = 500ns, 1 = 200µs
  signal cmd_enable_fullred, cmd_enable_partialred : std_logic;
  signal s_enable_fullred, s_enable_partialred : std_logic;
  signal init_countermeasures, countermeasure_initialized : std_logic;
  signal config_cntrmsr : std_logic_vector( 4 downto 0 ); 
  signal dout_reg : std_logic_vector( 127 downto 0 ); 
  signal dout_ok, s_aes_busy, s_sync : std_logic;
	signal cmd_do_mult_encr, multiple_encr : std_logic;
  signal s_aes_error : std_logic;
  signal sync_counter : integer range 0 to 25000;
  signal s_aes_load_key, s_aes_start, s_local_rst : std_logic;
  signal s_aes_din, aes_core_data_outH : std_logic_vector( 127 downto 0 ); 
  signal s_rnd_cmds : std_logic_vector( 5 downto 0 ); 
  signal aes_data_out_ok : std_logic; 
  signal aes_core_ready_out : std_logic;
  signal aes_core_error : std_logic;
  signal s_error_detector : std_logic;
begin
  s_sel_laser <= CONFIGREG( 0 );
  init_countermeasures <= spare_r( 2 ); -- SPAREIN( 2 ); 
  config_cntrmsr <= CONFIGREG( 5 downto 1 );
	cmd_do_mult_encr <= ed_r; -- E_D;
  cmd_enable_fullred <= spare_r( 1 ); -- SPAREIN( 1 );
  cmd_enable_partialred <= spare_r( 0 ); -- SPAREIN( 0 );
	
	process( CLK )
	begin
		if ( CLK'event and CLK='1' ) then
			ed_r <= E_D;
			start_r <= START;
			spare_r <= SPAREIN;
			end if;
		end process;

	-- FSM and command definition: ----------------------------------------------
	FSM_PROC : process( CLK )
	begin
		if ( CLK'event and CLK='1' ) then
			if ( RESETN='0' ) then
				fsm_state <= RESET_ST;
        s_rnd_cmds <= ( others => '0' );
        multiple_encr <= '0';
        s_enable_fullred <= '0';
        s_enable_partialred <= '0';
			else
				case ( fsm_state ) is
					when RESET_ST 			=> if ( init_countermeasures='1' ) then fsm_state <= INIT_RNDMS; end if;
					when INIT_RNDMS     => s_rnd_cmds <= '1' & config_cntrmsr;
                                 fsm_state <= WAIT11;
					when WAIT11					=> s_rnd_cmds <= ( others => '0' ); 
																 fsm_state <= WAIT12;
					when WAIT12					=> fsm_state <= WAIT13;
					when WAIT13					=> fsm_state <= WAIT_RNDMS;
					when WAIT_RNDMS     => if ( s_aes_busy='0' ) then fsm_state <= IDLE; end if;
					when IDLE 					=> if ( start_r='1' ) then -- START
                                    fsm_state <= SEND_KEY; 
                                    multiple_encr <= cmd_do_mult_encr;
                                    if ( cmd_enable_fullred='1' ) then
                                      s_enable_fullred <= '1';
                                      s_enable_partialred <= '0';
                                    elsif ( cmd_enable_partialred='1' ) then
                                      s_enable_fullred <= '0';
                                      s_enable_partialred <= '1';
                                    else 
                                      s_enable_fullred <= '0';
                                      s_enable_partialred <= '0';
                                      end if;
                                    end if;
																 s_rnd_cmds <= ( others => '0' );
          when SEND_KEY 			=> fsm_state <= WAIT_KEY_LOAD;
					when WAIT_KEY_LOAD 	=> if ( s_aes_busy='0' ) then fsm_state <= WAIT_SYNC; end if;
					when WAIT_SYNC      => if ( sync_counter = 0 ) then 
					                         if ( multiple_encr='1' ) then 
																	 	 fsm_state <= SEND_PTX_K; 
																	 else 
																	 	 fsm_state <= SEND_PTX; 
																		 end if; -- mult_encr
																	 end if;
          when SEND_PTX_K		  => fsm_state <= SEND_PTX; 
          when SEND_PTX       => fsm_state <= WAIT1; 
					when WAIT1          => fsm_state <= WAIT2;
					when WAIT2          => fsm_state <= WAIT3;
					when WAIT3          => fsm_state <= WAIT_RES;
					when WAIT_RES 			=> if ( s_aes_busy='0' ) then fsm_state <= GET_RESULT; end if;
					when GET_RESULT  	  => fsm_state <= IDLE; 
					when others 				=> null;
					end case;
				end if; -- RESETN
			end if; -- CLK
		end process FSM_PROC;
  SYNC_PROC : process( CLK )
  begin
    if ( clk'event and clk='1' ) then
			if ( RESETN='0' ) then
				s_sync <= '0';
				sync_counter <= 0;
      elsif ( fsm_state = SEND_KEY ) then
				s_sync <= '0';
        if ( s_sel_laser = C_LASER_500NS ) then -- 500 ns
          sync_counter <= 50;
        else -- C_LASER_200US
          sync_counter <= 25000;
          end if; -- s_sel_laser
      elsif ( sync_counter>0 ) then
				s_sync <= '1';
        sync_counter <= sync_counter - 1;
			else 
				s_sync <= '0';
        end if; -- ( fsm_state = SEND_KEY ), ( sync_counter>0 )
      end if; -- clk
    end process SYNC_PROC;

  s_aes_load_key <= '1' when ( fsm_state=SEND_KEY ) else '0';
	s_aes_start <= '1' when ( fsm_state=SEND_PTX or fsm_state=SEND_PTX_K ) else '0';
	s_local_rst <= '0' when ( fsm_state=RESET_ST ) else '1'; 
  s_aes_din <= KEY when ( fsm_state=SEND_PTX_K ) else DIN;

  AES_INST : aes_core generic map( 4, 2 )
                      port map( 
                        clk => CLK,
                        rst => s_local_rst,
                        start_cipher => s_aes_start,
                        load_key => s_aes_load_key,
                        data_in => s_aes_din,
                        input_key => KEY,
                        
                        rndms_in => s_rnd_cmds,
                        enable_full_red => s_enable_fullred,
                        enable_partial_red => s_enable_partialred,
                        
                        data_out => aes_core_data_outH,
                        data_out_ok => aes_data_out_ok,
                        error_out => aes_core_error,
                        error_detector => s_error_detector,
                        ready_out => aes_core_ready_out -- 1 = AVAILABLE, 0 = BUSY
                        );
  
  -- OUTPUT COLLECTION --------------------------------------------------------
  dout_ok <= aes_data_out_ok;
  s_aes_busy  <= ( not aes_core_ready_out );
  s_aes_error <= aes_core_error;
  DOUT_REG_PROC : process( CLK )
  begin
    if ( CLK'event and CLK='1' ) then
      if ( RESETN = '0' ) then 
        dout_reg <= ( others=>'0' );
      elsif ( dout_ok = '1' ) then
        dout_reg <= aes_core_data_outH;
        end if; -- RESETN, dout_ok
      end if; -- CLK
    end process DOUT_REG_PROC;
  DOUT        <= dout_reg;
  BUSY        <= s_aes_busy;
  SPAREOUT    <= "0000" & s_aes_error & s_sync;

  end architecture arch;
