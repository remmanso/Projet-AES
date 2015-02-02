------------------------------------------------------
------------------------------------------------------
--##################################################--
--#                                                #--
--#     File Authors:                              #--
--#                     Prada Marco                #--
--#                     Rossi Riccardo             #--
--#                                                #--
--#     Component name:                            #--
--#                     Sbox Parity Bit            #--
--#                                                #--
--#     Thesis name:                               #--
--#                                                #--
--#                                                #--
--##################################################--
------------------------------------------------------
------------------------------------------------------

library IEEE;
    use IEEE.std_logic_1164.all;
library WORK;
  use WORK.params.all;

entity sbox_parity is port(
    sbox_in : in std_logic_vector(7 downto 0);
    ctrl_dec : in T_ENCDEC;
    error : out std_logic     );
    end sbox_parity;

architecture a_sbox_parity of sbox_parity is
    signal parity_bit_sched, parity_bit_sched_cod, parity_bit_sched_dec : std_logic;
begin
    process (sbox_in)
    begin
    case sbox_in is
        when "00000000" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '1';
        when "00000001" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '0';
        when "00000010" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '0';
        when "00000011" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '1';
        when "00000100" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '0';
        when "00000101" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '0';
        when "00000110" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '0';
        when "00000111" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '1';
        when "00001000" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '1';
        when "00001001" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '1';
        when "00001010" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '0';
        when "00001011" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '1';
        when "00001100" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '0';
        when "00001101" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '0';
        when "00001110" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '0';
        when "00001111" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '1';
        --
        when "00010000" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '1';
        when "00010001" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '1';
        when "00010010" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '0';
        when "00010011" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '0';
        when "00010100" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '1';
        when "00010101" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '1';
        when "00010110" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '0';
        when "00010111" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '0';
        when "00011000" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '1';
        when "00011001" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '0';
        when "00011010" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '1';
        when "00011011" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '0';
        when "00011100" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '1';
        when "00011101" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '0';
        when "00011110" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '1';
        when "00011111" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '1';
        --
        when "00100000" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '1';
        when "00100001" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '0';
        when "00100010" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '1';
        when "00100011" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '1';
        when "00100100" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '0';
        when "00100101" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '1';
        when "00100110" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '1';
        when "00100111" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '1';
        when "00101000" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '0';
        when "00101001" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '1';
        when "00101010" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '0';
        when "00101011" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '1';
        when "00101100" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '0';
        when "00101101" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '0';
        when "00101110" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '0';
        when "00101111" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '0';
        --
        when "00110000" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '1';
        when "00110001" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '0';
        when "00110010" => parity_bit_sched_cod <= '1';  parity_bit_sched_dec <= '1';
        when "00110011" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '0';
        when "00110100" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '0';
        when "00110101" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '1';
        when "00110110" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '0';
        when "00110111" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '0';
        when "00111000" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '1';
        when "00111001" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '1';
        when "00111010" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '1';
        when "00111011" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '1';
        when "00111100" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '1';
        when "00111101" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '0';
        when "00111110" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '0';
        when "00111111" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '1';
        --
        when "01000000" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '0';
        when "01000001" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '1';
        when "01000010" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '0';
        when "01000011" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '1';
        when "01000100" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '1';
        when "01000101" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '1';
        when "01000110" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '1';
        when "01000111" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '1';
        when "01001000" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '0';
        when "01001001" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '1';
        when "01001010" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '0';
        when "01001011" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '0';
        when "01001100" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '1';
        when "01001101" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '0';
        when "01001110" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '1';
        when "01001111" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '1';
        --
        when "01010000" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '0';
        when "01010001" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '1';
        when "01010010" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '0';
        when "01010011" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '0';
        when "01010100" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '1';
        when "01010101" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '0';
        when "01010110" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '1';
        when "01010111" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '1';
        when "01011000" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '1';
        when "01011001" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '1';
        when "01011010" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '1';
        when "01011011" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '1';
        when "01011100" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '1';
        when "01011101" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '0';
        when "01011110" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '1';
        when "01011111" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '0';
        --
        when "01100000" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '0';
        when "01100001" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '0';
        when "01100010" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '1';
        when "01100011" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '0';
        when "01100100" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '1';
        when "01100101" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '1';
        when "01100110" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '1';
        when "01100111" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '0';
        when "01101000" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '1';
        when "01101001" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '0';
        when "01101010" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '1';
        when "01101011" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '0';
        when "01101100" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '0';
        when "01101101" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '1';
        when "01101110" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '1';
        when "01101111" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '0';
        --
        when "01110000" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '1';
        when "01110001" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '1';
        when "01110010" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '0';
        when "01110011" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '1';
        when "01110100" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '0';
        when "01110101" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '0';
        when "01110110" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '0';
        when "01110111" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '1';
        when "01111000" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '1';
        when "01111001" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '0';
        when "01111010" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '0';
        when "01111011" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '0';
        when "01111100" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '1';
        when "01111101" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '1';
        when "01111110" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '1';
        when "01111111" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '1';
        --
        when "10000000" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '0';
        when "10000001" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '1';
        when "10000010" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '0';
        when "10000011" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '0';
        when "10000100" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '1';
        when "10000101" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '1';
        when "10000110" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '1';
        when "10000111" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '1';
        when "10001000" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '1';
        when "10001001" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '1';
        when "10001010" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '0';
        when "10001011" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '1';
        when "10001100" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '0';
        when "10001101" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '0';
        when "10001110" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '1';
        when "10001111" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '1';
        --
        when "10010000" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '0';
        when "10010001" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '0';
        when "10010010" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '0';
        when "10010011" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '0';
        when "10010100" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '0';
        when "10010101" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '1';
        when "10010110" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '0';
        when "10010111" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '1';
        when "10011000" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '0';
        when "10011001" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '0';
        when "10011010" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '1';
        when "10011011" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '0';
        when "10011100" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '1';
        when "10011101" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '1';
        when "10011110" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '1';
        when "10011111" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '1';
        --
        when "10100000" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '0';
        when "10100001" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '1';
        when "10100010" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '1';
        when "10100011" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '0';
        when "10100100" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '0';
        when "10100101" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '1';
        when "10100110" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '0';
        when "10100111" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '1';
        when "10101000" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '0';
        when "10101001" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '0';
        when "10101010" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '1';
        when "10101011" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '1';
        when "10101100" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '0';
        when "10101101" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '0';
        when "10101110" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '0';
        when "10101111" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '0';
        --
        when "10110000" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '0';
        when "10110001" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '0';
        when "10110010" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '1';
        when "10110011" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '0';
        when "10110100" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '0';
        when "10110101" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '0';
        when "10110110" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '1';
        when "10110111" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '1';
        when "10111000" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '0';
        when "10111001" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '0';
        when "10111010" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '0';
        when "10111011" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '1';
        when "10111100" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '0';
        when "10111101" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '1';
        when "10111110" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '0';
        when "10111111" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '1';
        --
        when "11000000" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '1';
        when "11000001" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '0';
        when "11000010" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '1';
        when "11000011" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '0';
        when "11000100" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '0';
        when "11000101" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '1';
        when "11000110" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '1';
        when "11000111" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '1';
        when "11001000" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '0';
        when "11001001" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '0';
        when "11001010" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '1';
        when "11001011" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '0';
        when "11001100" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '0';
        when "11001101" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '1';
        when "11001110" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '1';
        when "11001111" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '0';
        --
        when "11010000" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '0';
        when "11010001" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '1';
        when "11010010" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '1';
        when "11010011" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '0';
        when "11010100" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '1';
        when "11010101" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '1';
        when "11010110" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '1';
        when "11010111" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '1';
        when "11011000" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '0';
        when "11011001" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '1';
        when "11011010" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '1';
        when "11011011" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '0';
        when "11011100" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '0';
        when "11011101" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '0';
        when "11011110" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '0';
        when "11011111" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '1';
        --
        when "11100000" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '0';
        when "11100001" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '1';
        when "11100010" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '1';
        when "11100011" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '0';
        when "11100100" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '1';
        when "11100101" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '1';
        when "11100110" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '0';
        when "11100111" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '1';
        when "11101000" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '1';
        when "11101001" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '0';
        when "11101010" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '0';
        when "11101011" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '0';
        when "11101100" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '1';
        when "11101101" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '0';
        when "11101110" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '0';
        when "11101111" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '1';
        --
        when "11110000" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '0';
        when "11110001" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '0';
        when "11110010" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '1';
        when "11110011" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '0';
        when "11110100" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '1';
        when "11110101" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '0';
        when "11110110" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '1';
        when "11110111" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '1';
        when "11111000" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '0';
        when "11111001" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '0';
        when "11111010" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '0';
        when "11111011" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '0';
        when "11111100" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '0';
        when "11111101" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '0';
        when "11111110" => parity_bit_sched_cod <= '0'; parity_bit_sched_dec <= '0';
        when "11111111" => parity_bit_sched_cod <= '1'; parity_bit_sched_dec <= '0';
        -- End Sbox
        when others => null;
        end case;
        end process;

    parity_bit_sched <= parity_bit_sched_cod when (ctrl_dec = C_ENC) else parity_bit_sched_dec;
    error <= parity_bit_sched;

end a_sbox_parity;

