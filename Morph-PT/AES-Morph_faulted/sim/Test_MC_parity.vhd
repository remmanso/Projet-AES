library IEEE;
	use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;
--library WORK;
-- use  WORK.globals.all;
--library lib_aes_core;

-- Component Declaration
entity A_test_MC_parity is

end A_test_MC_parity;

-- Architecture of the Component
architecture exp of A_test_MC_parity is
	constant ckht : time := 5 ns;
	constant ckt : time := 2*ckht;
	Component MC_col_parity is
		port (
			din : in std_logic_vector (31 downto 0);
			pdin : in std_logic_vector (3 downto 0);
			ctrl_dec : in std_logic_vector(0 downto 0);
			dout : out std_logic_vector (3 downto 0) ) ;
	end Component;
	component reg_B 
	    generic( G_SIZE : integer := 4 ); 
	    port (
	      din : in std_logic_vector (G_SIZE-1 downto 0);
	      dout : out std_logic_vector (G_SIZE-1 downto 0);
	      clock, reset : in std_logic );
	end component;
	signal ck, rst : std_logic;
	signal c_dec : std_logic_vector(0 downto 0);
	signal mix_col_in, mix_col_in_reg : std_logic_vector(31 downto 0);
	signal mix_col_in_pt, mix_col_in_reg_pt, mix_col_out_pt : std_logic_vector(3 downto 0);

begin
	clk_pr : process
	begin   
  	ck <= '1';
  	loop
    	wait for ckht;
    	ck <= not ck;
    	end loop;
  	end process;

  

  	rst <= '0', '1' after 15 * ckt;
  	c_dec <= "0";

  	DATA_PROC : process
  	begin
  		mix_col_in_reg <= (others => '0');
  		mix_col_in_reg_pt <= (others => '0');
  		wait for 25*ckt;

	  	mix_col_in_reg <= x"B546C6BF"; 	-- 10110101 01000110 11000110 10111111 
	  						  -- mix_out = 11000010 11010111 10111110 00100001
	  	mix_col_in_reg_pt <= "1101";
	  	-- mix_col_out_pt = "1000"

	  	wait for 2*ckt;
	  	mix_col_in_reg <= x"6B58CEA5"; 	-- 01101011 01011000 11001110 10100101 
	  						  -- mix_out = 01010101 00110111 01000000 01111010
	  	mix_col_in_reg_pt <= "1110";
	  	-- mix_col_out_pt = "0111"
	  	wait for 2*ckt;
	  	mix_col_in_reg <= x"BDFE8E2C"; 	-- 10111101 11111110 10001110 00101100 
	  						  -- mix_out = 11011010 11111111 00110000 11110100
	  	mix_col_in_reg_pt <= "0101";
	  	-- mix_col_out_pt = "1001"
	  	wait for 2*ckt;
	  	mix_col_in_reg <= x"60532E93"; 	-- 01100000 01010011 00101110 10010011 
	  						  -- mix_out = 10001000 00100111 11000001 11100000
	  	mix_col_in_reg_pt <= "0000";
	  	-- mix_col_out_pt = "0011"
	  	wait for 2*ckt;
	end process DATA_PROC;

  	REG_DATA : reg_B generic map (G_SIZE => 32)
  		port map (
  			din => mix_col_in_reg,
  			dout => mix_col_in,
  			clock => ck,
  			reset => rst
  		);

  	REG_PT : reg_B generic map (G_SIZE => 4)
  		port map (
  			din => mix_col_in_reg_pt,
  			dout => mix_col_in_pt,
  			clock => ck,
  			reset => rst
  		);

  	MC_COL : MC_col_parity
  		port map (
  			din => mix_col_in,
  			pdin => mix_col_in_pt,
  			ctrl_dec => c_dec,
  			dout => mix_col_out_pt
  		);

end exp;