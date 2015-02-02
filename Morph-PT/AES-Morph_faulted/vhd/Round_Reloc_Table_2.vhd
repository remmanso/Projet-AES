library IEEE;
    use IEEE.std_logic_1164.all;
library WORK;
    use WORK.params.all;

entity Round_Reloc_Table is
	-- 4 Buses, 24 configs
	generic (
		MATRIX_SIZE : integer := 4;
		RANDOM_SIZE : integer := 2 -- = log2( MATRIX_SIZE ) -- to be compliant to tower_matrix
		);
	port (
	-- 4 Buses, 24 configs -- number depends on FACT( MATRIX_SIZE )
		clk, rst : in std_logic;
		start, get_new_mask : in std_logic;
		rnd_seed : in std_logic_vector( RANDOM_SIZE-1 downto 0 ); 
		is_busy : out std_logic;
		ctrl_config : out std_logic_vector( MATRIX_SIZE*MATRIX_SIZE-1 downto 0 )
  	); 
  	end Round_Reloc_Table;

architecture arch of Round_Reloc_Table is
	signal s_ctrl_config : std_logic_vector( MATRIX_SIZE*MATRIX_SIZE-1 downto 0 );
	signal s_rnd_line : std_logic_vector( 4 downto 0 ); -- = Log2( MATRIX_SIZE ! )
	signal s_is_busy : std_logic;
begin
	RND_IN_PROC : process( clk )
	begin
		if ( clk'event and clk='1' ) then
			if ( rst=RESET_ACTIVE ) then
				s_rnd_line <= ( others=>'0' );
			elsif ( start='1' ) then
			   -- x5 + x2 + 1 => x5 = x2 + 1, x6 = x3 + x
				s_rnd_line <= ( s_rnd_line( 4-RANDOM_SIZE downto 0 ) & rnd_seed ) 
									xor ( '0' & s_rnd_line( 4 downto 4-RANDOM_SIZE+1 ) 
									      & s_rnd_line( 4 downto 4-RANDOM_SIZE+1 ) );
				end if; -- reset
			end if; -- clock
		end process RND_IN_PROC;
		
	STATE_PROC : process( clk )
	begin
		if ( clk'event and clk='1' ) then
			if ( rst=RESET_ACTIVE ) then
				s_is_busy <= '1';
			elsif ( start='1' ) then
				s_is_busy <= '0';
				end if; -- reset
			end if; -- clock
		end process STATE_PROC;

	SELECT_LINE_PROC : process( s_rnd_line )
	begin
		case ( s_rnd_line ) is
			when "00000" => s_ctrl_config <= "1000010000100001";
			when "00001" => s_ctrl_config <= "1000010000010010";
			when "00010" => s_ctrl_config <= "1000001001000001";
			when "00011" => s_ctrl_config <= "1000001000010100";
			when "00100" => s_ctrl_config <= "1000000101000010";
			when "00101" => s_ctrl_config <= "1000000100100100";
			when "00110" => s_ctrl_config <= "0100100000100001";
			when "00111" => s_ctrl_config <= "0100100000010010";
			when "01000" => s_ctrl_config <= "0100001010000001";
			when "01001" => s_ctrl_config <= "0100001000011000";
			when "01010" => s_ctrl_config <= "0100000110000010";
			when "01011" => s_ctrl_config <= "0100000100101000";
			when "01100" => s_ctrl_config <= "0010100001000001";
			when "01101" => s_ctrl_config <= "0010100000010100";
			when "01110" => s_ctrl_config <= "0010010010000001";
			when "01111" => s_ctrl_config <= "0010010000011000";
			when "10000" => s_ctrl_config <= "0010000110000100";
			when "10001" => s_ctrl_config <= "0010000101001000";
			when "10010" => s_ctrl_config <= "0001100001000010";
			when "10011" => s_ctrl_config <= "0001100000100100";
			when "10100" => s_ctrl_config <= "0001010010000010";
			when "10101" => s_ctrl_config <= "0001010000101000";
			when "10110" => s_ctrl_config <= "0001001010000100";
			when "10111" => s_ctrl_config <= "0001001001001000";
			-- Random lines selected for inputs >= 24
			when "11000" => s_ctrl_config <= "0100100000100001";
			when "11001" => s_ctrl_config <= "0100100000010010";
			when "11010" => s_ctrl_config <= "0100001010000001";
			when "11011" => s_ctrl_config <= "0100001000011000";
			when "11100" => s_ctrl_config <= "0100000110000010";
			when "11101" => s_ctrl_config <= "0100000100101000";
			when "11110" => s_ctrl_config <= "0010100001000001";
			when "11111" => s_ctrl_config <= "0010100000010100";
			when others => null;
			end case;
		end process SELECT_LINE_PROC;
		
	OUT_PROC : process( clk )
	begin
		if ( clk'event and clk='1' ) then
			if ( rst=RESET_ACTIVE or s_is_busy='1' ) then
				ctrl_config <= "1000010000100001";
			elsif ( get_new_mask='1' ) then
				ctrl_config <= s_ctrl_config;
				end if; -- reset
			end if; -- clock
		end process OUT_PROC;
	
	-- 20121130:
	-- ctrl_config <= s_ctrl_config when ( s_is_busy='0' ) else "1000010000100001";
	is_busy <= s_is_busy;

	end arch;
