
library IEEE;
    use IEEE.std_logic_1164.all;
library WORK;
    use WORK.aes_pt_params.all;

entity aes_pt_mixcolumn0 is port (
    in_0, in_1, in_2, in_3 : in std_logic_vector (7 downto 0);
    pin0, pin1, pin2, pin3 : in std_logic;
    ctrl_dec : in T_ENCDEC;
    b_out : out std_logic_vector (7 downto 0);
    pout : out std_logic ) ;
    end aes_pt_mixcolumn0;

architecture a_mixcolumn0 of aes_pt_mixcolumn0 is
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
    c <= in_2 xor in_3;
    b <= c xor in_1;
    e <= in_0 xor in_2;
    f <= a xor c;

    xt  : xtime  port map (a, d);
    x2t : x2time port map (e, g);
    x4t : x4time port map (f, h);

    i <= g xor h;
    out_1 <= b xor d;
    out_2 <= out_1 xor i;
    b_out <= out_1 when (ctrl_dec = S_ENC) else out_2;

    pout <= ( pin0 xor pin2 xor pin3 xor in_0(7) xor in_1(7) ) when (ctrl_dec = S_ENC) else
            ( pin0 xor pin1 xor pin2 xor in_0(5) xor in_0(7) xor in_1(5) xor
                       in_1(6) xor in_2(5) xor in_3(5) xor in_3(6) xor in_3(7) );

end a_mixcolumn0;