-- Library Declaration
library IEEE;
  use IEEE.std_logic_1164.all;
library WORK;
  use WORK.params.all;

-- Component Declaration
entity datacell_parity is port (
  clk: in std_logic;
  rst : in std_logic; 
  in_H : in std_logic_vector (7 downto 0);
  key_data : in std_logic_vector(7 downto 0);
  in_V : in std_logic;
  old_pt : in std_logic;
  enable_H_in : in T_ENABLE;
  end_ciph : in std_logic;
  ctrl_dec : in T_ENCDEC;
  init_cipher : in std_logic;
  dfa_mode : in T_DFA_MODE;
  b_out : out std_logic);
  end datacell_parity;

-- Architecture of the Component
architecture a_dc_parity of datacell_parity is
  component reg_B
    generic( G_SIZE : integer := 1 ); 
    port (
      din : in std_logic_vector (G_SIZE-1 downto 0);
      dout : out std_logic_vector (G_SIZE-1 downto 0);
      clock, reset : in std_logic );
    end component ;
    component Sbox_Parity port (
      sbox_in : in std_logic_vector(7 downto 0);
      ctrl_dec : in T_ENCDEC;
      error : out std_logic     );
    end component;
  signal data : std_logic_vector ( 7 downto 0 );
  signal parity_in, parity_data_in, parity_sbox, parity_data : std_logic;
  signal parity_in_reg, parity_out_reg : std_logic_vector(0 downto 0);
  signal parity_key : std_logic;
  signal data_with_key : std_logic_vector(7 downto 0);
  signal s_dfa_mode : T_DFA_MODE;
begin
  s_dfa_mode <= dfa_mode;
  data <= in_H;
  data_with_key <= data xor key_data;
  sb_pt : Sbox_Parity port map( data_with_key, ctrl_dec, parity_sbox );

  parity_key <= key_data(7) xor key_data(6) xor key_data(5) xor key_data(4) xor 
                key_data(3) xor key_data(2) xor key_data(1) xor key_data(0);

  parity_data_in <= data(7) xor data(6) xor data(5) xor data(4) xor 
                data(3) xor data(2) xor data(1) xor data(0) xor parity_key;
  
  parity_in <= parity_data_in when (init_cipher = '1') else 
              (old_pt xor parity_key) when (enable_H_in = C_ENABLED) else
              --parity_data_in when (enable_H_in = C_ENABLED and s_dfa_mode = FULL_RED) else
              in_V;
  parity_data <= (parity_data_in xor parity_in) xor parity_sbox;
  parity_in_reg(0) <= parity_in when (enable_H_in = C_ENABLED and end_ciph = '1') else 
                      parity_data when (enable_H_in = C_ENABLED) else
                      in_V;
  I_REG : reg_B generic map( 1 ) 
              port map( parity_in_reg, parity_out_reg,
                        clk, rst );
  b_out <= parity_out_reg(0);
  end a_dc_parity;