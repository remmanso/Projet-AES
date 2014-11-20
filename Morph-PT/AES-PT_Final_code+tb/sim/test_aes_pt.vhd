-- Library Declaration
library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;
--library WORK;
--  use WORK.globals.all;

-- Component Declaration
entity test_pt is 
    end test_pt;
    
--constant C_ERROR_SIGNAL_WIDTH : integer := 2;

-- Architecture of the Component
architecture a_tb of test_pt is
  component aes_parity is port (
    data_inH : in std_logic_vector( 31 downto 0 );
    input_key : in std_logic_vector( 127 downto 0 );
    go_cipher, go_key, enc_command : in std_logic;
    data_outH : out std_logic_vector( 31 downto 0 );
    data_out_ok : out std_logic;
    ready_out : out std_logic;
    error_out : out std_logic_vector( 3 downto 0 );
    rst, ck : in std_logic   ); 
    end component; 
  signal datain : std_logic_vector( 31 downto 0 );
  signal data, edata, edata1, edata2, ddata, ddata1, ddata2, kdata1, kdata2 : std_logic_vector( 127 downto 0 );
  signal input_key : std_logic_vector(127 downto 0);
  signal s_broken: std_logic_vector( 3 downto 0 ); -- C_ERROR_SIGNAL_WIDTH
  signal seltest : integer;
	signal enc_cmd : std_logic;
  signal rst, ck, s_ready, s_d_ok : std_logic;
  signal dout : std_logic_vector ( 31 downto 0 );
  signal s_go_crypt, s_go_key : std_logic;
  constant RESET_ACTIVE : std_logic := '0';
  constant CLK_HT : time := 10 ns;
	constant CKT : time := 2*CLK_HT;
	constant GO_ENC : std_logic := '0';
	constant GO_DEC : std_logic := '1';
begin
  seltest <= 1;
	enc_cmd <= GO_ENC;

  rst <= not( RESET_ACTIVE ), RESET_ACTIVE after 20*CKT, not( RESET_ACTIVE ) after 24*CKT;
  clk_pr : process
  begin   
    ck <= '1';
    loop
      wait for CLK_HT;
      ck <= not ck;
      end loop;
    end process;

  edata1 <= X"3243f6a8885a308d313198a2e0370734";  edata2 <= X"00112233445566778899aabbccddeeff";
  kdata1 <= X"2b7e151628aed2a6abf7158809cf4f3c";  kdata2 <= X"000102030405060708090a0b0c0d0e0f";
  ddata1 <= X"3925841d02dc09fbdc118597196a0b32";  ddata2 <= X"69c4e0d86a7b0430d8cdb78070b4c55a";
  edata  <= edata1 when ( seltest=1 ) else edata2;
  ddata  <= ddata1 when ( seltest=1 ) else ddata2;
  input_key <= kdata1 when ( seltest=1 ) else kdata2;
  data <= edata when ( enc_cmd=GO_ENC ) else ddata;

  s_go_key <= '0', '1' after 58*CLK_HT, '0' after 60*CLK_HT;
  datain <= ( others=>'0' ), 
						data( 127 downto 96 ) after 128*CLK_HT, 
						data(  95 downto 64 ) after 130*CLK_HT, 
						data(  63 downto 32 ) after 132*CLK_HT, 
						data(  31 downto  0 ) after 134*CLK_HT, 
            ( others=>'0' ) after 136*CLK_HT, 
      			data( 127 downto 96 ) after 280*CLK_HT, 
						data(  95 downto 64 ) after 282*CLK_HT,
      			data(  63 downto 32 ) after 284*CLK_HT, 
						data(  31 downto  0 ) after 286*CLK_HT, 
            ( others=>'0' ) after 288*CLK_HT; 
  s_go_crypt <= '0', '1' after 128*CLK_HT, '0' after 130*CLK_HT, 
                     '1' after 280*CLK_HT, '0' after 282*CLK_HT;
  
  UUT : aes_parity port map(
    data_inH => datain,
    input_key => input_key,
    go_cipher => s_go_crypt, 
    go_key => s_go_key, 
    enc_command => enc_cmd, 
    data_outH => dout, 
    data_out_ok => s_d_ok, 
    ready_out => s_ready, 
    error_out => s_broken,
    rst => rst, 
    ck => ck );
  end a_tb;
