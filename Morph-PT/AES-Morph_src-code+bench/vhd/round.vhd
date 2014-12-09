-- Library Declaration
library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;
library WORK;
  use WORK.params.all;

-- Component Declaration
entity round is port (
  data_in : in std_logic_vector( BLID_HI downto 0 ); 
  key : in std_logic_vector( 127 downto 0 ); 
  ctrl_dec : in T_ENCDEC;
  enable_H_inputs : in T_ENABLE;
  enable_shuffle, realign : in T_ENABLE; 
	set_new_mask : in T_ENABLE; 
	enable_mc  : in T_ENABLE;
  enable_mc_in : in T_ENABLE;
  enable_key : in T_ENABLE;
  -- rnd_seed_in  : in std_logic_vector( 13 downto 0 );
	col_reloc : in std_logic_vector( BLK_IDX_SZ-1 downto 0 ); 
	dyn_sbmap : in std_logic_vector( 2 downto 0 ); 
	lin_mask  : in std_logic_vector( MASK_SIZE-1 downto 0 ); 
  data_out : out std_logic_vector( BLID_HI downto 0 );
  clk, rst : in std_logic );
  end round;

-- Architecture of the Component
architecture arch of round is
  component reg_B 
    generic( G_SIZE : integer := 8 ); 
    port (
      din : in std_logic_vector (G_SIZE-1 downto 0);
      dout : out std_logic_vector (G_SIZE-1 downto 0);
      clock, reset : in std_logic );
  end component;
  component datacell port (
  	clock, reset : in std_logic; 
  	in_H, in_V : in std_logic_vector (7 downto 0);
  	enable_H_in : in T_ENABLE;
  	b_out : out std_logic_vector (7 downto 0) );
    end component;
  component sbox port (
    b_in : in std_logic_vector (7 downto 0);
    ctrl_dec : T_ENCDEC;
    clock : in std_logic;
    b_out : out std_logic_vector (7 downto 0)   );
  end component;
--  component sbox_randomized is 
--    generic (
--      G_Field_0 : integer range 1 to 8 := 1;
--      G_Field_1 : integer range 1 to 8 := 1
--      );
--    port (
--      b_in : in std_logic_vector (7 downto 0);
--      ctrl_dec : in T_ENCDEC;
--      choose_field : in std_logic;
--      clock : in std_logic;
--      b_out : out std_logic_vector (7 downto 0)   );
--      end component;
	component sbox_8map is 
		port (
    	b_in : in std_logic_vector (7 downto 0);
    	ctrl_dec : in T_ENCDEC;
    	rnd_seed : in std_logic_vector (2 downto 0);
	    clock, reset : in std_logic;
    	b_out : out std_logic_vector (7 downto 0)   );
    	end component;
  component MC_col port (
    din : in std_logic_vector (31 downto 0);
    ctrl_dec : in T_ENCDEC;
    dout : out std_logic_vector (31 downto 0) ) ;
    end component;
  component shuffler is port(
    datain : in std_logic_vector( 31 downto 0 );
    rnd_seed : in std_logic_vector( 1 downto 0 );
    go_shuffle : in T_ENABLE; -- , realign
    ctrl_dec : in T_ENCDEC; 
    clk, rst : in std_logic;
    dataout : out std_logic_vector( 31 downto 0 );
    alignment : out std_logic_vector( 1 downto 0 )  );
    end component;
  signal inH : std_logic_vector( DATA_SIZE-1 downto 0 );
  signal inV : std_logic_vector( 31 downto 0 );
  signal outA0, outB0, outC0, outD0, outA1, outB1, outC1, outD1, 
        outA2, outB2, outC2, outD2, outA3, outB3, outC3, outD3 : std_logic_vector( 7 downto 0 ); 
  signal sbAi, sbBi, sbCi, sbDi, sbAo, sbBo, sbCo, sbDo : std_logic_vector( 7 downto 0 );
  signal sbox_out, sbox_reg_out, sbox_out_masked, 
         shuffler_in_masked, shuffler_in, shuffler_out : std_logic_vector( 31 downto 0 );
  signal mixcol_in, mixcol_out : std_logic_vector( DATA_SIZE-1 downto 0 );
  signal column_A, column_B, column_C, column_D : std_logic_vector( 31 downto 0 );
  -- Global signals ------------------------------------------------------------
	signal key_word, key_2_add : std_logic_vector( DATA_SIZE-1 downto 0 );
	-- signal blk_idx : std_logic_vector( NUMBER_OF_ROUNDS_INSTANCES*BLK_IDX_SZ-1 downto 0 );
	signal blk_idx : std_logic_vector( BLK_IDX_SZ-1 downto 0 ); -- 20130104: 4*
	signal wrd_idx : std_logic_vector( 7 downto 6 );
	signal old_mask_reg, new_mask_reg : std_logic_vector( 31 downto 0 );
	signal enable_H_inputs_delayed : T_ENABLE;
	-- Shuffler signals ----------------------------------------------------------
	signal s_en_shuffle_del, s_en_shuffle_del2 : T_ENABLE;
	signal shuffle_seed_reg : std_logic_vector( 1 downto 0 );
  signal t_dataout : std_logic_vector( 31 downto 0 );
  signal s_reloc_reg : std_logic_vector( 1 downto 0 );
	-- signal rnd_seed_reg : std_logic_vector( 13 downto 0 );
	-- Output Signals ------------------------------------------------------------
	signal s_blk_idx_out : std_logic_vector( BLK_IDX_SZ-1 downto 0 );
  signal s_aligned_data : std_logic_vector( MASK_HI downto 0 );
	signal s_mcoff_data : std_logic_vector( CLID_HI downto 0 );
  signal s_mix_col_bus_in : std_logic_vector( BLID_HI downto 0 );
