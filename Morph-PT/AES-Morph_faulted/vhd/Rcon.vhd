
library IEEE;
    use IEEE.std_logic_1164.all;
library WORK;
    use WORK.params.all;

entity rcon is port (
    next_value : in T_ENABLE;  
    ctrl_dec : in T_ENCDEC;
    reset, clock : in std_logic;
    rcon_byte : out std_logic_vector (7 downto 0);
    rewind_key : in T_ENABLE;
    save_key : in T_ENABLE );
    end rcon;

architecture a_rcon of rcon is
    signal rc_reg, s_last_rcon : std_logic_vector( 7 downto 0 );
begin
    process( clock, reset )
        variable temp_rc : std_logic_vector( 7 downto 0 );
    begin
        if ( reset=RESET_ACTIVE ) then  
            rc_reg <= "00000001"; 
            s_last_rcon <= (others=>'0');
        elsif ( clock'event and clock='1' ) then 
          if ( rewind_key = C_ENABLED ) then
            if ( C_INCLUDE_DECODING_LOGIC ) then
              if( ctrl_dec=C_ENC ) then
                rc_reg <= "00000001";
              else -- ctrl_dec
                rc_reg <= s_last_rcon;
                end if; -- ctrl_dec
            else -- not C_INCLUDE_DECODING_LOGIC
              rc_reg <= "00000001";
              end if; -- C_INCLUDE_DECODING_LOGIC
          elsif ( save_key = C_ENABLED ) then
            s_last_rcon <= rc_reg;
          elsif ( next_value=C_ENABLED ) then
            temp_rc := rc_reg; 
            if ( C_INCLUDE_DECODING_LOGIC ) then
              if ( ctrl_dec=C_ENC ) then  
                rc_reg <= ( temp_rc(6 downto 0) & '0' ) xor ( "000" & temp_rc(7) & temp_rc(7) & '0' & temp_rc(7) & temp_rc(7) );
              else   -- ctrl_dec
                rc_reg <= ( '0' & temp_rc(7 downto 1) ) xor ( temp_rc(0) & "000" & temp_rc(0) & temp_rc(0) & '0' & temp_rc(0) );
                end if; -- ctrl_dec
            else -- not C_INCLUDE_DECODING_LOGIC 
              rc_reg <= ( temp_rc(6 downto 0) & '0' ) xor ( "000" & temp_rc(7) & temp_rc(7) & '0' & temp_rc(7) & temp_rc(7) );
              end if; -- C_INCLUDE_DECODING_LOGIC
            end if; -- nextval
          end if; -- reset, clock
        end process;
        rcon_byte <= rc_reg;
    end a_rcon;
