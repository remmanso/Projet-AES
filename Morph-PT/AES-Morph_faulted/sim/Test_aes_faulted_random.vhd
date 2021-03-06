-- Library Declaration
library IEEE;
	use IEEE.std_logic_1164.all;
	use IEEE.numeric_std.all;
	use STD.textio.all;

--library WORK;
-- use  WORK.globals.all;
library lib_aes_core;
	use lib_aes_core.all;

-- Component Declaration
entity A_test_aes_core_faulted is

   end A_test_aes_core_faulted;
 

-- Architecture of the Component
architecture exp of A_test_aes_core_faulted is
	constant ckht : time := 5 ns;
	constant ckt : time := 2*ckht;
	constant RESET_ACTIVE : std_logic := '0';
	constant NUMBER_OF_ROUNDS_INSTANCES : integer := 4;
	constant BLK_IDX_SZ : integer :=  2; -- LOG2( NUMBER_OF_ROUNDS_INSTANCES )
	constant NUMBER_OF_ROUNDS : integer := NUMBER_OF_ROUNDS_INSTANCES;
	component aes_core 
--	generic ( 
--			NUMBER_OF_ROUNDS : integer := NUMBER_OF_ROUNDS_INSTANCES;
--			LOG2_NUM_OF_ROUNDS : integer := BLK_IDX_SZ			);
		port (
			clk, rst : in std_logic;
			start_cipher, load_key : in std_logic; -- active HIGH 
			enable_fault : in std_logic;
			data_in : in std_logic_vector( 127 downto 0 ); 
			input_key : in std_logic_vector( 127 downto 0 ); 
			-- enc_mode : in std_logic; -- 0 = ENCRYPTION, 1 = DECRYPTION

			rndms_in : in std_logic_vector( 5 downto 0 ); -- bus noise / blk_reloc / col_reloc / dyn mapping / linear mask
			enable_full_red : in std_logic; 
			enable_partial_red : in std_logic; 
			enable_detect_code : in std_logic;

			data_out : out std_logic_vector( 127 downto 0 ); 
			data_out_ok : out std_logic; 
      error_out : out std_logic; 
      error_detector : out std_logic;
			ready_out : out std_logic -- 1 = AVAILABLE, 0 = BUSY
			); -- rst active LOW, see aes_globals.vhd
    	end component;
	signal enc_datain, dec_datain, datain, keyin : std_logic_vector( 127 downto 0 );
	signal edata, edata1, edata2, ddata, ddata1, ddata2, eddata, kdata1, kdata2 : std_logic_vector( 127 downto 0 );
	signal input_key : std_logic_vector(127 downto 0);
	-- signal key_size_in : std_logic_vector( 1 downto 0 );
	signal goe, god, goc, go_k, enc_command: std_logic;
	signal data_outH : std_logic_vector( 127 downto 0 );
	signal data_out_ok, error_out, error_detector : std_logic;
	signal rdy : std_logic;
	signal seed, test_seed : std_logic_vector( 5 downto 0 );
	signal rst, ck, ck2x : std_logic;
	signal seltest : integer;
	signal deb_bus_ctrls : std_logic_vector( NUMBER_OF_ROUNDS*(NUMBER_OF_ROUNDS+2)-1 downto 0 ); 
	signal c_enable_full_red, c_enable_partial_red : std_logic;
	signal s_enable_fault : std_logic;
	signal s_enable_detect_code : std_logic;
	signal xn, a, c : integer;
	signal cpt : integer;
