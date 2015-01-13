-- Library Declaration
library IEEE;
	use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;

--library WORK;
-- use  WORK.globals.all;
library lib_aes_core;

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
	component aes_core is 
--		generic ( 
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

			data_out : out std_logic_vector( 127 downto 0 ); 
			data_out_ok : out std_logic; 
      error_out : out std_logic; 
			ready_out : out std_logic -- 1 = AVAILABLE, 0 = BUSY
			); -- rst active LOW, see aes_globals.vhd
    	end component;
	signal enc_datain, dec_datain, datain, keyin : std_logic_vector( 127 downto 0 );
	signal edata, edata1, edata2, ddata, ddata1, ddata2, eddata, kdata1, kdata2 : std_logic_vector( 127 downto 0 );
	signal input_key : std_logic_vector(127 downto 0);
	-- signal key_size_in : std_logic_vector( 1 downto 0 );
	signal goe, god, goc, go_k, enc_command: std_logic;
	signal data_outH : std_logic_vector( 127 downto 0 );
	signal data_out_ok, error_out : std_logic;
	signal rdy : std_logic;
	signal seed, test_seed : std_logic_vector( 5 downto 0 );
	signal rst, ck, ck2x : std_logic;
	signal seltest : integer;
	signal deb_bus_ctrls : std_logic_vector( NUMBER_OF_ROUNDS*(NUMBER_OF_ROUNDS+2)-1 downto 0 ); 
	signal c_enable_full_red, c_enable_partial_red : std_logic;
	signal s_enable_fault : std_logic;
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

	edata1 <= X"3243f6a8885a308d313198a2e0370734";
	ddata1 <= X"3925841d02dc09fbdc118597196a0b32";
	kdata1 <= X"2b7e151628aed2a6abf7158809cf4f3c";
	edata2 <= X"00112233445566778899aabbccddeeff";
	kdata2 <= X"000102030405060708090a0b0c0d0e0f";
	eddata <= ddata1; -- X"0b6672b58a863976ed201d35f95d0c06";
	seltest <= 1;
	edata  <= edata1 when ( seltest=1 ) else edata2;
	input_key <= kdata1 when ( seltest=1 ) else kdata2;

	-- bus noise / blk_reloc / col_reloc / dyn mapping / linear mask

	DATA_PROC : process
	begin
		-- INIT ( & RESET )
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
	-- PARTIAL RED
    -- SEND PTX
    	c_enable_partial_red <= '1';
    	c_enable_full_red <= '0';
		goe <=  '1';
		enc_datain <= edata; wait for ckt;
		goe <=  '0';
		enc_datain <= ( others=>'0' );	
		wait for ckt;
		wait until rdy='1';
		wait for 10*ckt;
		-- SEND PTX
		goe <=  '1';
		enc_datain <= edata; wait for ckt;
		goe <=  '0';
		enc_datain <= ( others=>'0' );	
		wait for 32 * ckt;
		s_enable_fault <= '1';
		wait for ckt;
		s_enable_fault <= '0';
		wait until rdy='1';
		wait for 10*ckt;
		-- SEND PTX
		goe <=  '1';
		enc_datain <= edata2; wait for ckt;
		goe <=  '0';
		enc_datain <= ( others=>'0' );	
		wait for ckt;
		wait until rdy='1';
		wait for 10*ckt;
		-- SEND PTXs
		goe <= '1';
		enc_datain <= edata1; wait for ckt;
		enc_datain <= edata2; wait for ckt;
		goe <= '0';
		enc_datain <= ( others=>'0' );	
		wait for ckt;
		wait until rdy='1';
		wait for 10*ckt;
		-- SEND PTXs
		goe <= '1';
		enc_datain <= edata1; wait for ckt;
		enc_datain <= ddata1; wait for ckt;
		enc_datain <= edata2; wait for ckt;
		goe <= '0';
		enc_datain <= ( others=>'0' );	
		wait for ckt;
		wait until rdy='1';
		wait for 10*ckt;
		-- SEND PTXs
		goe <= '1';
		enc_datain <= edata1; wait for ckt;
		enc_datain <= kdata2; wait for ckt;
		enc_datain <= ddata1; wait for ckt;
		enc_datain <= edata2; wait for ckt;
		goe <= '0';
		enc_datain <= ( others=>'0' );	
		wait for ckt;
		wait until rdy='1';
		wait for 10*ckt;


	-- FULL RED
    -- SEND PTX
    	c_enable_partial_red <= '0';
    	c_enable_full_red <= '1';
		goe <=  '1';
		enc_datain <= edata; wait for ckt;
		goe <=  '0';
		enc_datain <= ( others=>'0' );	
		wait for 25 * ckt;
		s_enable_fault <= '1';
		wait for 1 * ckt;
		s_enable_fault <= '0';
		wait until rdy='1';
		wait for 10*ckt;
		-- SEND PTX
		goe <=  '1';
		enc_datain <= edata; wait for ckt;
		goe <=  '0';
		enc_datain <= ( others=>'0' );	
		wait for 45 * ckt;
		s_enable_fault <= '1';
		wait for ckt;
		s_enable_fault <= '0';
		wait until rdy='1';
		wait for 10*ckt;
		-- SEND PTX
		goe <=  '1';
		enc_datain <= edata2; wait for ckt;
		goe <=  '0';
		enc_datain <= ( others=>'0' );	
		wait for 32 * ckt;
		s_enable_fault <= '1';
		wait for 1 * ckt;
		s_enable_fault <= '0';
		wait until rdy='1';
		wait for 10*ckt;
		-- SEND PTXs
		goe <= '1';
		enc_datain <= edata1; wait for ckt;
		enc_datain <= edata2; wait for ckt;
		goe <= '0';
		enc_datain <= ( others=>'0' );	
		wait for 22 * ckt;
		s_enable_fault <= '1';
		wait for 1 * ckt;
		s_enable_fault <= '0';
		wait until rdy='1';
		wait for 10*ckt;
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
			data_out => data_outH,
			data_out_ok => data_out_ok, 
      error_out => error_out,
			ready_out => rdy 
			);

end exp;

