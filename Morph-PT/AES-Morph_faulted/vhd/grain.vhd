--This software is provided 'as-is', without any express or implied warranty.
--In no event will the authors be held liable for any damages arising from the use of this software.

--Permission is granted to anyone to use this software for any purpose,
--excluding commercial applications, and to alter it and redistribute
--it freely except for commercial applications. 
--File:         grain.vhd
--Author:       Richard Stern (rstern01@utopia.poly.edu)
--Organization: Polytechnic University
--------------------------------------------------------
--Description: Grain encryption algorithm
--------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity grain is
	port(	clk, rst, grst	: in std_logic; 
		key	 : in std_logic_vector(79 downto 0);
		IV	 : in std_logic_vector(63 downto 0);
		o_vld	 : out std_logic;
		z	 : out std_logic);
end grain;


architecture do_it of grain is
signal nfsr, lfsr : std_logic_vector(79 downto 0); -- registers
signal lbit, nbit, z_tmp : std_logic; --feedback bit
type statetype is (key_initialize, run);
type Encode is array (0 to 1) of statetype;
type Decode is array (statetype) of std_logic;
signal state_encode : Encode := (key_initialize, run);
signal state_decode : Decode := ('0','1');
signal state : statetype;
signal count : integer;
signal s_vld : std_logic;

begin
	lbit <= lfsr(62) xor lfsr(51) xor lfsr(38) xor lfsr(23) xor lfsr(13) xor lfsr(0);
	--lbit <= lfsr(17) xor lfsr(28) xor lfsr(41) xor lfsr(56) xor lfsr(66) xor lfsr(79);
	nbit <= lfsr(0) xor nfsr(62) xor nfsr(60) xor nfsr(52) xor nfsr(45) xor nfsr(37)
			xor nfsr(33) xor nfsr(28) xor nfsr(21) xor nfsr(14) xor nfsr(9)
			xor nfsr(0) xor (nfsr(63) and nfsr(60)) xor (nfsr(37) and nfsr(33))
			xor (nfsr(15) and nfsr(9)) xor (nfsr(60) and nfsr(52) and nfsr(45))
			xor (nfsr(33) and nfsr(28) and nfsr(21)) xor (nfsr(63) and nfsr(45) and nfsr(28) and nfsr(9))
			xor (nfsr(60) and nfsr(52) and nfsr(37) and nfsr(33)) xor (nfsr(63) and nfsr(60) and nfsr(21) and nfsr(15))
			xor (nfsr(63) and nfsr(60) and nfsr(52) and nfsr(45) and nfsr(37)) xor (nfsr(33) and nfsr(28) and nfsr(21) and nfsr(15) and nfsr(9))
			xor (nfsr(52) and nfsr(45) and nfsr(37) and nfsr(33) and nfsr(28) and nfsr(21));

	z_tmp <= nfsr(1) xor nfsr(2) xor nfsr(4) xor nfsr(10) xor nfsr(31) xor nfsr(43) xor nfsr(56) xor lfsr(25) xor nfsr(63) xor (lfsr(3) and lfsr(64))
		xor (lfsr(46) and lfsr(64)) xor (lfsr(64) and nfsr(63)) xor (lfsr(3) and lfsr(25) and lfsr(46)) xor (lfsr(3) and lfsr(46) and lfsr(64))
		xor (lfsr(3) and lfsr(46) and nfsr(63)) xor (lfsr(25) and lfsr(46) and nfsr(63)) xor (lfsr(46) and lfsr(64) and nfsr(63));
	z <= z_tmp;

--lfsr
process(rst, clk)
begin
if(clk'event and clk='1') then
	if (rst = '1') then
	--on reset key initialization
	  lfsr <= "1111111111111111" & IV;
  elsif (state = key_initialize) then
		lfsr(79 downto 0) <= (z_tmp xor lbit) & lfsr(79 downto 1);
	else
		lfsr(79 downto 0) <= lbit & lfsr(79 downto 1);
	end if;
end if;
end process;

--nfsr
process(rst, clk)
begin
if(clk'event and clk='1') then
	if (rst = '1') then
	--on reset key initialization
	  nfsr <= key;
  elsif (state = key_initialize) then
		nfsr(79 downto 0) <= (z_tmp xor nbit) & nfsr(79 downto 1);
	else
		nfsr(79 downto 0) <= nbit & nfsr(79 downto 1);
	end if;
end if;
end process;

--state machine
process(rst, clk)
begin
if(clk'event and clk='1') then
if ( grst='0' ) then 
	count <= 0;
	s_vld <= '0';
elsif (rst = '1') then
	state <= key_initialize;
	count <= 0;
	s_vld <= '0';
else
	case state is
		when key_initialize =>
			count <= count + 1;
			if (count = 159) then
				state <= run;
				s_vld <= '1';
			end if;
		when others =>
		end case;
	end if;
end if;
end process;

o_vld <= s_vld;
	
end do_it;
