library IEEE;
    use IEEE.std_logic_1164.all;
    use IEEE.numeric_std.all;
library WORK;
    use WORK.params.all;

entity Tower_Matrix is 
	generic (
		MATRIX_SIZE : integer := 4;
		RANDOM_SIZE : integer := 2 -- = log2( MATRIX_SIZE )
		);
	port (
	-- 4 Buses, 24 configs
		clk, rst : in std_logic;
		start, get_new_mask : in std_logic;
		rnd_seed : in std_logic_vector( RANDOM_SIZE-1 downto 0 ); 
		is_busy : out std_logic;
		ctrl_config : out std_logic_vector( MATRIX_SIZE*MATRIX_SIZE-1 downto 0 )
  	); 
  	end Tower_Matrix;

architecture arch of Tower_Matrix is
	-- function get2( rnd : std_logic_vector ) return std_logic_vector( 0 downto 0 ); is
		-- begin 
			-- return rnd( rnd'right to rnd'right );
			-- end function get2;
  component reg
    generic( G_SIZE : integer := 8 ); 
    port (
      din : in std_logic_vector (G_SIZE-1 downto 0);
      dout : out std_logic_vector (G_SIZE-1 downto 0);
      clock, reset : in std_logic );
    end component ;  
	type T_STATE is  ( WARMING_UP, RESET, WAITING, BUSY );
	signal state : T_STATE := WARMING_UP;
	type mask_type is array( 0 to MATRIX_SIZE-1 ) of std_logic_vector( MATRIX_SIZE-1 downto 0 );
	signal current_mask, next_mask : mask_type;
	signal one_mask, flattened_rows : std_logic_vector( MATRIX_SIZE-1 downto 0 );
--	signal flattened_rows_reg : std_logic_vector( MATRIX_SIZE-1 downto 0 );
  signal seed_reg : std_logic_vector( RANDOM_SIZE-1 downto 0 ); 
  signal row_idx : integer range 0 to MATRIX_SIZE := 1;
  signal col_idx : integer range 0 to MATRIX_SIZE-1 := MATRIX_SIZE-1;
  signal zeroes : std_logic_vector( RANDOM_SIZE-1 downto 0 ) := ( others=> '0' ); 
begin
	FLATTEN_PROC : process( next_mask )
		variable temp : std_logic_vector( MATRIX_SIZE-1 downto 0 );
	begin
		temp := ( others=>'0' );
		for ROW in 0 to MATRIX_SIZE-1 loop
			temp := temp or next_mask( ROW );
			end loop; -- for ROW
		flattened_rows <= temp;
		end process FLATTEN_PROC;
	FLATTEN_REG_PROC : process( clk )
	begin
		if ( clk'event and clk='1' ) then
			if ( get_new_mask='1' or rst='1' ) then
				-- flattened_rows_reg <= ( others=>'0' );
			else
				-- flattened_rows_reg <= flattened_rows;
				end if; 
			end if;
		end process FLATTEN_REG_PROC;
		-- FLATTEN_REG : reg generic map( MATRIX_SIZE ) port map( flattened_rows, flattened_rows_reg, clk, get_new_mask );

	-- Prendi il seed
	-- Per ogni riga:
	--		If summary=1 then continue
	-- 		else ( summary=0 )
	-- 			if seed=0 then 
	--				set mask bit [ + update summary]
	--				next row
	--			else 
	--				seed--

	NEXT_MASK_PROC : process( clk )
	begin
		if ( clk'event and clk='1' ) then
			if ( rst=RESET_ACTIVE ) then 
				state <= RESET;
			else
				case ( state ) is
					when WARMING_UP => state <= RESET;
					when RESET 	 => 
          		if ( start='1' ) then 
								state <= BUSY; -- Next FSM state
								end if;
							for I in 0 to MATRIX_SIZE-1 loop
								next_mask( I ) <= ( others=>'0' );
								end loop;
          		col_idx <= MATRIX_SIZE-1;
          		row_idx <= 0;
          		seed_reg <= rnd_seed;
          		one_mask( MATRIX_SIZE-1 ) <= '1';
          		one_mask( MATRIX_SIZE-2 downto 0 ) <= ( others => '0' );
					when BUSY  	 => -- busy generating next matrix
        			if ( row_idx<MATRIX_SIZE ) then
          			if ( flattened_rows( col_idx )='1' ) then -- column already mapped
            			if ( col_idx=0 ) then
										col_idx <= MATRIX_SIZE-1;
									else
										col_idx <= col_idx-1;
										end if; -- col_idx
									one_mask <= one_mask( 0 ) & one_mask( MATRIX_SIZE-1 downto 1 );
          			else -- column still to map
            			if ( seed_reg=zeroes ) then -- Map and generate next row
              			next_mask( row_idx ) <= one_mask;
										seed_reg <= rnd_seed;
              			row_idx <=  row_idx + 1;
										col_idx <= MATRIX_SIZE-1;
              			one_mask( MATRIX_SIZE-1 ) <= '1';
              			one_mask( MATRIX_SIZE-2 downto 0 ) <= ( others => '0' );
            			else -- Decrease counter and go next column
              			one_mask <= one_mask( 0 ) & one_mask( MATRIX_SIZE-1 downto 1 );
            				if ( col_idx=0 ) then 
											col_idx <= MATRIX_SIZE-1;
										else
											col_idx <= col_idx-1;
											end if; -- col_idx
              			seed_reg <= std_logic_vector( unsigned( seed_reg ) - 1 );
              			end if; -- seed_reg
            			end if; -- flattened_rows
        			else -- row_idx == MATRIX_SIZE
          			state <= WAITING; -- Go waiting
          			end if; -- if row_idx <> MATRIX_SIZE
					when WAITING => -- waiting to provide next matrix
        			if ( get_new_mask='1' ) then
          			state <= BUSY; -- Next FSM state
								for I in 0 to MATRIX_SIZE-1 loop
									next_mask( I ) <= ( others=>'0' );
									end loop;
          			col_idx <= MATRIX_SIZE-1;
          			row_idx <= 0;
          			seed_reg <= rnd_seed;
          			one_mask( MATRIX_SIZE-1 ) <= '1';
          			one_mask( MATRIX_SIZE-2 downto 0 ) <= ( others => '0' );
          			end if; 
					end case;
				end if;
			end if;
		end process NEXT_MASK_PROC;	

	NEW_MASK_PROC : process( clk )
	begin
		if ( clk'event and clk='1' ) then
			if ( state = RESET ) then
				for I in 0 to MATRIX_SIZE-1 loop
					-- current_mask( I ) <= ( others=>'0' );
					for J in 0 to MATRIX_SIZE-1 loop
						if ( I=MATRIX_SIZE-1-J ) then
							current_mask( I )( J ) <= '1';
						else
							current_mask( I )( J ) <= '0';
							end if;
						end loop;
					end loop;
			elsif ( get_new_mask='1' and state=WAITING ) then
				current_mask <= next_mask;
				end if; 
			end if;
		end process NEW_MASK_PROC;
		
  OUTPUT : for row in 0 to MATRIX_SIZE-1 generate 
    ctrl_config( (row+1)*MATRIX_SIZE-1 downto row*MATRIX_SIZE ) <= current_mask( MATRIX_SIZE-row-1 );
    end generate OUTPUT;
	is_busy <= '1' when ( state=BUSY ) else '0';

	end arch;
