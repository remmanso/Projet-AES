
library IEEE;
    use IEEE.std_logic_1164.all;
library WORK;
    use WORK.aes_pt_params.all;

entity aes_pt_mixcolumn2 is port (
    in_0, in_1, in_2, in_3 : in std_logic_vector (7 downto 0);
    pin0, pin1, pin2, pin3 : std_logic;
    ctrl_dec : in T_ENCDEC;
    b_out : out std_logic_vector (7 downto 0);
    pout : out std_logic ) ;
    end aes_pt_mixcolumn2;

architecture a_mixcolumn2 of aes_pt_mixcolumn2 is
    component xtime port (
        b_in : in std_logic_vector (7 downto 0);
        b_out : out std_logic_vector (7 downto 0) ) ;
        end component;
    component x2time port (
        b_in : in std_logic_vector (7 downto 0);
        b_out : out std_logic_vector (7 downto 0) ) ;
        end component;
    component x4time port (
        b_in : in std_logic_vector (7 downto 0);
        b_out : out std_logic_vector (7 downto 0) ) ;
        end component;
    signal a, b, c, d, e, f, g, h, i, out_1, out_2 : std_logic_vector (7 downto 0);
begin
    a <= in_0 xor in_1;
    b <= in_2 xor in_3;
    c <= in_0 xor in_2;
    d <= a xor b;
    e <= a xor in_3;

    xt  : xtime  port map (b, h);
    x2t : x2time port map (c, f);
    x4t : x4time port map (d, g);

    i <= f xor g;
    out_1 <= e xor h;
    out_2 <= out_1 xor i;
    b_out <= out_1 when (ctrl_dec = S_ENC) else out_2;

    pout <= ( pin0 xor pin1 xor pin2 xor in_2(7) xor in_3(7) ) when (ctrl_dec = S_ENC) else
            ( pin0 xor pin2 xor pin3 xor in_0(5) xor in_1(5) xor in_1(6) xor
                       in_1(7) xor in_2(5) xor in_2(7) xor in_3(5) xor in_3(6) );


end a_mixcolumn2;
