-- Library Declaration
library IEEE;
  use IEEE.std_logic_1164.all;
library WORK;
  use WORK.params.all;

-- Component Declaration
entity MC_col_parity is port (
  din : in std_logic_vector (31 downto 0);
  pdin : in std_logic_vector (3 downto 0);
  ctrl_dec : in T_ENCDEC;
  dout : out std_logic_vector (3 downto 0) ) ;
  end MC_col_parity;

-- Architecture of the Component
architecture a_MC_col_parity of MC_col_parity is
  component PreMcRot_parity_B 
    generic( G_ROW : integer range 0 to 3 ); 
    port ( 
      in_0, in_1, in_2, in_3 : in std_logic_vector (7 downto 0);
      pin_0, pin_1, pin_2, pin_3 : in std_logic;
      out_0, out_1, out_2, out_3 : out std_logic_vector (7 downto 0) ;
      pout_0, pout_1, pout_2, pout_3 : out std_logic );
    end component;
  
  signal Value_PostRot_0, Value_PostRot_1, Value_PostRot_2, Value_PostRot_3 : std_logic_vector (31 downto 0);
  signal pValue_PostRot_0, pValue_PostRot_1, pValue_PostRot_2, pValue_PostRot_3 : std_logic_vector (3 downto 0);
  signal MC_out : std_logic_vector (3 downto 0);
begin
  Rot0: PreMcRot_parity_B generic map( 0 ) 
        port map( din( 31 downto 24 ), din( 23 downto 16 ),
                  din( 15 downto 8 ), din( 7 downto 0 ),
                  pdin(3), pdin(2), pdin(1), pdin(0),
                  Value_PostRot_0( 31 downto 24 ), Value_PostRot_0( 23 downto 16 ),
                  Value_PostRot_0( 15 downto 8 ), Value_PostRot_0( 7 downto 0 ),
                  pValue_PostRot_0(3), pValue_PostRot_0(2),
                  pValue_PostRot_0(1), pValue_PostRot_0(0) );

  Rot1: PreMcRot_parity_B generic map( 1 ) 
        port map( din( 31 downto 24 ), din( 23 downto 16 ),
                  din( 15 downto 8 ), din( 7 downto 0 ),
                  pdin(3), pdin(2), pdin(1), pdin(0),
                  Value_PostRot_1( 31 downto 24 ), Value_PostRot_1( 23 downto 16 ),
                  Value_PostRot_1( 15 downto 8 ), Value_PostRot_1( 7 downto 0 ),
                  pValue_PostRot_1(3), pValue_PostRot_1(2),
                  pValue_PostRot_1(1), pValue_PostRot_1(0) );

  Rot2: PreMcRot_parity_B generic map( 2 ) 
        port map( din( 31 downto 24 ), din( 23 downto 16 ),
                  din( 15 downto 8 ), din( 7 downto 0 ),
                  pdin(3), pdin(2), pdin(1), pdin(0),
                  Value_PostRot_2( 31 downto 24 ), Value_PostRot_2( 23 downto 16 ),
                  Value_PostRot_2( 15 downto 8 ), Value_PostRot_2( 7 downto 0 ),
                  pValue_PostRot_2(3), pValue_PostRot_2(2),
                  pValue_PostRot_2(1), pValue_PostRot_2(0) );

  Rot3: PreMcRot_parity_B generic map( 3 ) 
        port map( din( 31 downto 24 ), din( 23 downto 16 ),
                  din( 15 downto 8 ), din( 7 downto 0 ),
                  pdin(3), pdin(2), pdin(1), pdin(0),
                  Value_PostRot_3( 31 downto 24 ), Value_PostRot_3( 23 downto 16 ),
                  Value_PostRot_3( 15 downto 8 ), Value_PostRot_3( 7 downto 0 ), 
                  pValue_PostRot_3(3), pValue_PostRot_3(2),
                  pValue_PostRot_3(1), pValue_PostRot_3(0) );
                  
  MC_out(3) <=  (pValue_PostRot_0(3) xor pValue_PostRot_0(1) xor pValue_PostRot_0(0) xor
                Value_PostRot_0(31) xor Value_PostRot_0(23)) when (ctrl_dec = C_ENC) 
                else
                (pValue_PostRot_0(3) xor pValue_PostRot_0(2) xor pValue_PostRot_0(1) xor
                Value_PostRot_0(29) xor Value_PostRot_0(31) xor Value_PostRot_0(21) xor 
                Value_PostRot_0(22) xor Value_PostRot_0(13) xor Value_PostRot_0(14) xor
                Value_PostRot_0(5) xor Value_PostRot_0(6) xor Value_PostRot_0(7));

  MC_out(2) <=  (pValue_PostRot_1(3) xor pValue_PostRot_1(1) xor pValue_PostRot_1(0) xor
                Value_PostRot_1(31) xor Value_PostRot_1(23)) when (ctrl_dec = C_ENC) 
                else
                (pValue_PostRot_1(3) xor pValue_PostRot_1(2) xor pValue_PostRot_1(1) xor
                Value_PostRot_1(29) xor Value_PostRot_1(31) xor Value_PostRot_1(21) xor 
                Value_PostRot_1(22) xor Value_PostRot_1(13) xor Value_PostRot_1(14) xor
                Value_PostRot_1(5) xor Value_PostRot_1(6) xor Value_PostRot_1(7));
  
  MC_out(1) <=  (pValue_PostRot_2(3) xor pValue_PostRot_2(1) xor pValue_PostRot_2(0) xor
                Value_PostRot_2(31) xor Value_PostRot_2(23)) when (ctrl_dec = C_ENC) 
                else
                (pValue_PostRot_2(3) xor pValue_PostRot_2(2) xor pValue_PostRot_2(1) xor
                Value_PostRot_2(29) xor Value_PostRot_2(31) xor Value_PostRot_2(21) xor 
                Value_PostRot_2(22) xor Value_PostRot_2(13) xor Value_PostRot_2(14) xor
                Value_PostRot_2(5) xor Value_PostRot_2(6) xor Value_PostRot_2(7));                

  MC_out(0) <=  (pValue_PostRot_3(3) xor pValue_PostRot_3(1) xor pValue_PostRot_3(0) xor
                Value_PostRot_3(31) xor Value_PostRot_3(23)) when (ctrl_dec = C_ENC) 
                else
                (pValue_PostRot_3(3) xor pValue_PostRot_3(2) xor pValue_PostRot_3(1) xor
                Value_PostRot_3(29) xor Value_PostRot_3(31) xor Value_PostRot_3(21) xor 
                Value_PostRot_3(22) xor Value_PostRot_3(13) xor Value_PostRot_3(14) xor
                Value_PostRot_3(5) xor Value_PostRot_3(6) xor Value_PostRot_3(7));
                
  dout <= MC_out;
  end a_MC_col_parity;
