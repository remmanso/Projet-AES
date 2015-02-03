library IEEE;
    use IEEE.std_logic_1164.all;
library WORK;
    use WORK.params.all;

-- First row for the MixCol multiplication: 
--   2 3 1 1 (enc): 3=2+1 
--   e b d 9 (dec): ebd9=8888+6351=8888+4040+2311 [248,28,48,8]
entity mixcolumn0 is port (
    in_0, in_1, in_2, in_3 : in std_logic_vector (7 downto 0);
    ctrl_dec : in T_ENCDEC;
    b_out : out std_logic_vector (7 downto 0) );
    end mixcolumn0;

architecture a_mixcolumn0 of mixcolumn0 is
  component xtime_B port (
    b_in : in std_logic_vector (7 downto 0);
    b_out : out std_logic_vector (7 downto 0) ) ;
    end component;
  component x2time_B port (
    b_in : in std_logic_vector (7 downto 0);
    b_out : out std_logic_vector (7 downto 0) ) ;
    end component;
  component x4time_B port (
    b_in : in std_logic_vector (7 downto 0);
    b_out : out std_logic_vector (7 downto 0) ) ;
    end component;
  signal in_01, in_23, in_0123, in_02, in_123, in_01x2, in_02x4, in_0123x8, in_x48, out_enc, out_dec : std_logic_vector (7 downto 0);
begin
  in_01 <= in_0 xor in_1;  
  in_23 <= in_2 xor in_3;  
  in_123 <= in_23 xor in_1;    
  xt  : xtime_B  port map (in_01, in_01x2);
  out_enc <= in_01x2 xor in_123;

  gen000e : if ( C_INCLUDE_DECODING_LOGIC=false ) generate
    b_out <= out_enc;  
    end generate;
  gen000d : if ( C_INCLUDE_DECODING_LOGIC ) generate
    in_02 <= in_0 xor in_2;  
    in_0123 <= in_01 xor in_23;      
    x2t : x2time_B port map (in_02, in_02x4);
    x4t : x4time_B port map (in_0123, in_0123x8);
    in_x48 <= in_02x4 xor in_0123x8;
    out_dec <= out_enc xor in_x48;
    b_out <= out_enc when (ctrl_dec = C_ENC) else out_dec;  
    end generate;

  end a_mixcolumn0;
