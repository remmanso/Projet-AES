--This software is provided 'as-is', without any express or implied warranty.
--In no event will the authors be held liable for any damages arising from the use of this software.

--Permission is granted to anyone to use this software for any purpose,
--excluding commercial applications, and to alter it and redistribute
--it freely except for commercial applications. 
--File:         trivium.vhd
--Author:       Richard Stern (rstern01@utopia.poly.edu)
--Organization: Polytechnic University
--------------------------------------------------------
--Description: Trivium encryption algorithm
--------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity trivium is
	port(	clk, rst	: in std_logic; 
		key	 : in std_logic_vector(79 downto 0);
		IV	 : in std_logic_vector(79 downto 0);
		o_vld	 : out std_logic;
		z	 : out std_logic);
end trivium;


architecture do_it of trivium is

type state_type is (setup, run);
signal state : state_type;
signal s_reg : std_logic_vector(288 downto 1);
signal s: std_logic_vector(288 downto 1);
signal count : integer;
begin

	z <= s_reg(66) xor s_reg(93) xor s_reg(162) xor s_reg(177) xor s_reg(243) xor s_reg(288);	

	s(93 downto 1) <= s_reg(92 downto 1) & (s_reg(243) xor s_reg(288) xor (s_reg(286) and s_reg(287)) xor s_reg(69));
	s(177 downto 94) <= s_reg(176 downto 94) & (s_reg(66) xor s_reg(93) xor (s_reg(91) and s_reg(92)) xor s_reg(171));
	s(288 downto 178) <= s_reg(287 downto 178) & (s_reg(162) xor s_reg(177) xor (s_reg(175) and s_reg(176)) xor s_reg(264));

--s_reg
process(clk)
begin
  if ( clk'event and clk='1' ) then
    if( rst='1' ) then
      s_reg(80 downto 1) <= key(79 downto 0);
      s_reg(93 downto 81) <= (others => '0');
      s_reg(173 downto 94) <= IV(79 downto 0);
      s_reg(285 downto 174) <= (others => '0');
      s_reg(288 downto 286) <= "111";
    else
      s_reg <= s;
      end if; -- rst
    end if; -- clk
  end process;

--state machine
process(rst, clk)
begin
  if(clk'event and clk='1') then
    if (rst = '1') then
      state <= setup;
      count <= 0;
      o_vld <= '0';
    else 
      case state is
        when setup =>
          if(count = 1151) then
            state <= run;
            o_vld <= '1';
          else
            count <= count + 1;
            state <= setup;
            o_vld <= '0';
          end if;
        when run =>
        end case;
      end if; -- rst
    end if; -- clk
  end process;
	
end do_it;