begin
	rst<= not( RESET_ACTIVE ), 
      	RESET_ACTIVE after 15*ckt, 
				not( RESET_ACTIVE ) after 18*ckt; 

	clk_pr : process
	begin   
  	ck <= '1';
  	loop
    	wait for ckht;
    	ck <= not ck;
    	end loop;
  	end process;

  	a <= 1140671485 ;
  	c <= 12820163;

  	random_generator : process (ck, rst)
  	begin
  		if (ck = '1' and ck'event) then
  			if (rst = '0') then
  				xn <= 3;
  			else
  				xn <= (a * xn + c) mod (16777216);
  				cpt <= xn mod 73;
  			end if;
  		end if;
  	end process;

	edata1 <= X"3243f6a8885a308d313198a2e0370734";
	ddata1 <= X"3925841d02dc09fbdc118597196a0b32";
	kdata1 <= X"2b7e151628aed2a6abf7158809cf4f3c";
	edata2 <= X"00112233445566778899aabbccddeeff";
	kdata2 <= X"000102030405060708090a0b0c0d0e0f";
	eddata <= ddata1; -- X"0b6672b58a863976ed201d35f95d0c06";
	seltest <= 1;
	edata  <= edata1 when ( seltest=1 ) else edata2;
	input_key <= kdata1 when ( seltest=1 ) else kdata2;
	s_enable_detect_code <= '1';

	-- bus noise / blk_reloc / col_reloc / dyn mapping / linear mask

	DATA_PROC : process
	file file_pointer : text;
	variable line_num : line;
	constant line_content_ok : string(1 to 9) := "Cipher OK";
	constant line_content_nok : string(1 to 10) := "Cipher NOK";
	constant line_content_oka : string(1 to 23) := "Cipher OK FAUSSE ALARME";
	begin
		-- INIT ( & RESET )
	file_open(file_pointer,"~/Documents/Projet_AES/Morph-PT/AES-Morph_faulted/libs/results_no_detector.log",WRITE_MODE);
    keyin  <= ( others=>'0' );
		enc_datain <= ( others=>'0' );
    seed <= "000000";
		go_k <= '0';
		goe <=  '0';
		s_enable_fault <= '0';
		wait for 25*ckt;
    -- COUNTERMEASURE INIT (WITH RANDOM SEED)
    enc_datain <= edata2; 
    keyin  <= kdata2; 
    seed <= test_seed;
		wait for ckt;
		keyin  <= ( others=>'0' );
		enc_datain <= ( others=>'0' );
    seed <= "000000";
		wait for 10*ckt;
    -- WAIT PRNG INITIALIZATION
		wait until rdy='1';
		wait for 10*ckt;
		keyin  <= ( others=>'0' );
		enc_datain <= ( others=>'0' );
    seed <= "000000";
		wait for 20*ckt;
    -- LOAD KEY
		go_k <= '1';
		keyin  <= input_key; wait for ckt;
		go_k <= '0';
		keyin  <= ( others=>'0' ); 
		wait for 10*ckt;
	-- FULL RED
    -- SEND PTX
    c_enable_partial_red <= '0';
	c_enable_full_red <= '1';
    	for i in 0 to 10000 loop
			goe <=  '1';
			enc_datain <= edata; wait for ckt;
			goe <=  '0';
			enc_datain <= ( others=>'0' );	
			wait for cpt * ckt;
			s_enable_fault <= '1';
			wait for ckt;
			s_enable_fault <= '0';
			wait until data_out_ok = '1';
			if (error_out = '0' and error_detector = '0') then
				write(line_num,line_content_ok);
			elsif (error_out = '0' and error_detector = '1') then
				write(line_num,line_content_oka); 
			else
				write(line_num,line_content_nok);
      		end if;
      		writeline (file_pointer,line_num);
			wait until rdy='1';
			wait for 10*ckt;
		end loop;
		file_close(file_pointer);
	end process DATA_PROC;

	goc <= god when enc_command='1' else 
      	 goe when enc_command='0' else '0';
	-- key_size_in <= "00", "01" after 204*ckht, "00" after 206*ckht;
	enc_command <= '0'; --'X', '0' after 204*ckht, 'X' after 206*ckht,  -- 0/1 E/D
                	 --   '0' after  209*ckht, 'X' after  211*ckht; -- ENC
		                	-- '1' after 336*ckht, 'X' after 338*ckht; -- DEC
	datain <= enc_datain;

	test_seed <= "111111";
  UUT: aes_core 
		-- generic map( 4, 2 )
		port map(
			clk => ck,
			rst => rst,
			start_cipher => goc,
			load_key => go_k,
			enable_fault => s_enable_fault, 
			data_in => datain,
			input_key => keyin, -- input_key, 
			-- enc_mode => enc_command,
			rndms_in => seed, 
			enable_full_red => c_enable_full_red,
			enable_partial_red => c_enable_partial_red,
			enable_detect_code => s_enable_detect_code,
			data_out => data_outH,
			data_out_ok => data_out_ok, 
      error_out => error_out,
      error_detector => error_detector,
			ready_out => rdy 
			);

end exp;

