-- Library Declaration
library IEEE;
  use IEEE.std_logic_1164.all;
library WORK;
  use WORK.params.all;

-- Component Declaration
entity datacell_parity is port (
  -- A = Leftmost column, B = Middleleft column
  clock, reset : in std_logic; 
  in_H : in std_logic_vector (7 downto 0);
  in_V : in std_logic;
  old_pt : in std_logic;
  enable_H_in : in T_ENABLE;
  ctrl_dec : in T_ENCDEC;
  init_cipher : in std_logic;
  b_out : out std_logic;
  end datacell;

-- Architecture of the Component
architecture a_dc of datacell_parity is
  component reg_B
    generic( G_SIZE : integer := 1 ); 
    port (
      din : in std_logic_vector (G_SIZE-1 downto 0);
      dout : out std_logic_vector (G_SIZE-1 downto 0);
      clock, reset : in std_logic );
    end component ;
  signal data : std_logic_vector ( 7 downto 0 );
  signal parity_in, parity_data_in, parity_sbox, parity_data : std_logic;
  signal 
begin
  data <= in_H;
  sb_pt : sbox_parity port map( data, ctrl_dec, parity_sbox );
  parity_data_in <= data(7) xor data(6) xor data(5) xordata(4) xor 
                data(3) xor data(2) xor data(1) xor data(0);
  parity_in <= parity_data_in when (init_cipher = '1') else 
              old_pt when (enable_H_in = '1') else
              in_V;
  parity_data <= (data(7) xor data(6) xor data(5) xordata(4) xor 
                data(3) xor data(2) xor data(1) xor data(0) xor parity_in) xor parity_sbox;
  I_REG : reg_B generic map( 1 ) 
              port map( parity_data when (enable_H_in) else in_V, b_out,
                        clock, reset );
 
  end a_dc;