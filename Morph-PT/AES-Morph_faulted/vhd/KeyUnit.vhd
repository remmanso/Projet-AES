
-- next_key(127 downto 96) = Subword(RotWord(prev_key(32 downto 0)) XOR rcon
-- next_key(95 downto 64) = prev_key(95 downto 64) XOR next_key(127 downto 96)
-- next_key(63 downto 32) = prev_key(63 downto 32) XOR next_key(95 downto 64)
-- next_key(31 downto 0) = prev_key(31 downto 0) XOR next_key(63 downto 32)

library IEEE;
    use IEEE.std_logic_1164.all;
library WORK;
   use WORK.params.all;

entity keyunit is port (
  key_in : in std_logic_vector (127 downto 0);
  ctrl_dec : in T_ENCDEC;
  in_ready : in T_READY;
  store_key, next_rcon, load_key : in T_ENABLE;
  reset, clk : in std_logic;
  key_out : out std_logic_vector (127 downto 0) ;
  rewind_key : in T_ENABLE;
  save_key : in T_ENABLE );
  end keyunit;

architecture a_keyunit of keyunit is
	component reg_B 
  	generic( G_SIZE : integer := 8 ); 
  	port (
			clock, reset : in std_logic;
    	din : in std_logic_vector (G_SIZE-1 downto 0);
    	dout : out std_logic_vector (G_SIZE-1 downto 0)
    	);
  	end component;
	component sbox 
		port (
    	b_in : in std_logic_vector (7 downto 0);
    	ctrl_dec : T_ENCDEC;
	    clock : in std_logic;
    	b_out : out std_logic_vector (7 downto 0)   );
    end component;
  component rcon port (
    next_value : in T_ENABLE;
    ctrl_dec : in T_ENCDEC;
    reset, clock : in std_logic;
    rcon_byte : out std_logic_vector (7 downto 0);
    rewind_key: in T_ENABLE ;
    save_key : in T_ENABLE );
    end component;
  signal data_from_sbox, data_from_sbox_reg, data_to_sbox : std_logic_vector (31 downto 0);
  signal regs_out, next_key : std_logic_vector( 127 downto 0 ); -- , s_final_key
  signal rcon_in, rcon_out : std_logic_vector( 31 downto 0 );
  signal RCon_byte : std_logic_vector( 7 downto 0 );
begin    
  key_reg_pr : process( reset, clk )
  begin
    if ( clk'event and clk='1' ) then	
    	if ( reset=RESET_ACTIVE ) then  
      	regs_out <= ( others=>'0' );
      -- s_final_key <= ( others=>'0');
      elsif ( in_ready=C_RDY ) then	
        if ( load_key=C_ENABLED ) then	
          regs_out <= key_in;
          end if;
      elsif ( rewind_key = C_ENABLED ) then
        regs_out <= key_in; -- s_final_key;
      elsif ( store_key=C_ENABLED ) then	
        regs_out <= next_key;
      elsif ( save_key = C_ENABLED ) then
        -- s_final_key <= regs_out;
        end if; -- in_ready, reset_key, store_key, last_key 
      end if; -- reset, clock
    end process;

  key_out <= regs_out;
  rcon_in <= data_from_sbox_reg; 
  RCon_inst : RCon port map ( next_RCon, ctrl_dec, reset, clk, RCon_byte, rewind_key, save_key  );
  rcon_out <= rcon_in xor ( RCon_byte & X"000000");
  next_key( 127 downto 96 ) <= regs_out( 127 downto 96 ) xor rcon_out;
  
  g002e : if ( not C_INCLUDE_DECODING_LOGIC ) generate 
   data_to_sbox <= ( regs_out( 23 downto 0 ) & regs_out( 31 downto 24 ) );
   next_key(  95 downto 64 ) <= regs_out(  95 downto 64 ) xor next_key( 127 downto 96 );
   next_key(  63 downto 32 ) <= regs_out(  63 downto 32 ) xor next_key(  95 downto 64 );
   next_key(  31 downto  0 ) <= regs_out(  31 downto  0 ) xor next_key(  63 downto 32 );
   end generate; -- not C_INCLUDE_DECODING_LOGIC
     
  g002d : if ( C_INCLUDE_DECODING_LOGIC ) generate 
   data_to_sbox <= ( regs_out( 23 downto 0 ) & regs_out( 31 downto 24 ) ) when ( ctrl_dec = C_ENC ) 
      else ( next_key( 23 downto 0 ) & next_key( 31 downto 24 ) ); 
   next_key(  95 downto 64 ) <= ( regs_out(  95 downto 64 ) xor next_key( 127 downto 96 ) ) when ( ctrl_dec=C_ENC ) 
      else ( regs_out(  95 downto 64 ) xor regs_out( 127 downto 96 ) );
   next_key(  63 downto 32 ) <= ( regs_out(  63 downto 32 ) xor next_key(  95 downto 64 ) ) when ( ctrl_dec=C_ENC ) 
      else ( regs_out(  63 downto 32 ) xor regs_out(  95 downto 64 ) );
   next_key(  31 downto  0 ) <= ( regs_out(  31 downto  0 ) xor next_key(  63 downto 32 ) ) when ( ctrl_dec=C_ENC ) 
      else ( regs_out(  31 downto  0 ) xor regs_out(  63 downto 32 ) );
   end generate; -- C_INCLUDE_DECODING_LOGIC

	SB_A : sbox port map( data_to_sbox( 31 downto 24 ), C_ENC, clk, data_from_sbox( 31 downto 24 ) );
	SB_B : sbox port map( data_to_sbox( 23 downto 16 ), C_ENC, clk, data_from_sbox( 23 downto 16 ) );
	SB_C : sbox port map( data_to_sbox( 15 downto  8 ), C_ENC, clk, data_from_sbox( 15 downto  8 ) );
	SB_D : sbox port map( data_to_sbox(  7 downto  0 ), C_ENC, clk, data_from_sbox(  7 downto  0 ) );
  sbox_reg : reg_B generic map( 32 ) port map( clk, reset, data_from_sbox, data_from_sbox_reg );
  
  end a_keyunit;
