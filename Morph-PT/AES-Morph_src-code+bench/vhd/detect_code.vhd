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
	component reg_B 
	    generic( G_SIZE : integer := 8 ); 
	    port (
	      din : in std_logic_vector (G_SIZE-1 downto 0);
	      dout : out std_logic_vector (G_SIZE-1 downto 0);
	      clock, reset : in std_logic );
	    end component;
	component shuffler is port(
	    datain : in std_logic_vector( 3 downto 0 );
	    rnd_seed : in std_logic_vector( 1 downto 0 );
	    go_shuffle : in T_ENABLE; -- , realign
	    ctrl_dec : in T_ENCDEC; 
	    clk, rst : in std_logic;
	    dataout : out std_logic_vector( 3 downto 0 );
	    alignment : out std_logic_vector( 1 downto 0 )  );
	end component;
	component sbox_parity port(
        sbox_in : in std_logic_vector(7 downto 0);
        ctrl_dec : in T_ENCDEC;
        error : out std_logic     );
    end component;
    component datacell_parity port(
        clk, rst : in std_logic; 
		in_H : in std_logic_vector (7 downto 0);
		key_data : in std_logic_vector(7 downto 0);
		in_V : in std_logic;
		old_pt : in std_logic;
		enable_H_in : in T_ENABLE;
		end_ciph : in std_logic;
		ctrl_dec : in T_ENCDEC;
		init_cipher : in std_logic;
		b_out : out std_logic);
    end component;
    component MC_col_parity port(
		din : in std_logic_vector (31 downto 0);
		pdin : in std_logic_vector (3 downto 0);
		ctrl_dec : in T_ENCDEC;
		dout : out std_logic_vector (3 downto 0) ) ;
    end component;
    component parity_calculator port (
      data_in : in std_logic_vector( 7 downto 0 ); 
      data_out : out std_logic
	);
	end component;

	signal inH : std_logic_vector( DATA_SIZE-1 downto 0 );
	signal inV0, inV1, inV2, inV3 : std_logic;
	signal data_col0_unmasked, data_col1_unmasked, data_col2_unmasked, data_col3_unmasked : std_logic_vector(31 downto 0);
	signal round : integer range 0 to 12;
	signal end_cipher : std_logic;
	-- Global signals ------------------------------------------------------------
	signal key_word, key_2_add : std_logic_vector( DATA_SIZE-1 downto 0 );
	-- signal blk_idx : std_logic_vector( NUMBER_OF_ROUNDS_INSTANCES*BLK_IDX_SZ-1 downto 0 );
	signal wrd_idx : std_logic_vector( 7 downto 6 );
	signal old_mask_reg, new_mask_reg : std_logic_vector( 31 downto 0 );
	signal enable_H_inputs_delayed : T_ENABLE;
	-- Shuffler signals ----------------------------------------------------------
	signal shuffler_in_pt, shuffler_out_pt, t_dataout_pt : std_logic_vector(3 downto 0);
	signal s_en_shuffle_del, s_en_shuffle_del2 : T_ENABLE;
	signal shuffle_seed_reg : std_logic_vector( 1 downto 0 );
	signal s_reloc_reg : std_logic_vector( 1 downto 0 );
	-- Parity Signals ------------------------------------------------------------
	signal pt_A0, pt_A1, pt_A2, pt_A3, 
		   pt_B0, pt_B1, pt_B2, pt_B3,
		   pt_C0, pt_C1, pt_C2, pt_C3,
		   pt_D0, pt_D1, pt_D2, pt_D3 : std_logic;
	signal sr_Ai, sr_Bi, sr_Ci, sr_Di : std_logic_vector(0 downto 0);
	signal sbox_outA, sbox_outB, sbox_outC, sbox_outD : std_logic_vector(0 downto 0);
	signal init_cipher : std_logic;
	signal mixcol_in_masqued, mixcol_in : std_logic_vector( DATA_SIZE-1 downto 0 );
	signal mixcol_in_ptA, mixcol_in_ptB, mixcol_in_ptC, mixcol_in_ptD : std_logic_vector(3 downto 0);
	signal mixcol_out_ptA, mixcol_out_ptB, mixcol_out_ptC, mixcol_out_ptD : std_logic_vector(3 downto 0);
	signal s_old_ptA, s_old_ptB, s_old_ptC, s_old_ptD : std_logic_vector(3 downto 0);
	signal old_mask_colA, old_mask_colB, old_mask_colC, old_mask_colD : std_logic_vector(31 downto 0);
	signal new_mask_colA, new_mask_colB, new_mask_colC, new_mask_colD : std_logic_vector(31 downto 0);
	-- Output Signals ------------------------------------------------------------
	signal s_pt_aligned : std_logic_vector(15 downto 0);
	signal s_pt_non_aligned : std_logic_vector(15 downto 0);
	signal s_parity_data_in : std_logic_vector(15 downto 0);
	signal s_data_in_unmasked : std_logic_vector(DATA_HI downto 0);
	begin
	  ------------------------------------------------------------------------------
	  ---- INPUT BLOCK -------------------------------------------------------------
	  ------------------------------------------------------------------------------
	key_word <= key  when ( data_in( CLID_HI downto CLID_LO )="00" ) 
					 else key(  95 downto  0 ) & key( 127 downto 96 ) when ( data_in( CLID_HI downto CLID_LO )="01" ) 
					 else key(  63 downto  0 ) & key( 127 downto 64 ) when ( data_in( CLID_HI downto CLID_LO )="10" ) 
					 else key(  31 downto  0 ) & key( 127 downto 32 ); --  when ( data_in( 33 downto 32 )="11" )
	key_2_add <= key_word when ( enable_key=C_ENABLED ) else ( others=>'0' );
	inH <= mixcol_in when ( realign=C_ENABLED ) 
		--else ( data_in( DATA_HI downto 0 ) xor key_2_add );
		else ( data_in( DATA_HI downto 0 ));

	inV0 <= shuffler_out_pt(3);
	inV1 <= shuffler_out_pt(2);
	inV2 <= shuffler_out_pt(1);
	inV3 <= shuffler_out_pt(0);

	--old_mask_colA <= old_mask_reg(31 downto 24) & old_mask_reg(31 downto 24) & 
	--				old_mask_reg(31 downto 24) & old_mask_reg(31 downto 24); 
	--old_mask_colB <= old_mask_reg(23 downto 16) & old_mask_reg(23 downto 16) & 
	--				old_mask_reg(23 downto 16) & old_mask_reg(23 downto 16); 
	--old_mask_colC <= old_mask_reg(15 downto 8) & old_mask_reg(15 downto 8) & 
	--				old_mask_reg(15 downto 8) & old_mask_reg(15 downto 8); 
	--old_mask_colD <= old_mask_reg(7 downto 0) & old_mask_reg(7 downto 0) & 
	--				old_mask_reg(7 downto 0) & old_mask_reg(7 downto 0); 

	new_mask_colA <= new_mask_reg(31 downto 24) & new_mask_reg(31 downto 24) & 
					new_mask_reg(31 downto 24) & new_mask_reg(31 downto 24); 
	new_mask_colB <= new_mask_reg(23 downto 16) & new_mask_reg(23 downto 16) & 
					new_mask_reg(23 downto 16) & new_mask_reg(23 downto 16); 
	new_mask_colC <= new_mask_reg(15 downto 8) & new_mask_reg(15 downto 8) & 
					new_mask_reg(15 downto 8) & new_mask_reg(15 downto 8); 
	new_mask_colD <= new_mask_reg(7 downto 0) & new_mask_reg(7 downto 0) & 
					new_mask_reg(7 downto 0) & new_mask_reg(7 downto 0); 

	-- RSEED : reg_B generic map( 14 ) port map( rnd_seed_in, rnd_seed_reg, clk, rst );
	-- CLRLC : reg_B generic map( 2 ) port map( col_reloc, , clk, rst );
	-- SBMAP : reg_B generic map( 2 ) port map( dyn_sbmap, , clk, rst );
	SHFF  : reg_B generic map( C_CTRL_SIGNAL_SIZE ) port map( enable_shuffle, s_en_shuffle_del, clk, rst );
	SHFF2 : reg_B generic map( C_CTRL_SIGNAL_SIZE ) port map( s_en_shuffle_del, s_en_shuffle_del2, clk, rst );
	-- ENHD  : reg_B generic map( C_CTRL_SIGNAL_SIZE ) port map( enable_H_inputs, enable_H_inputs_delayed, clk, rst );
	
