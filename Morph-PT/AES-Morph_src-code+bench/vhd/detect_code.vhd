-- Library Declaration
library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;
library WORK;
  use WORK.params.all;

-- Component Declaration
entity detect_code is port (
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
  clk, rst : in std_logic;
  alarm : out T_ENABLE 
  );
  end detect_code;

-- Architecture of the Component
Architecture a_detect_code of detect_code is
    component parity_calculator port (
      data_in : in std_logic_vector( 7 downto 0 ); 
      data_out : out std_logic
	); 
	end component;
	component parity_expectation port (
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
		data_out : out std_logic_vector(15 downto 0);
		clk, rst : in std_logic
		);
	end component;

	signal s_data_out_parity : std_logic_vector(15 downto 0);

	-- signal blk_idx : std_logic_vector( NUMBER_OF_ROUNDS_INSTANCES*BLK_IDX_SZ-1 downto 0 );
	signal wrd_idx : std_logic_vector( 7 downto 6 );
	signal old_mask_reg, new_mask_reg : std_logic_vector( 31 downto 0 );
	-- Shuffler signals ----------------------------------------------------------
	signal s_en_shuffle_del, s_en_shuffle_del2 : T_ENABLE;
	signal shuffle_seed_reg : std_logic_vector( 1 downto 0 );
	-- Output Signals ------------------------------------------------------------
	signal s_parity_data_in : std_logic_vector(15 downto 0);
	signal s_data_in_unmasked : std_logic_vector(DATA_HI downto 0);
	begin

	PARITY_EXP : parity_expectation port map(data_in, key, ctrl_dec, enable_H_inputs, enable_shuffle, realign, set_new_mask,
		enable_mc, enable_key, start_cipher, col_reloc, dyn_sbmap, lin_mask, s_data_out_parity, clk, rst);

	WRD_IDX_PROC : process( clk )
	begin
		if ( clk'event and clk='1' ) then
			if ( rst=RESET_ACTIVE ) then
				wrd_idx <= "11"; 
			elsif ( realign=C_ENABLED ) then
				wrd_idx <= wrd_idx; 
			elsif ( enable_H_inputs=C_ENABLED ) then
        wrd_idx <= data_in( CLID_HI downto CLID_LO );
      elsif ( s_en_shuffle_del2 = C_ENABLED ) then 
        wrd_idx <= std_logic_vector( unsigned( wrd_idx ) + unsigned( shuffle_seed_reg ) );
				end if; -- rst, enable_H_inputs
			end if; -- clk
		end process WRD_IDX_PROC;
		
	
  -- LINEAR MASK ---------------------------------------------------------------
	OLD_MASK_PROC : process( clk ) 
	begin
		if ( clk'event and clk='1' ) then
			if ( rst=RESET_ACTIVE ) then
				old_mask_reg <= ( others=>'0' );
			elsif ( enable_H_inputs = C_ENABLED ) then 
				if ( realign = C_ENABLED ) then 
					old_mask_reg <= old_mask_reg;
				else
					old_mask_reg <= data_in( MASK_HI downto MASK_LO );
					end if;
				end if; -- rst, enable_H_inputs
			end if; -- clk
	end process OLD_MASK_PROC;
	NEW_MASK_PROC : process( clk ) 
	begin
		if ( clk'event and clk='1' ) then
			if ( rst=RESET_ACTIVE ) then
				new_mask_reg <= ( others=>'0' );
			elsif ( set_new_mask = C_ENABLED ) then 
				new_mask_reg <= lin_mask;
			elsif ( enable_H_inputs = C_ENABLED ) then 
				new_mask_reg <= data_in( MASK_HI downto MASK_LO );
				end if; -- rst, enable_H_inputs
			end if; -- clk
	end process NEW_MASK_PROC;

	
  	------------------------------------------------------------------------------
	---- PARITY COMPARISON -------------------------------------------------------
	------------------------------------------------------------------------------
	s_data_in_unmasked <= data_in(DATA_HI downto 0) xor ExpandMask( data_in(MASK_HI downto MASK_LO) ) when (realign = C_ENABLED)
	else (others => '0');

	--PC0 : parity_calculator port map(s_data_in_unmasked( 7 downto 0), s_parity_data_in(0)); 
	--PC1 : parity_calculator port map(s_data_in_unmasked( 15 downto 8), s_parity_data_in(1)); 
	--PC2 : parity_calculator port map(s_data_in_unmasked( 23 downto 16), s_parity_data_in(2)); 
	--PC3 : parity_calculator port map(s_data_in_unmasked( 31 downto 24), s_parity_data_in(3)); 
	--PC4 : parity_calculator port map(s_data_in_unmasked( 39 downto 32), s_parity_data_in(4)); 
	--PC5 : parity_calculator port map(s_data_in_unmasked( 47 downto 40), s_parity_data_in(5)); 
	--PC6 : parity_calculator port map(s_data_in_unmasked( 55 downto 48), s_parity_data_in(6)); 
	--PC7 : parity_calculator port map(s_data_in_unmasked( 63 downto 56), s_parity_data_in(7)); 
	--PC8 : parity_calculator port map(s_data_in_unmasked( 71 downto 64), s_parity_data_in(8)); 
	--PC9 : parity_calculator port map(s_data_in_unmasked( 79 downto 72), s_parity_data_in(9)); 
	--PC10 : parity_calculator port map(s_data_in_unmasked( 87 downto 80), s_parity_data_in(10)); 
	--PC11 : parity_calculator port map(s_data_in_unmasked( 95 downto 88), s_parity_data_in(11)); 
	--PC12 : parity_calculator port map(s_data_in_unmasked( 103 downto 96), s_parity_data_in(12)); 
	--PC13 : parity_calculator port map(s_data_in_unmasked( 111 downto 104), s_parity_data_in(13)); 
	--PC14 : parity_calculator port map(s_data_in_unmasked( 119 downto 112), s_parity_data_in(14)); 
	--PC15 : parity_calculator port map(s_data_in_unmasked( 127 downto 120), s_parity_data_in(15));  
	
<<<<<<< HEAD
	PC_for : for I in 1 to 16 generate
	PC_I : parity_calculator port map(
		data_in => s_data_in_unmasked(8*I-1 downto 8*(I-1)), 
		data_out => s_parity_data_in(I-1));
	end generate PC_for;

	alarm <= C_ENABLED when (s_parity_data_in /= s_pt_aligned and realign=C_ENABLED)
		else C_DISABLED;
=======
	
>>>>>>> ca3a46ad34026cafc0079f877f306b7133b11fe0

	------------------------------------------------------------------------------
	---- OUTPUT BLOCK ------------------------------------------------------------
	------------------------------------------------------------------------------
	
	alarm <= C_ENABLED when (s_parity_data_in /= s_data_out_parity and realign=C_ENABLED)
		else C_DISABLED;

	data_out <= s_data_out_parity;

end a_detect_code;