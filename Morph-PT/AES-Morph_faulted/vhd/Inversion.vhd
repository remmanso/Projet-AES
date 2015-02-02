-- Library Declaration
library IEEE;
    use IEEE.std_logic_1164.all;
library WORK;
    use WORK.params.all;

-- Component Declaration
entity inversion is port (
    b_in : in std_logic_vector (7 downto 0);
--    ctrl_dec : T_ENCDEC;
    clock : in std_logic;
    b_out : out std_logic_vector (7 downto 0)   );
    end inversion;

-- Architecture of the Component
architecture arch of inversion is
    component gfmapB port (
        a : in std_logic_vector (7 downto 0);
        ah, al : out std_logic_vector (3 downto 0));
        end component;
    component quadrato port (
        a : in std_logic_vector (3 downto 0);
        d : out std_logic_vector (3 downto 0));
        end component;
    component x_e is port (
        a : in std_logic_vector (3 downto 0);
        d : out std_logic_vector (3 downto 0) );
        end component;
    component gf_molt_B is port (
        a, b: in std_logic_vector (3 downto 0);
        d : out std_logic_vector (3 downto 0));
        end component;
    component gf_inv_B is port (
        a_in : std_logic_vector (3 downto 0);
        d : out std_logic_vector (3 downto 0));
        end component;
    component gfmapinvB is port (
        ah, al : in std_logic_vector (3 downto 0);
        a : out std_logic_vector (7 downto 0)    );
        end component;
  -- signal tsdec : T_ENCDEC;
  -- Internal Signal (4 std_logic)
  signal ah, a1h, al, a1l, d, o, n, m, l, i, g, f, p, q, r : std_logic_vector (3 downto 0);
  -- Internal Signal (8 bit)
  signal z : std_logic_vector (7 downto 0); -- s, t, v, 
begin
    -- Map
    mp:gfmapB port map (b_in, ah, al);
    -- First Square
    qua1:quadrato port map (ah, o);
    -- Second Square
    qua2:quadrato port map (al, n);
    -- X [e]
    x9:x_e port map (o, m);
    -- First Moltiplicator
    molt1:gf_molt_B port map (ah, al, l);

    f <= ah xor al;
    i <= m xor n;
    g <= i xor l;

    temp_reg : process( clock )
    begin
        if ( clock'event and clock='1' ) then
            p <= ah;
            q <= g;
            r <= f;
            end if;
        end process;
    -- NO PIPELINE
--    p <= ah; 
--    q <= g;
--    r <= f;

    -- Inverter
    inv:gf_inv_B port map (q, d);

    -- Second Moltiplicator
    molt2:gf_molt_B port map (p, d, a1h);

    -- Third Moltiplicator
    molt3:gf_molt_B port map (d, r, a1l);

    -- Inverse Map
    mapinv:gfmapinvB port map (a1h, a1l, z);

    b_out <= z;

end arch;
