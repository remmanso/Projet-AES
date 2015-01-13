-- Library Declaration
library IEEE;
    use IEEE.std_logic_1164.all;
library WORK;
    use WORK.params.all;

-- Component Declaration
entity inversion_8map is port (
    b_in : in std_logic_vector (7 downto 0);
    rnd_seed : in std_logic_vector (2 downto 0);
    clock, reset : in std_logic;
    b_out : out std_logic_vector (7 downto 0)   );
    end inversion_8map;

-- Architecture of the Component
architecture arch of inversion_8map is
    component gfmapB port ( 
        a : in std_logic_vector (7 downto 0);
        ah, al : out std_logic_vector (3 downto 0));
        end component;
    component gfmap2 port (
        a : in std_logic_vector (7 downto 0);
        ah, al : out std_logic_vector (3 downto 0));
        end component;
    component gfmap4 port (
        a : in std_logic_vector (7 downto 0);
        ah, al : out std_logic_vector (3 downto 0));
        end component;
    component gfmap8 port (
        a : in std_logic_vector (7 downto 0);
        ah, al : out std_logic_vector (3 downto 0));
        end component;
    component gfmap16 port (
        a : in std_logic_vector (7 downto 0);
        ah, al : out std_logic_vector (3 downto 0));
        end component;
    component gfmap32 port (
        a : in std_logic_vector (7 downto 0);
        ah, al : out std_logic_vector (3 downto 0));
        end component;
    component gfmap64 port (
        a : in std_logic_vector (7 downto 0);
        ah, al : out std_logic_vector (3 downto 0));
        end component;
    component gfmap128 port (
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
    component gfmap2inv is port (
        ah, al : in std_logic_vector (3 downto 0);
        a : out std_logic_vector (7 downto 0)    );
        end component;
    component gfmap4inv is port (
        ah, al : in std_logic_vector (3 downto 0);
        a : out std_logic_vector (7 downto 0)    );
        end component;
    component gfmap8inv is port (
        ah, al : in std_logic_vector (3 downto 0);
        a : out std_logic_vector (7 downto 0)    );
        end component;
    component gfmap16inv is port (
        ah, al : in std_logic_vector (3 downto 0);
        a : out std_logic_vector (7 downto 0)    );
        end component;
    component gfmap32inv is port (
        ah, al : in std_logic_vector (3 downto 0);
        a : out std_logic_vector (7 downto 0)    );
        end component;
    component gfmap64inv is port (
        ah, al : in std_logic_vector (3 downto 0);
        a : out std_logic_vector (7 downto 0)    );
        end component;
    component gfmap128inv is port (
        ah, al : in std_logic_vector (3 downto 0);
        a : out std_logic_vector (7 downto 0)    );
        end component;
   -- signal tsdec : T_ENCDEC;
   -- Internal Signal (4 std_logic)
   signal ah0, ah1, ah2, ah3, ah4, ah5, ah6, ah7 : std_logic_vector (3 downto 0);
   signal al0, al1, al2, al3, al4, al5, al6, al7  : std_logic_vector (3 downto 0);
   signal ah, al : std_logic_vector (3 downto 0);
   signal d, o, n, m, l, i, g, f, p, q, r, a1h, a1l : std_logic_vector (3 downto 0);
   -- Internal Signal (8 bit)
   signal z0, z1, z2, z3, z4, z5, z6, z7 : std_logic_vector (7 downto 0);
   signal z : std_logic_vector (7 downto 0); -- s, t, v, 
   signal s_rnd_seed : std_logic_vector (2 downto 0);
begin
  -- Map
  mp01:gfmapB port map (b_in, ah0, al0); 
  mp02:gfmap2 port map (b_in, ah1, al1);
  mp03:gfmap4 port map (b_in, ah2, al2);
  mp04:gfmap8 port map (b_in, ah3, al3); 
  mp05:gfmap16 port map (b_in, ah4, al4); 
  mp06:gfmap32 port map (b_in, ah5, al5); 
  mp07:gfmap64 port map (b_in, ah6, al6); 
  mp08:gfmap128 port map (b_in, ah7, al7);
  with rnd_seed select
    ah <= ah0 when "000",
          ah1 when "001",
          ah2 when "010",
          ah3 when "011",
          ah4 when "100",
          ah5 when "101",
          ah6 when "110",
          ah7 when "111",
					( others=>'X' ) when others;
  with rnd_seed select
    al <= al0 when "000",
          al1 when "001",
          al2 when "010",
          al3 when "011",
          al4 when "100",
          al5 when "101",
          al6 when "110",
          al7 when "111",
					( others=>'X' ) when others;
    
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

  -- PIPELINE LAYER
  temp_reg : process( clock )
  begin
    if ( clock'event and clock='1' ) then
			if ( reset=RESET_ACTIVE ) then
        p <= ( others=>'0' );
        q <= ( others=>'0' );
        r <= ( others=>'0' );
				s_rnd_seed <= ( others=>'0' );
			else
        p <= ah;
        q <= g;
        r <= f;
				s_rnd_seed <= rnd_seed;
        end if;
			end if;
    end process;
  -- NO PIPELINE
  -- p <= ah; 
  -- q <= g;
  -- r <= f;  
  -- s_rnd_seed <= rnd_seed;
  
  -- Inverter
  inv:gf_inv_B port map (q, d);

  -- Second Moltiplicator
  molt2:gf_molt_B port map (p, d, a1h);
  -- Third Moltiplicator
  molt3:gf_molt_B port map (d, r, a1l);

  -- Inverse Map
  imp01:gfmapinvB port map (a1h, a1l, z0); 
  imp00:gfmap2inv port map (a1h, a1l, z1);
  imp03:gfmap4inv port map (a1h, a1l, z2);
  imp04:gfmap8inv port map (a1h, a1l, z3);
  imp05:gfmap16inv port map (a1h, a1l, z4); 
  imp06:gfmap32inv port map (a1h, a1l, z5); 
  imp07:gfmap64inv port map (a1h, a1l, z6); 
  imp08:gfmap128inv port map (a1h, a1l, z7); 
  with s_rnd_seed select
    z <= z0 when "000",
          z1 when "001",
          z2 when "010",
          z3 when "011",
          z4 when "100",
          z5 when "101",
          z6 when "110",
          z7 when "111",
					( others=>'X' ) when others;
  
  b_out <= z;
  end arch;