begin
  ------------------------------------------------------------------------------
  ---- INPUT BLOCK -------------------------------------------------------------
  ------------------------------------------------------------------------------
	key_word <= key                                         when ( data_in( CLID_HI downto CLID_LO )="00" ) 
				 else key(  95 downto  0 ) & key( 127 downto 96 ) when ( data_in( CLID_HI downto CLID_LO )="01" ) 
				 else key(  63 downto  0 ) & key( 127 downto 64 ) when ( data_in( CLID_HI downto CLID_LO )="10" ) 
				 else key(  31 downto  0 ) & key( 127 downto 32 ); --  when ( data_in( 33 downto 32 )="11" )
	key_2_add <= key_word when ( enable_key=C_ENABLED ) else ( others=>'0' );
  inH <= mixcol_in when ( realign=C_ENABLED ) 
		else ( data_in( DATA_HI downto 0 ) xor key_2_add );
  inV <= sbox_reg_out;
	
	-- RSEED : reg_B generic map( 14 ) port map( rnd_seed_in, rnd_seed_reg, clk, rst );
	-- CLRLC : reg_B generic map( 2 ) port map( col_reloc, , clk, rst );
	-- SBMAP : reg_B generic map( 2 ) port map( dyn_sbmap, , clk, rst );
	SHFF  : reg_B generic map( C_CTRL_SIGNAL_SIZE ) port map( enable_shuffle, s_en_shuffle_del, clk, rst );
	SHFF2 : reg_B generic map( C_CTRL_SIGNAL_SIZE ) port map( s_en_shuffle_del, s_en_shuffle_del2, clk, rst );
	-- ENHD  : reg_B generic map( C_CTRL_SIGNAL_SIZE ) port map( enable_H_inputs, enable_H_inputs_delayed, clk, rst );
	
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
		
	BLK_IDX_PROC : process( clk )
	begin
		if ( clk'event and clk='1' ) then
			if ( rst=RESET_ACTIVE ) then
				blk_idx <= ( others=>'1' );
			elsif ( enable_H_inputs = C_ENABLED ) then 
				blk_idx <= data_in( BLID_HI downto BLID_LO ); 
				end if; -- rst, enable_H_inputs
			end if; -- clk
		end process BLK_IDX_PROC;

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
  ---- STATE -------------------------------------------------------------------
  ------------------------------------------------------------------------------
  -- First row:
  A0 : datacell port map( clk, rst, inH(127 downto 120), inV( 31 downto 24 ), 
        enable_H_inputs, outA0 );
  B0 : datacell port map( clk, rst, inH( 95 downto 88 ), inV( 23 downto 16 ),
        enable_H_inputs, outB0 );
  C0 : datacell port map( clk, rst, inH( 63 downto 56 ), inV( 15 downto 8 ), 
        enable_H_inputs, outC0 );
  D0 : datacell port map( clk, rst, inH( 31 downto 24 ), inV( 7 downto 0 ), 
        enable_H_inputs, outD0 );
  -- Second row:
  A1 : datacell port map( clk, rst, inH(119 downto 112), outA0,
        enable_H_inputs, outA1 );   
  B1 : datacell port map( clk, rst, inH( 87 downto 80 ), outB0,
        enable_H_inputs, outB1 );   
  C1 : datacell port map( clk, rst, inH( 55 downto 48 ), outC0,
        enable_H_inputs, outC1 );
  D1 : datacell port map( clk, rst, inH( 23 downto 16 ), outD0, 
        enable_H_inputs, outD1 );
  -- Third row:
  A2 : datacell port map( clk, rst, inH(111 downto 104), outA1,
        enable_H_inputs, outA2 );   
  B2 : datacell port map( clk, rst, inH( 79 downto 72 ), outB1,
        enable_H_inputs, outB2 );   
  C2 : datacell port map( clk, rst, inH( 47 downto 40 ), outC1,
        enable_H_inputs, outC2 );
  D2 : datacell port map( clk, rst, inH( 15 downto 8 ), outD1, 
        enable_H_inputs, outD2 );
  -- Fourth row:
  A3 : datacell port map( clk, rst, inH(103 downto 96 ), outA2,
        enable_H_inputs, outA3 );   
  B3 : datacell port map( clk, rst, inH( 71 downto 64 ), outB2, 
        enable_H_inputs, outB3 );   
  C3 : datacell port map( clk, rst, inH( 39 downto 32 ), outC2, 
        enable_H_inputs, outC3 );
  D3 : datacell port map( clk, rst, inH(  7 downto  0 ), outD2, 
        enable_H_inputs, outD3 );
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------

  ------------------------------------------------------------------------------
  ---- SHUFFLER BLOCK ----------------------------------------------------------
  ------------------------------------------------------------------------------
  -- shuffler_in <= outA3 & outB3 & outC3 & outD3;
	shuffler_in_masked <= outA3 & outB3 & outC3 & outD3;
	shuffler_in <= shuffler_in_masked xor old_mask_reg;

  -- RELOC REG -----------------------------------------------------------------
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
  
  t_dataout <= shuffler_in when ( s_reloc_reg(0) = '0' ) else
               shuffler_in( 23 downto 0 ) & shuffler_in( 31 downto 24 );
  shuffler_out <= t_dataout when ( s_reloc_reg(1) = '0' ) else
             			t_dataout( 15 downto 0 ) & t_dataout( 31 downto 16 );

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
  
  ------------------------------------------------------------------------------
  ---- SUBBYTES BLOCK ----------------------------------------------------------
  ------------------------------------------------------------------------------
  sbAi <= shuffler_out( 31 downto 24 );
  sbBi <= shuffler_out( 23 downto 16 );
  sbCi <= shuffler_out( 15 downto  8 );
  sbDi <= shuffler_out(  7 downto  0 );
  SB_A : sbox_8map port map( sbAi, ctrl_dec, dyn_sbmap, clk, rst, sbAo );
  SB_B : sbox_8map port map( sbBi, ctrl_dec, dyn_sbmap, clk, rst, sbBo );
  SB_C : sbox_8map port map( sbCi, ctrl_dec, dyn_sbmap, clk, rst, sbCo );
  SB_D : sbox_8map port map( sbDi, ctrl_dec, dyn_sbmap, clk, rst, sbDo );
--  SB_A : sbox port map( sbAi, ctrl_dec, clk, sbAo );
--  SB_B : sbox port map( sbBi, ctrl_dec, clk, sbBo );
--  SB_C : sbox port map( sbCi, ctrl_dec, clk, sbCo );
--  SB_D : sbox port map( sbDi, ctrl_dec, clk, sbDo );
  sbox_out <= sbAo & sbBo & sbCo & sbDo;
	sbox_out_masked <= sbox_out xor new_mask_reg;
	sbox_reg : reg_B generic map( 32 ) port map( sbox_out_masked, sbox_reg_out, clk, rst );
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
 
  ------------------------------------------------------------------------------
  ---- MIXCOLUMNS BLOCK --------------------------------------------------------
  ------------------------------------------------------------------------------
  column_A <= outA0 & outA1 & outA2 & outA3;
  column_B <= outB0 & outB1 & outB2 & outB3;
  column_C <= outC0 & outC1 & outC2 & outC3;
  column_D <= outD0 & outD1 & outD2 & outD3;
  mixcol_in <= column_A & column_B & column_C & column_D;
  MC_COLUMN_A : MC_col port map( mixcol_in( 127 downto 96 ), ctrl_dec, mixcol_out( 127 downto 96 ) );
  MC_COLUMN_B : MC_col port map( mixcol_in(  95 downto 64 ), ctrl_dec, mixcol_out(  95 downto 64 ) );
  MC_COLUMN_C : MC_col port map( mixcol_in(  63 downto 32 ), ctrl_dec, mixcol_out(  63 downto 32 ) );
  MC_COLUMN_D : MC_col port map( mixcol_in(  31 downto  0 ), ctrl_dec, mixcol_out(  31 downto  0 ) );
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
	

  ------------------------------------------------------------------------------
  ---- OUTPUT BLOCK ------------------------------------------------------------
  ------------------------------------------------------------------------------

	-- BLK_IDX_SZ + COL_IDX_SZ + MASK_SIZE + DATA_SIZE
  s_mix_col_bus_in <= x"F00000000" & (sbox_reg_out &
                      outB0 & outB1 & outB2 & outB3 &
                      outC0 & outC1 & outC2 & outC3 &
                      outD0 & outD1 & outD2 & outD3)
	s_blk_idx_out <= blk_idx; 
	s_aligned_data <= ( old_mask_reg & column_A & column_B & column_C & column_D ) 
																	when ( wrd_idx( 7 downto 6 )="00" ) 
							else  ( old_mask_reg( 23 downto 0 ) & old_mask_reg( 31 downto 24 ) & column_B & column_C & column_D & column_A ) 
																	when ( wrd_idx( 7 downto 6 )="11" ) 
							else  ( old_mask_reg( 15 downto 0 ) & old_mask_reg( 31 downto 16 ) & column_C & column_D & column_A & column_B ) 
																	when ( wrd_idx( 7 downto 6 )="10" ) 
							else  ( old_mask_reg(  7 downto 0 ) & old_mask_reg( 31 downto  8 ) & column_D & column_A & column_B & column_C )
																	when ( wrd_idx( 7 downto 6 )="01" )
							else  ( others=>'0' );
	s_mcoff_data <= ( "00" & s_aligned_data ) when ( realign = C_ENABLED ) 
						 else ( wrd_idx( 7 downto 6 ) & new_mask_reg & mixcol_in );
	data_out <= ( s_blk_idx_out & wrd_idx( 7 downto 6 ) & new_mask_reg & mixcol_out ) 
												when ( enable_mc=C_ENABLED ) 
         else s_mix_col_bus_in when (enable_mc_in)
				 else ( s_blk_idx_out & s_mcoff_data );
  end arch;
