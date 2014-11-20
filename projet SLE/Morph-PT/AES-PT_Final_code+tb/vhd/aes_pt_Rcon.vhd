
library IEEE;
    use IEEE.std_logic_1164.all;
library WORK;
    use WORK.aes_pt_params.all;

entity aes_pt_rcon is port (
    next_value : in std_logic;
    ctrl_dec : in T_ENCDEC;
    reset, clock : in std_logic;
    rcon_byte : out std_logic_vector (7 downto 0);
    rcon_pbit : out std_logic       );
    end aes_pt_rcon;

architecture a_rcon of aes_pt_rcon is
    signal rc_reg : std_logic_vector( 7 downto 0 );
    signal rc_pt : std_logic;
begin
    process( clock, reset )
        variable temp_rc : std_logic_vector( 7 downto 0 );
    begin
        if ( reset=RESET_ACTIVE ) then
            rc_reg <= X"01";
            rc_pt <= '1';
        elsif ( clock'event and clock='1' ) then
            if ( next_value='1' ) then
                temp_rc := rc_reg;
                if ( ctrl_dec=S_ENC ) then
                    rc_reg <= ( temp_rc(6 downto 0) & '0' ) xor ( "000" & temp_rc(7) & temp_rc(7) & '0' & temp_rc(7) & temp_rc(7) );
                    rc_pt <= rc_pt xor temp_rc(7);
                else
                    rc_reg <= ( '0' & temp_rc(7 downto 1) ) xor ( temp_rc(0) & "000" & temp_rc(0) & temp_rc(0) & '0' & temp_rc(0) );
                    rc_pt <= rc_pt xor temp_rc(0);
                   end if;
                end if;
            end if;
        end process;
        rcon_byte <= rc_reg;
        rcon_pbit <= rc_pt;
    end a_rcon;