--	BEGINNING_CIPHER : process( clk, start_cipher)
--	begin
--		if (clk'event and clk ='1' and start_cipher ='1') then
--			round <= 11;
--		end if;
--	end process BEGINNING_CIPHER;

	CPT_ROUND : process (clk, enable_H_inputs, start_cipher)
	begin
		if (clk'event and clk ='1') then
			if (start_cipher ='1') then
				round <= 11;
			elsif (enable_H_inputs = C_ENABLED and round > 0) then
				round <= round - 1;
			else 
				round <= round;
			end if;
		end if;
	end process CPT_ROUND;

	INIT_ROUND : process (clk, round)
	begin
		if (clk'event and clk = '1') then
			if (round = 11) then
				init_cipher <= '1';
			else
				init_cipher <= '0';
			end if;
			if (round = 0) then
				end_cipher <= '1';
			else
				end_cipher <= '0';
			end if;
		end if;
	end process INIT_ROUND;

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
	---- STATE Parity-------------------------------------------------------------
	------------------------------------------------------------------------------
	data_col0_unmasked <= inH(127 downto 96) xor new_mask_colA;
	data_col1_unmasked <= inH(95 downto 64) xor new_mask_colB;
	data_col2_unmasked <= inH(63 downto 32) xor new_mask_colC;
	data_col3_unmasked <= inH(31 downto 0) xor new_mask_colD;

	s_old_ptA <= 	mixcol_in_ptA when (enable_H_inputs = C_ENABLED and enable_mc = C_DISABLED)
			else 	mixcol_out_ptA;
	s_old_ptB <= 	mixcol_in_ptB when (enable_H_inputs = C_ENABLED and enable_mc = C_DISABLED)
			else 	mixcol_out_ptB;
	s_old_ptC <= 	mixcol_in_ptC when (enable_H_inputs = C_ENABLED and enable_mc = C_DISABLED)
			else 	mixcol_out_ptC;
	s_old_ptD <= 	mixcol_in_ptD when (enable_H_inputs = C_ENABLED and enable_mc = C_DISABLED)
			else 	mixcol_out_ptD;
	-- First row:
	A0 : datacell_parity port map( clk, rst, data_col0_unmasked(31 downto 24), key_2_add(127 downto 120),
	 	inV0, s_old_ptA(3), enable_H_inputs, end_cipher, ctrl_dec, init_cipher, pt_A0 );
  	B0 : datacell_parity port map( clk, rst, data_col1_unmasked(31 downto 24), key_2_add(95 downto 88), inV1,
        s_old_ptB(3), enable_H_inputs, end_cipher, ctrl_dec, init_cipher, pt_B0 );
  	C0 : datacell_parity port map( clk, rst, data_col2_unmasked(31 downto 24), key_2_add(63 downto 56), inV2, 
        s_old_ptC(3), enable_H_inputs, end_cipher, ctrl_dec, init_cipher, pt_C0 );
  	D0 : datacell_parity port map( clk, rst, data_col3_unmasked(31 downto 24), key_2_add(31 downto 24), inV3, 
        s_old_ptD(3), enable_H_inputs, end_cipher, ctrl_dec, init_cipher, pt_D0 );
	-- Second row:
	A1 : datacell_parity port map( clk, rst, data_col0_unmasked(23 downto 16), key_2_add(119 downto 112), pt_A0,
        s_old_ptA(2), enable_H_inputs, end_cipher, ctrl_dec, init_cipher, pt_A1 );   
  	B1 : datacell_parity port map( clk, rst, data_col1_unmasked(23 downto 16), key_2_add(87 downto 80), pt_B0,
        s_old_ptB(2), enable_H_inputs, end_cipher, ctrl_dec, init_cipher, pt_B1 );   
  	C1 : datacell_parity port map( clk, rst, data_col2_unmasked(23 downto 16), key_2_add(55 downto 48), pt_C0,
        s_old_ptC(2), enable_H_inputs, end_cipher, ctrl_dec, init_cipher, pt_C1 );
  	D1 : datacell_parity port map( clk, rst, data_col3_unmasked(23 downto 16), key_2_add(23 downto 16), pt_D0, 
        s_old_ptD(2), enable_H_inputs, end_cipher, ctrl_dec, init_cipher, pt_D1 );
	-- Third row:
	A2 : datacell_parity port map( clk, rst, data_col0_unmasked(15 downto 8), key_2_add(111 downto 104), pt_A1,
        s_old_ptA(1), enable_H_inputs, end_cipher, ctrl_dec, init_cipher, pt_A2 );   
  	B2 : datacell_parity port map( clk, rst, data_col1_unmasked(15 downto 8), key_2_add(79 downto 72), pt_B1,
        s_old_ptB(1), enable_H_inputs, end_cipher, ctrl_dec, init_cipher, pt_B2 );   
  	C2 : datacell_parity port map( clk, rst, data_col2_unmasked(15 downto 8), key_2_add(47 downto 40), pt_C1,
        s_old_ptC(1), enable_H_inputs, end_cipher, ctrl_dec, init_cipher, pt_C2 );
  	D2 : datacell_parity port map( clk, rst, data_col3_unmasked(15 downto 8), key_2_add(15 downto 8), pt_D1, 
        s_old_ptD(1), enable_H_inputs, end_cipher, ctrl_dec, init_cipher, pt_D2 );
	-- Fourth row:
	A3 : datacell_parity port map( clk, rst, data_col0_unmasked(7 downto 0), key_2_add(103 downto 96), pt_A2,
        s_old_ptA(0), enable_H_inputs, end_cipher, ctrl_dec, init_cipher, pt_A3 );   
  	B3 : datacell_parity port map( clk, rst, data_col1_unmasked(7 downto 0), key_2_add(71 downto 64), pt_B2,
        s_old_ptB(0), enable_H_inputs, end_cipher, ctrl_dec, init_cipher, pt_B3 );   
  	C3 : datacell_parity port map( clk, rst, data_col2_unmasked(7 downto 0), key_2_add(39 downto 32), pt_C2,
        s_old_ptC(0), enable_H_inputs, end_cipher, ctrl_dec, init_cipher, pt_C3 );
  	D3 : datacell_parity port map( clk, rst, data_col3_unmasked(7 downto 0), key_2_add(7 downto 0), pt_D2, 
        s_old_ptD(0), enable_H_inputs, end_cipher, ctrl_dec, init_cipher, pt_D3 );
	------------------------------------------------------------------------------
	------------------------------------------------------------------------------

	------------------------------------------------------------------------------
	---- SHUFFLER BLOCK ----------------------------------------------------------
	------------------------------------------------------------------------------
	-- shuffler_in <= outA3 & outB3 & outC3 & outD3;
	--shuffler_in_pt <= pt_A3 & pt_B3 & pt_C3 & pt_D3;
	sr_Ai(0) <= pt_A3;
	sr_Bi(0) <= pt_B3;
	sr_Ci(0) <= pt_C3;
	sr_Di(0) <= pt_D3;
	--RELOC_PROC : process( clk, rst )
    --variable flag : std_logic_vector( 3 downto 0 );
  	--begin
	--	if ( rst = RESET_ACTIVE ) then
	--	  s_reloc_reg <= "00";
	--	  flag := "0000";
	--	elsif ( clk='1' and clk'event ) then
	--	  if ( enable_shuffle = C_ENABLED ) then
	--	    s_reloc_reg <= col_reloc; 
	--	    flag := "1111";
	--	  elsif ( flag /= "0000" ) then -- continuing rotation, after go_shuffle
	--	    if ( ctrl_dec=C_ENC ) then
	--	      s_reloc_reg <= std_logic_vector( unsigned( s_reloc_reg ) - 1 ); 
	--	    else
	--	      s_reloc_reg <= std_logic_vector( unsigned( s_reloc_reg ) + 1 ); 
	--	      end if; -- ctrl_dec
	--	    flag := '0' & flag( 3 downto 1 );
	--	    end if; -- go_shuffle
	--	  end if; -- rst, clk
    --end process RELOC_PROC;

    RELOC_PROC : process( clk, rst )
    variable flag : std_logic_vector( 3 downto 0 );
    variable cpt : std_logic_vector(2 downto 0);
  	begin
		if ( rst = RESET_ACTIVE ) then
		  s_reloc_reg <= "00";
		  flag := "0000";
		elsif ( clk='1' and clk'event ) then
		  if ( enable_H_inputs = C_ENABLED ) then
		    flag := "0000";
		    cpt := "111";
		  elsif ( flag /= "0000" ) then 
		    if ( ctrl_dec=C_ENC ) then
		      	s_reloc_reg <= std_logic_vector( unsigned( s_reloc_reg ) - 1 ); 
		    else
		      	s_reloc_reg <= std_logic_vector( unsigned( s_reloc_reg ) + 1 ); 
		    end if; 
		    flag := '0' & flag( 3 downto 1 ); 
		  elsif (cpt = "001") then
		  	s_reloc_reg <= std_logic_vector(unsigned(col_reloc) + 1);
		  	flag := "1111";
		  end if;
		  cpt := '0' & cpt(2 downto 1);
		end if;
    end process RELOC_PROC;
   	
   	t_dataout_pt <= shuffler_in_pt when ( s_reloc_reg(0) = '0' ) else
               	 shuffler_in_pt( 2 downto 0 ) & shuffler_in_pt(3);
  	shuffler_out_pt <= t_dataout_pt when ( s_reloc_reg(1) = '0' ) else
             		t_dataout_pt( 1 downto 0 ) & t_dataout_pt( 3 downto 2 );

    -- TRACK REGISTER ------------------------------------------------------------
	TRK_REG_PROC : process( clk, rst )
	begin
	    if ( clk='1' and clk'event ) then
	        if ( enable_shuffle = C_ENABLED ) then 
					shuffle_seed_reg <= col_reloc; -- rnd_seed_reg( 1 downto 0 );
	        end if; -- go_shuffle
	      end if; -- rst, clk
    end process TRK_REG_PROC;
    ------------------------------------------------------------------------------
  	------------------------------------------------------------------------------

	REG_1 : reg_B generic map( 1 ) 
              port map( sr_Ai, sbox_outA,
                        clk, rst );
    REG_2 : reg_B generic map( 1 ) 
              port map( sr_Bi, sbox_outB,
                        clk, rst );
    REG_3 : reg_B generic map( 1 ) 
              port map( sr_Ci, sbox_outC,
                        clk, rst );
    REG_4 : reg_B generic map( 1 ) 
              port map( sr_Di, sbox_outD,
                        clk, rst );
    ------------------------------------------------------------------------------
  	------------------------------------------------------------------------------
  	SBOX_REG_1 : reg_B generic map( 1 ) 
              port map( sbox_outA, shuffler_in_pt(3 downto 3),
                        clk, rst );
    SBOX_REG_2 : reg_B generic map( 1 ) 
              port map( sbox_outB, shuffler_in_pt(2 downto 2),
                        clk, rst );
    SBOX_REG_3 : reg_B generic map( 1 ) 
              port map( sbox_outC, shuffler_in_pt(1 downto 1),
                        clk, rst );
    SBOX_REG_4 : reg_B generic map( 1 ) 
              port map( sbox_outD, shuffler_in_pt(0 downto 0),
                        clk, rst );
    ------------------------------------------------------------------------------
  	------------------------------------------------------------------------------

  	------------------------------------------------------------------------------
	---- MIX COLUMN EXPECTATION --------------------------------------------------
	------------------------------------------------------------------------------
	MC_REG : reg_B generic map (DATA_SIZE)
			port map(data_in(DATA_SIZE-1 downto 0), 
				mixcol_in_masqued, clk, rst);
	mixcol_in <= 	(mixcol_in_masqued(127 downto 96) xor new_mask_colA) & 
					(mixcol_in_masqued(95 downto 64) xor new_mask_colB) &
					(mixcol_in_masqued(63 downto 32) xor new_mask_colC) &
					(mixcol_in_masqued(31 downto 0) xor new_mask_colD);
	mixcol_in_ptA <= pt_A0 & pt_A1 & pt_A2 & pt_A3;
	mixcol_in_ptB <= pt_B0 & pt_B1 & pt_B2 & pt_B3;
	mixcol_in_ptC <= pt_C0 & pt_C1 & pt_C2 & pt_C3;
	mixcol_in_ptD <= pt_D0 & pt_D1 & pt_D2 & pt_D3;
	MC_COLUMN_A : MC_col_parity port map( mixcol_in( 127 downto 96 ), mixcol_in_ptA, ctrl_dec, mixcol_out_ptA) ;
	MC_COLUMN_B : MC_col_parity port map( mixcol_in(  95 downto 64 ), mixcol_in_ptB, ctrl_dec, mixcol_out_ptB) ;
	MC_COLUMN_C : MC_col_parity port map( mixcol_in(  63 downto 32 ), mixcol_in_ptC, ctrl_dec, mixcol_out_ptC) ;
	MC_COLUMN_D : MC_col_parity port map( mixcol_in(  31 downto  0 ), mixcol_in_ptD, ctrl_dec, mixcol_out_ptD) ;

  	------------------------------------------------------------------------------
	---- PARITY COMPARISON -------------------------------------------------------
	------------------------------------------------------------------------------
	s_data_in_unmasked <= data_in(DATA_HI downto 0) xor ExpandMask( data_in(MASK_HI downto MASK_LO) ) when (realign = C_ENABLED)
	else (others => '0');

	PC0 : parity_calculator port map(s_data_in_unmasked( 7 downto 0), s_parity_data_in(0)); 
	PC1 : parity_calculator port map(s_data_in_unmasked( 15 downto 8), s_parity_data_in(1)); 
	PC2 : parity_calculator port map(s_data_in_unmasked( 23 downto 16), s_parity_data_in(2)); 
	PC3 : parity_calculator port map(s_data_in_unmasked( 31 downto 24), s_parity_data_in(3)); 
	PC4 : parity_calculator port map(s_data_in_unmasked( 39 downto 32), s_parity_data_in(4)); 
	PC5 : parity_calculator port map(s_data_in_unmasked( 47 downto 40), s_parity_data_in(5)); 
	PC6 : parity_calculator port map(s_data_in_unmasked( 55 downto 48), s_parity_data_in(6)); 
	PC7 : parity_calculator port map(s_data_in_unmasked( 63 downto 56), s_parity_data_in(7)); 
	PC8 : parity_calculator port map(s_data_in_unmasked( 71 downto 64), s_parity_data_in(8)); 
	PC9 : parity_calculator port map(s_data_in_unmasked( 79 downto 72), s_parity_data_in(9)); 
	PC10 : parity_calculator port map(s_data_in_unmasked( 87 downto 80), s_parity_data_in(10)); 
	PC11 : parity_calculator port map(s_data_in_unmasked( 95 downto 88), s_parity_data_in(11)); 
	PC12 : parity_calculator port map(s_data_in_unmasked( 103 downto 96), s_parity_data_in(12)); 
	PC13 : parity_calculator port map(s_data_in_unmasked( 111 downto 104), s_parity_data_in(13)); 
	PC14 : parity_calculator port map(s_data_in_unmasked( 119 downto 112), s_parity_data_in(14)); 
	PC15 : parity_calculator port map(s_data_in_unmasked( 127 downto 120), s_parity_data_in(15));  
	
	alarm <= C_ENABLED when (s_parity_data_in /=  s_pt_non_aligned and realign=C_ENABLED)
		else C_DISABLED;

	------------------------------------------------------------------------------
	---- OUTPUT BLOCK ------------------------------------------------------------
	------------------------------------------------------------------------------
	s_pt_non_aligned <= mixcol_in_ptA & mixcol_in_ptB & mixcol_in_ptC & mixcol_in_ptD ; 
	s_pt_aligned <= ( mixcol_in_ptA & mixcol_in_ptB & mixcol_in_ptC & mixcol_in_ptD ) 
						when ( wrd_idx( 7 downto 6 )="00" ) 
					else  ( mixcol_in_ptB & mixcol_in_ptC & mixcol_in_ptD & mixcol_in_ptA ) 
						when ( wrd_idx( 7 downto 6 )="11" ) 
					else  ( mixcol_in_ptC & mixcol_in_ptD & mixcol_in_ptA & mixcol_in_ptB ) 
						when ( wrd_idx( 7 downto 6 )="10" ) 
					else  ( mixcol_in_ptD & mixcol_in_ptA & mixcol_in_ptB & mixcol_in_ptC )
						when ( wrd_idx( 7 downto 6 )="01" )
					else  ( others=>'0' );

	data_out <= s_pt_aligned when (realign = C_ENABLED)
				else (mixcol_out_ptA & mixcol_out_ptB & mixcol_out_ptC & mixcol_out_ptD);

end a_detect_code;