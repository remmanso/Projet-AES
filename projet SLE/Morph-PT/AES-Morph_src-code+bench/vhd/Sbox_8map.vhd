-- Library Declaration
library IEEE;
    use IEEE.std_logic_1164.all;
library WORK;
    use WORK.params.all;

-- Component Declaration
entity sbox_8map is port (
    b_in : in std_logic_vector (7 downto 0);
    ctrl_dec : in T_ENCDEC;
    rnd_seed : in std_logic_vector (2 downto 0);
    clock, reset : in std_logic;
    b_out : out std_logic_vector (7 downto 0)   );
    end sbox_8map;

-- Architecture of the Component
architecture a_sbox of sbox_8map is
    component aff_trans_B port (
        a : in std_logic_vector (7 downto 0);
        b_out : out std_logic_vector (7 downto 0)    );
        end component;
    component aff_trans_inv_B port (
        a : in std_logic_vector (7 downto 0);
        b_out : out std_logic_vector (7 downto 0)    );
        end component;
    component inversion_8map port (
        b_in : in std_logic_vector (7 downto 0);
        rnd_seed : in std_logic_vector (2 downto 0);
    		clock, reset : in std_logic;
        b_out : out std_logic_vector (7 downto 0)   );
      end component;
  signal tsdec : T_ENCDEC;
   -- Internal Signal (4 std_logic)
--   signal ah, a1h, al, a1l, d, o, n, m, l, i, g, f, p, q, r : std_logic_vector (3 downto 0);
   -- Internal Signal (8 bit)
   signal s, t, v, z : std_logic_vector (7 downto 0);
begin
    -- Affine Trasnformation
    gen000e : if ( C_INCLUDE_DECODING_LOGIC=false ) generate
      v <= b_in;
      end generate;
    gen000d : if ( C_INCLUDE_DECODING_LOGIC ) generate
      ati:aff_trans_inv_B port map (b_in, s);
      v <= s when (ctrl_dec = C_DEC) else b_in;
      end generate;
    -- Inversion 
    i_inv : inversion_8map port map( v, rnd_seed, clock, reset, z );

    temp_reg : process( clock )
    begin
      if ( clock'event and clock='1' ) then
				if ( reset=RESET_ACTIVE ) then
					tsdec <= C_ENC;
				else
        	tsdec <= ctrl_dec;
					end if;
        end if;
      end process;
    -- NO PIPELINE
    -- tsdec <= ctrl_dec;

    -- Inverse Affine Transformation
    at:aff_trans_B port map (z, t);
   
    gen001e : if ( not C_INCLUDE_DECODING_LOGIC ) generate
      b_out <= t;
      end generate;
    gen001d : if ( C_INCLUDE_DECODING_LOGIC ) generate
      b_out <= z when (tsdec = C_DEC ) else t; 
      end generate;

end a_sbox;
