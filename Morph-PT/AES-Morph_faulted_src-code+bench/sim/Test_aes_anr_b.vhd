-- Library Declaration
library IEEE;
	use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;

library lib_aes_core;
-- Component Declaration
entity Test_aes_anr_b is

   end Test_aes_anr_b;
 

-- Architecture of the Component
architecture beh of Test_aes_anr_b is
	constant ckht : time := 5 ns;
	constant ckt : time := 2*ckht;
	constant RESET_ACTIVE : std_logic := '0';
	constant NUMBER_OF_ROUNDS_INSTANCES : integer := 4;
	constant BLK_IDX_SZ : integer :=  2; -- LOG2( NUMBER_OF_ROUNDS_INSTANCES )
	constant NUMBER_OF_ROUNDS : integer := NUMBER_OF_ROUNDS_INSTANCES;
  component AES_ANR_B 
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
      TST_SCANIN  : std_logic_vector( 5 downto 0 ); 
      -- Outputs :
      DOUT        : out std_logic_vector( 127 downto 0 ); 
      BUSY        : out std_logic;
      SPAREOUT    : out std_logic_vector( 5 downto 0 ); -- Dynamic output
      TST_SCANOUT : out std_logic_vector( 5 downto 0 )
      ); 
    end component;
	constant edata1 : std_logic_vector( 127 downto 0 ) := X"3243f6a8885a308d313198a2e0370734";
  constant edata2 : std_logic_vector( 127 downto 0 ) := X"00112233445566778899aabbccddeeff";
  constant ddata1 : std_logic_vector( 127 downto 0 ) := X"3925841d02dc09fbdc118597196a0b32";
  constant ddata2 : std_logic_vector( 127 downto 0 ) := X"69c4e0d86a7b0430d8cdb78070b4c55a";
  constant kdata1 : std_logic_vector( 127 downto 0 ) := X"2b7e151628aed2a6abf7158809cf4f3c";
  constant kdata2 : std_logic_vector( 127 downto 0 ) := X"000102030405060708090a0b0c0d0e0f";
	
	signal rst, ck : std_logic;
	signal din, din_r : std_logic_vector( 127 downto 0 );
	signal kin, kin_r : std_logic_vector(127 downto 0);
  signal ed, start : std_logic;
  signal s_config, config_r : std_logic_vector(15 downto 0);
	signal sparein : std_logic_vector( 2 downto 0 );
  signal dout, dout_r : std_logic_vector( 127 downto 0 );
  signal spareout : std_logic_vector( 5 downto 0 );
  signal busy : std_logic;
begin
	rst<= not( RESET_ACTIVE ), 
      	RESET_ACTIVE after 35*ckt, 
				not( RESET_ACTIVE ) after 38*ckt; 

	clk_pr : process
	begin   
  	ck <= '1';
  	loop
    	wait for ckht;
    	ck <= not ck;
    	end loop;
  	end process;

  process( ck )
  begin
    if ( ck'event and ck='1' ) then
      din_r <= din;
      kin_r <= kin;
      config_r <= s_config;
      dout_r <= dout;
      end if;
    end process;

  UUT : AES_ANR_B port map(
      -- Inputs :
      CLK         => ck,
      RESETN      => rst,
      KEY         => kin_r,
      DIN         => din_r,
      E_D         => ed,
      START       => start,
      CONFIGREG   => config_r,
      SPAREIN     => sparein,
      TST_SCANEN  => '0',
      TST_SCANIN  => "000000",
      -- Outputs :
      DOUT        => dout,
      BUSY        => busy,
      SPAREOUT    => spareout,
      TST_SCANOUT => open
      ); 
      
  
  -- s_sel_laser <= CONFIGREG( 0 );
  -- init_countermeasures <= SPAREIN( 2 ); 
  -- config_cntrmsr <= CONFIGREG( 5 downto 1 );
	-- cmd_do_mult_encr <= E_D;
  -- cmd_enable_fullred <= SPAREIN( 1 );
  -- cmd_enable_partialred <= SPAREIN( 0 );

	DATA_PROC : process
	begin
    -- Configure Countermeasures
		s_config <= x"003e"; -- All active: 00 --11 111-
		sparein <= "000";
    kin <= ( others=>'0' );
		din <= ( others=>'0' );
		ed <= '0';
		start <= '0';
		wait for 60*ckt;
    ------------------------------
    wait for ckht;
    -- Init PRNG
		kin <= kdata1;
		din <= edata1;
		ed <= '0';
		wait for 2*ckt;
    sparein <= "100"; -- init cntrmsr 
		wait for 1*ckt;
    sparein <= "000"; 
		wait for 10*ckt;
		wait until busy='0'; -- Wait PRNG to initialise
		wait for 10*ckt;
		------------------------------
    wait for ckht;
    -- Encryption 1 PTX
		kin <= kdata1;
		din <= edata1;
		ed <= '0';
		wait for 2*ckt;
		start <= '1';
		wait for 1*ckt;
		start <= '0';
		wait for 5*ckt;
		wait until spareout(0)='0';
		wait for 5*ckt;
		wait until busy='0';
		wait for 10*ckt;
		------------------------------
		wait for ckht;
    -- Encryption 1 PTX + Full Red
		din <= ddata1;
		ed <= '0';
		wait for 2*ckt;
    sparein <= "010";
		start <= '1';
		wait for 1*ckt;
    sparein <= "000";
		start <= '0';
		wait for 5*ckt;
		wait until spareout(0)='0';
		wait for 5*ckt;
		wait until busy='0';
		wait for 10*ckt;
		------------------------------
		wait for ckht;
    -- Encryption 1 PTX + Partial Red
		din <= ddata1;
		ed <= '0';
		wait for 2*ckt;
    sparein <= "001";
		start <= '1';
		wait for 1*ckt;
    sparein <= "000";
		start <= '0';
		wait for 5*ckt;
		wait until spareout(0)='0';
		wait for 5*ckt;
		wait until busy='0';
		wait for 10*ckt;
		------------------------------
    wait for ckht;
    -- Encryption 2 PTX
		din <= edata1;
		wait for 2*ckt;
		ed <= '1';
		start <= '1';
    sparein <= "000";
		wait for 1*ckt;
		ed <= '0';
		start <= '0';
    sparein <= "000"; 
		wait for 5*ckt;
		wait until spareout(0)='0';
		wait for 5*ckt;
		wait until busy='0';
		wait for 10*ckt;
		------------------------------
    wait for ckht;
    -- Encryption 2 PTX + Full red
		din <= edata1;
		wait for 2*ckt;
		ed <= '1';
		start <= '1';
    sparein <= "010";
		wait for 1*ckt;
		ed <= '0';
		start <= '0';
    sparein <= "000"; 
		wait for 5*ckt;
		wait until spareout(0)='0';
		wait for 5*ckt;
		wait until busy='0';
		wait for 10*ckt;
		------------------------------
    wait for ckht;
    -- Encryption 2 PTX + partial red
		din <= edata1;
		wait for 2*ckt;
		ed <= '1';
		start <= '1';
    sparein <= "001";
		wait for 1*ckt;
		ed <= '0';
		start <= '0';
    sparein <= "000"; 
		wait for 5*ckt;
		wait until spareout(0)='0';
		wait for 5*ckt;
		wait until busy='0';
		wait for 10*ckt;
		------------------------------
		end process DATA_PROC;

end beh;

