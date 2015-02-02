library ieee;
	use ieee.std_logic_1164.all;
library WORK;
    use WORK.params.all;

entity enable_countermeasures is
-- blk_reloc / col_reloc / dyn mapping / linear mask
	port(
		clk, rst : in std_logic;
		load : in std_logic;
		rnds : in std_logic_vector( 5 downto 0 ); -- LSW : Countermeasure activation; 3 MSWs : random seed
    key, IV : in std_logic_vector( 79 downto 0 );
		valid : out std_logic;
		rnd_mask_out : out std_logic_vector( 31 downto 0 );
		rnd_map_out : out std_logic_vector( 2 downto 0 );
		rnd_colreloc_out : out std_logic_vector( 2*NUMBER_OF_ROUNDS_INSTANCES-1 downto 0 );
		rnd_blkreloc_out : out std_logic_vector( BLK_IDX_SZ-1 downto 0 );
    rnd_dfa_select : out std_logic_vector( 1 downto 0 );
    enable_bus_noise : out T_ENABLE
    );
	end enable_countermeasures;

architecture arch of enable_countermeasures is
	component PRNG 
		generic( USE_GRAIN_RATHER_THAN_TRIVIUM : boolean := false );
		port(
			clk, rst : in std_logic;
			start : in std_logic;
			key, IV : in std_logic_vector( 79 downto 0 );
			valid :  out std_logic;
			rnd_out : out std_logic_vector( 47 downto 0 )
		);
		end component;
	signal start, s_val : std_logic;
	signal act_mask, act_col_reloc, act_blk_reloc, act_dyn_map, act_bus_noise : std_logic;
	signal enable_mask, enable_col_reloc, enable_blk_reloc, enable_dyn_map, s_enable_bus_noise : T_ENABLE;
	signal s_iv_reg, s_key_reg : std_logic_vector( 79 downto 0 );
	signal s_valid : std_logic_vector( 47 downto 0 ) := ( others=>'0' );
	signal s_rnd_o : std_logic_vector( 47 downto 0 );
begin
	act_mask 			<= rnds( 0 );
	act_dyn_map   <= rnds( 1 );
	act_col_reloc <= rnds( 2 );
	act_blk_reloc <= rnds( 3 );
  act_bus_noise <= rnds( 4 );
	
	ENABLE_PROC : process( clk )
	begin
		if ( clk'event and clk='1' ) then
			if ( rst = RESET_ACTIVE ) then 
				enable_mask      <= C_DISABLED;
				enable_col_reloc <= C_DISABLED;
				enable_blk_reloc <= C_DISABLED;
				enable_dyn_map   <= C_DISABLED;
        s_enable_bus_noise <= C_DISABLED;
			elsif ( load='1' ) then 
			-- elsif ( load='1' or start='1' ) then 
				if ( act_mask='1' ) then enable_mask <= C_ENABLED; 
														else enable_mask <= C_DISABLED; end if;
				if ( act_dyn_map='1' ) then enable_dyn_map <= C_ENABLED; 
														 	 else enable_dyn_map <= C_DISABLED; end if;
				if ( act_col_reloc='1' ) then enable_col_reloc <= C_ENABLED; 
														 		 else enable_col_reloc <= C_DISABLED; end if;
				if ( act_blk_reloc='1' ) then enable_blk_reloc <= C_ENABLED; 
														 		 else enable_blk_reloc <= C_DISABLED; end if;
				if ( act_bus_noise='1' ) then s_enable_bus_noise <= C_ENABLED; 
														 		 else s_enable_bus_noise <= C_DISABLED; end if;
				end if;
			end if; -- clk
		end process ENABLE_PROC;

	process( clk )
	begin
		if ( clk'event and clk='1' ) then
			start <= load;
			end if;
		end process;
	process( clk )
	begin
		if ( clk'event and clk='1' ) then
			if ( rst = RESET_ACTIVE ) then 
				s_valid <= ( others=>'0' );
			elsif ( s_val='1' ) then
				s_valid <= s_valid( 46 downto 0 ) & '1';
				end if;
			end if;
		end process;
	process( clk )
	begin
		if ( clk'event and clk='1' ) then
			if ( rst = RESET_ACTIVE ) then 
				s_iv_reg <= ( others=>'0' );
				s_key_reg <= ( others=>'0' );
			elsif ( load='1' ) then 
				s_iv_reg <= IV;
				s_key_reg <= key;
				end if;
			end if;
		end process;

	RNG : PRNG generic map( true ) 
						 port map(
						 	 clk => clk,
							 rst => rst,
							 start => start, 
							 key => s_key_reg,
							 IV => s_iv_reg,
							 valid => s_val,
							 rnd_out => s_rnd_o
						 	 );
							 
	valid <= s_valid( 47 );
	rnd_mask_out <= s_rnd_o( 31 downto 0 ) when (enable_mask=C_ENABLED) else ( others=>'0' );
	rnd_map_out <= s_rnd_o( 34 downto 32 ) when (enable_dyn_map=C_ENABLED) else ( others=>'0' );
	rnd_colreloc_out <= s_rnd_o( 42 downto 35 ) when (enable_col_reloc=C_ENABLED) else ( others=>'0' );
	rnd_blkreloc_out <= s_rnd_o( 44 downto 43 ) when (enable_blk_reloc=C_ENABLED) else ( others=>'0' );
	rnd_dfa_select <= s_rnd_o( 46 downto 45 ); 
  enable_bus_noise <= s_enable_bus_noise;
	end arch;
