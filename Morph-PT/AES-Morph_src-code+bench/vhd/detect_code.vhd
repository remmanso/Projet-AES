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
  start_cipher : in;
  -- rnd_seed_in  : in std_logic_vector( 13 downto 0 );
  col_reloc : in std_logic_vector( BLK_IDX_SZ-1 downto 0 ); 
  dyn_sbmap : in std_logic_vector( 2 downto 0 ); 
  lin_mask  : in std_logic_vector( MASK_SIZE-1 downto 0 ); 
  data_out : out std_logic_vector( 15 downto 0 );
  clk, rst : in std_logic );
  end round;

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

	signal inH : std_logic_vector( DATA_SIZE-1 downto 0 );
	signal inV0, inV1, inV2, inV3 : std_logic;
	signal data_col0_unmasked, data_col1_unmasked, data_col2_unmasked, data_col3_unmasked : std_logic_vector(31 downto 0);
	signal round : integer range 0 to 11;
	-- Global signals ------------------------------------------------------------
	signal key_word, key_2_add : std_logic_vector( DATA_SIZE-1 downto 0 );
	-- signal blk_idx : std_logic_vector( NUMBER_OF_ROUNDS_INSTANCES*BLK_IDX_SZ-1 downto 0 );
	signal wrd_idx : std_logic_vector( 7 downto 6 );
	signal old_mask_reg, new_mask_reg : std_logic_vector( 31 downto 0 );
	signal enable_H_inputs_delayed : T_ENABLE;
	-- Shuffler signals ----------------------------------------------------------
	signal shuffler_in_pt, shuffler_out_pt : std_logic_vector(3 downto 0);
	signal s_en_shuffle_del, s_en_shuffle_del2 : T_ENABLE;
	signal shuffle_seed_reg : std_logic_vector( 1 downto 0 );
	signal t_dataout : std_logic_vector( 3 downto 0 );
	signal s_reloc_reg : std_logic_vector( 1 downto 0 );
	-- Parity Signals ------------------------------------------------------------
	signal pt_A0, pt_A1, pt_A2, pt_A3, 
		   pt_B0, pt_B1, pt_B2, pt_B3,
		   pt_C0, pt_C1, pt_C2, pt_C3,
		   pt_D0, pt_D1, pt_D2, pt_D3 : std_logic;
	signal sr_Ai, sr_Bi, sr_Ci, sr_Di : std_logic;
	signal sbox_outA, sbox_outB, sbox_outC, sbox_outD : std_logic;
	signal init_cipher : std_logic;
	signal mixcol_in : std_logic_vector( DATA_SIZE-1 downto 0 );
	signal mixcol_in_ptA, mixcol_in_ptB, mixcol_in_ptC, mixcol_in_ptD : std_logic_vector(3 downto 0);
	signal mixcol_out_ptA, mixcol_out_ptB, mixcol_out_ptC, mixcol_out_ptD : std_logic_vector(3 downto 0)
	-- Output Signals ------------------------------------------------------------

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
		else ( data_in( DATA_HI downto 0 ) xor key_2_add );

	inV0 <= sbox_outA;
	inV1 <= sbox_outB;
	inV2 <= sbox_outC;
	inV3 <= sbox_outD;
	-- RSEED : reg_B generic map( 14 ) port map( rnd_seed_in, rnd_seed_reg, clk, rst );
	-- CLRLC : reg_B generic map( 2 ) port map( col_reloc, , clk, rst );
	-- SBMAP : reg_B generic map( 2 ) port map( dyn_sbmap, , clk, rst );
	SHFF  : reg_B generic map( C_CTRL_SIGNAL_SIZE ) port map( enable_shuffle, s_en_shuffle_del, clk, rst );
	SHFF2 : reg_B generic map( C_CTRL_SIGNAL_SIZE ) port map( s_en_shuffle_del, s_en_shuffle_del2, clk, rst );
	-- ENHD  : reg_B generic map( C_CTRL_SIGNAL_SIZE ) port map( enable_H_inputs, enable_H_inputs_delayed, clk, rst );
	
	BEGINNING_CIPHER : process( clk, start_cipher)
	begin
		if (clk'event and clk ='1' and start_cipher ='1') then
			round <= 11;
		end if;
	end process BEGINNING_CIPHER;

	CPT_ROUND : process (clk, enable_H_inputs)
	begin
		if (clk'event and clk ='1' and enable_H_inputs='1') then
			round <= round - 1;
		end if;
	end process CPT_ROUND;

	INIT_ROUND : process (clk, round)
	begin
		if (clk'event and clk = '1') then
			if (round = 10) then
				init_cipher <= 1;
			else
				init_cipher <= 0;
			end if;
		end if;
	end INIT_ROUND;

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
	data_col0_unmasked = inH(127 downto 96) xor old_mask_reg;
	data_col1_unmasked = inH(95 downto 64) xor old_mask_reg;
	data_col2_unmasked = inH(63 downto 32) xor old_mask_reg;
	data_col3_unmasked = inH(31 downto 0) xor old_mask_reg;
	-- First row:
	A0 : datacell_parity port map( clk, rst, data_col0_unmasked(31 downto 24), inV0, 
        mixcol_out_ptA(3), enable_H_inputs, ctrl_dec, init_cipher, pt_A0 );
  	B0 : datacell_parity port map( clk, rst, data_col1_unmasked(31 downto 24), inV1,
        mixcol_out_ptB(3), enable_H_inputs, ctrl_dec, init_cipher, pt_B0 );
  	C0 : datacell_parity port map( clk, rst, data_col2_unmasked(31 downto 24), inV2, 
        mixcol_out_ptC(3), enable_H_inputs, ctrl_dec, init_cipher, pt_C0 );
  	D0 : datacell_parity port map( clk, rst, data_col3_unmasked(31 downto 24), inV3, 
        mixcol_out_ptD(3), enable_H_inputs, ctrl_dec, init_cipher, pt_D0 );
	-- Second row:
	A1 : datacell_parity port map( clk, rst, data_col0_unmasked(23 downto 16), pt_A0,
        mixcol_out_ptA(2), enable_H_inputs, ctrl_dec, init_cipher, pt_A1 );   
  	B1 : datacell_parity port map( clk, rst, data_col1_unmasked(23 downto 16), pt_B0,
        mixcol_out_ptB(2), enable_H_inputs, ctrl_dec, init_cipher, pt_B1 );   
  	C1 : datacell_parity port map( clk, rst, data_col2_unmasked(23 downto 16), pt_C0,
        mixcol_out_ptB(2), enable_H_inputs, ctrl_dec, init_cipher, pt_C1 );
  	D1 : datacell_parity port map( clk, rst, data_col3_unmasked(23 downto 16), pt_D0, 
        mixcol_out_ptB(2), enable_H_inputs, ctrl_dec, init_cipher, pt_D1 );
	-- Third row:
	A2 : datacell_parity port map( clk, rst, data_col0_unmasked(15 downto 8), pt_A1,
        mixcol_out_ptA(1), enable_H_inputs, ctrl_dec, init_cipher, pt_A2 );   
  	B2 : datacell_parity port map( clk, rst, data_col1_unmasked(15 downto 8), pt_B1,
        mixcol_out_ptB(1), enable_H_inputs, ctrl_dec, init_cipher, pt_B2 );   
  	C2 : datacell_parity port map( clk, rst, data_col2_unmasked(15 downto 8), pt_C1,
        mixcol_out_ptC(1), enable_H_inputs, ctrl_dec, init_cipher, pt_C2 );
  	D2 : datacell_parity port map( clk, rst, data_col3_unmasked(15 downto 8), pt_D1, 
        mixcol_out_ptD(1), enable_H_inputs, ctrl_dec, init_cipher, pt_D2 );
	-- Fourth row:
	A3 : datacell_parity port map( clk, rst, data_col0_unmasked(7 downto 0), pt_A2,
        mixcol_out_ptA(0), enable_H_inputs, ctrl_dec, init_cipher, pt_A3 );   
  	B3 : datacell_parity port map( clk, rst, data_col1_unmasked(7 downto 0), pt_B2,
        mixcol_out_ptB(0), enable_H_inputs, ctrl_dec, init_cipher, pt_B3 );   
  	C3 : datacell_parity port map( clk, rst, data_col2_unmasked(7 downto 0), pt_C2,
        mixcol_out_ptC(0), enable_H_inputs, ctrl_dec, init_cipher, pt_C3 );
  	D3 : datacell_parity port map( clk, rst, data_col3_unmasked(7 downto 0), pt_D2, 
        mixcol_out_ptD(0), enable_H_inputs, ctrl_dec, init_cipher, pt_D3 );
	------------------------------------------------------------------------------
	------------------------------------------------------------------------------

	------------------------------------------------------------------------------
	---- SHUFFLER BLOCK ----------------------------------------------------------
	------------------------------------------------------------------------------
	-- shuffler_in <= outA3 & outB3 & outC3 & outD3;
	shuffler_in_pt <= pt_A3 & pt_B3 & pt_C3 & pt_D3;

	RELOC_PROC : process( clk, rst )
    variable flag : std_logic_vector( 3 downto 0 );
  	begin
		if ( rst = RESET_ACTIVE ) then
		  s_reloc_reg <= "00";
		  flag := "0000";
		elsif ( clk='1' and clk'event ) then
		  if ( enable_shuffle = C_ENABLED ) then
		    s_reloc_reg <= col_reloc; 
		    flag := "1111";
		  elsif ( flag /= "0000" ) then -- continuing rotation, after go_shuffle
		    if ( ctrl_dec=C_ENC ) then
		      s_reloc_reg <= std_logic_vector( unsigned( s_reloc_reg ) - 1 ); 
		    else
		      s_reloc_reg <= std_logic_vector( unsigned( s_reloc_reg ) + 1 ); 
		      end if; -- ctrl_dec
		    flag := '0' & flag( 3 downto 1 );
		    end if; -- go_shuffle
		  end if; -- rst, clk
    end process RELOC_PROC;
  
  	t_dataout_pt <= shuffler_in when ( s_reloc_reg(0) = '0' ) else
               	 shuffler_in( 2 downto 0 ) & shuffler_in(3);
  	shuffler_out_pt <= t_dataout when ( s_reloc_reg(1) = '0' ) else
             		t_dataout( 1 downto 0 ) & t_dataout( 3 downto 2 );

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

--	REG_1 : reg_B generic map( 1 ) 
--              port map( shuffler_out_pt(3), sr_Ai,
--                        clock, reset );
--    REG_2 : reg_B generic map( 1 ) 
--              port map( shuffler_out_pt(2), sr_Bi,
--                        clock, reset );
--    REG_3 : reg_B generic map( 1 ) 
--              port map( shuffler_out_pt(1), sr_Ci,
--                        clock, reset );
--    REG_4 : reg_B generic map( 1 ) 
--              port map( shuffler_out_pt(0), sr_Di,
--                        clock, reset );
    ------------------------------------------------------------------------------
  	------------------------------------------------------------------------------
  	SBOX_REG_1 : reg_B generic map( 1 ) 
              port map( shuffler_out_pt(3), sbox_outA,
                        clock, reset );
    SBOX_REG_2 : reg_B generic map( 1 ) 
              port map( shuffler_out_pt(2), sbox_outB,
                        clock, reset );
    SBOX_REG_3 : reg_B generic map( 1 ) 
              port map( shuffler_out_pt(1), sbox_outC,
                        clock, reset );
    SBOX_REG_4 : reg_B generic map( 1 ) 
              port map( shuffler_out_pt(0), sbox_outD,
                        clock, reset );
    ------------------------------------------------------------------------------
  	------------------------------------------------------------------------------

  	------------------------------------------------------------------------------
	---- MIX COLUMN EXPECTATION --------------------------------------------------
	------------------------------------------------------------------------------
	MC_REG : reg_B generic map (DATA_SIZE)
			port map(data_in(DATA_SIZE-1 downto 0), 
				mixcol_in, clock, reset);
	mixcol_in_ptA <= pt_A0 & pt_A1 & pt_A2 & pt_A3;
	mixcol_in_ptB <= pt_B0 & pt_B1 & pt_B2 & pt_B3;
	mixcol_in_ptC <= pt_C0 & pt_C1 & pt_C2 & pt_C3;
	mixcol_in_ptD <= pt_D0 & pt_D1 & pt_D2 & pt_D3;
	MC_COLUMN_A : MC_col_parity port map( mixcol_in( 127 downto 96 ), mixcol_in_ptA, ctrl_dec, mixcol_out_ptA) );
	MC_COLUMN_B : MC_col_parity port map( mixcol_in(  95 downto 64 ), mixcol_in_ptB, ctrl_dec, mixcol_out_ptB) );
	MC_COLUMN_C : MC_col_parity port map( mixcol_in(  63 downto 32 ), mixcol_in_ptC, ctrl_dec, mixcol_out_ptC) );
	MC_COLUMN_D : MC_col_parity port map( mixcol_in(  31 downto  0 ), mixcol_in_ptD, ctrl_dec, mixcol_out_ptD) );

	------------------------------------------------------------------------------
	---- OUTPUT BLOCK ------------------------------------------------------------
	------------------------------------------------------------------------------

	data_out <= mixcol_out_ptA & mixcol_out_ptB & mixcol_out_ptC & mixcol_out_ptD;

end arch;