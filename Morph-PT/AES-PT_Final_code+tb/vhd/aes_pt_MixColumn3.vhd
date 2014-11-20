
library IEEE;
    use IEEE.std_logic_1164.all;
library WORK;
    use WORK.aes_pt_params.all;

entity aes_pt_mixcolumn3 is port (
    in_0, in_1, in_2, in_3 : in std_logic_vector (7 downto 0);
    pin0, pin1, pin2, pin3 : std_logic;
    ctrl_dec : in T_ENCDEC;
    b_out : out std_logic_vector (7 downto 0);
    pout : out std_logic ) ;
    end aes_pt_mixcolumn3;

architecture a_mixcolumn3 of aes_pt_mixcolumn3 is
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
    a <= in_1 xor in_3;
    b <= in_1 xor in_2;
    c <= in_0 xor b;
    d <= in_0 xor in_3;
    e <= b xor d;

    xt  : xtime  port map (d, f);
    x2t : x2time port map (a, h);
    x4t : x4time port map (e, g);

    i <= g xor h;
    out_1 <= f xor c;
    out_2 <= out_1 xor i;
    b_out <= out_1 when (ctrl_dec = S_ENC) else out_2;

    pout <= ( pin1 xor pin2 xor pin3 xor in_3(7) xor in_0(7) ) when (ctrl_dec = S_ENC) else
            ( pin0 xor pin1 xor pin3 xor in_0(5) xor in_0(6) xor in_1(5) xor
                       in_2(5) xor in_2(6) xor in_2(7) xor in_3(5) xor in_3(7) );

end a_mixcolumn3;

