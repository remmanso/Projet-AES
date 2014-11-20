
-- Library Declaration
library IEEE;
    use IEEE.std_logic_1164.all;
library WORK;
    use WORK.aes_pt_params.all;

-- Component Declaration
entity aes_pt_sbox is port (
    b_in : in std_logic_vector (7 downto 0);
    p_in : in std_logic;
    ctrl_dec : T_ENCDEC;
    clock, reset : in std_logic;
    b_out : out std_logic_vector (7 downto 0);
    p_out : out std_logic );
    end aes_pt_sbox;

-- Architecture of the Component
architecture a_sbox of aes_pt_sbox is
	component reg 
		generic( SIZE : integer := 8 );
		port(
			clk, rst : in std_logic;
			din  : in std_logic_vector( SIZE-1 downto 0 );
			dout : out std_logic_vector( SIZE-1 downto 0 ) );
		end component;
	component regbit 
		port(
			clk, rst : in std_logic;
			din  : in std_logic;
			dout : out std_logic );
		end component;
    component sbox_parity port(
        sbox_in : in std_logic_vector(7 downto 0);
        ctrl_dec : in T_ENCDEC;
        error : out std_logic     );
        end component;
    component aff_trans port (
        a : in std_logic_vector (7 downto 0);
        b_out : out std_logic_vector (7 downto 0)    );
        end component;
    component aff_trans_inv port (
        a : in std_logic_vector (7 downto 0);
        b_out : out std_logic_vector (7 downto 0)    );
        end component;
    component gfmap port (
        a : in std_logic_vector (7 downto 0);
        ah, al : out std_logic_vector (3 downto 0));
        end component;
    component gf_square port (
        a : in std_logic_vector (3 downto 0);
        d : out std_logic_vector (3 downto 0));
        end component;
    component gf_x_e is port (
        a : in std_logic_vector (3 downto 0);
        d : out std_logic_vector (3 downto 0) );
        end component;
    component gf_molt is port (
        a, b: in std_logic_vector (3 downto 0);
        d : out std_logic_vector (3 downto 0));
        end component;
    component gf_inv is port (
        a_in : std_logic_vector (3 downto 0);
        d : out std_logic_vector (3 downto 0));
        end component;
    component gfmapinv is port (
        ah, al : in std_logic_vector (3 downto 0);
        a : out std_logic_vector (7 downto 0)    );
        end component;
   -- Internal Signal (4 std_logic)
   signal ah, a1h, al, a1l, d, o, n, m, l, i, g, f, p, q, r : std_logic_vector (3 downto 0);
   -- Internal Signal (8 bit)
   signal s, t, v, z : std_logic_vector (7 downto 0);
   signal sub_pt, tmp_pt, pred_pt : std_logic;
begin
    sb_pt : sbox_parity port map( b_in, ctrl_dec, sub_pt );
    tmp_pt <= ( b_in(7) xor b_in(6) xor b_in(5) xor b_in(4) xor b_in(3) xor
                b_in(2) xor b_in(1) xor b_in(0) xor p_in ) xor sub_pt;

    -- Affine Trasnformation
    ati:aff_trans_inv port map (b_in, s);

    v <= s when (ctrl_dec = S_DEC) else b_in;

    -- Map
    mp:gfmap port map (v, ah, al);

    -- First Square
    qua1:gf_square port map (ah, o);

    -- Second Square
    qua2:gf_square port map (al, n);

    -- X [e]
    xe:gf_x_e port map (o, m);

    -- First Moltiplicator
    molt1:gf_molt port map (ah, al, l);

    f <= ah xor al;
    i <= m xor n;
    g <= i xor l;

    -- TEMPORARY REGISTERS 
		p_reg : reg generic map( 4 ) port map( clock, reset, ah, p );
		q_reg : reg generic map( 4 ) port map( clock, reset,  g, q );
		r_reg : reg generic map( 4 ) port map( clock, reset,  f, r );
		pt_reg : regbit port map( clock, reset, tmp_pt, pred_pt );

    -- Inverter
    inv:gf_inv port map (q, d);

    -- Second Moltiplicator
    molt2:gf_molt port map (p, d, a1h);

    -- Third Moltiplicator
    molt3:gf_molt port map (d, r, a1l);

    -- Inverse Map
    mapinv:gfmapinv port map (a1h, a1l, z);

    -- Inverse Affine Transformation
    at:aff_trans port map (z, t);

    b_out <= z when (ctrl_dec = S_DEC) else t;
    p_out <= pred_pt;

end a_sbox;
