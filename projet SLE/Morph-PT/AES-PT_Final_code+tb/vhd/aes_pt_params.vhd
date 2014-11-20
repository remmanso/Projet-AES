
library IEEE;
    use IEEE.std_logic_1164.all;
    use IEEE.std_logic_misc.all;
    use IEEE.std_logic_arith.all;

library WORK;
package aes_pt_params is
    -- Set when reset signals have to be considered 'active'
    constant RESET_ACTIVE : std_logic := '0';
    type T_CTRL_IN is ( S_H_IN, S_V_IN );
    type T_CTRL_MIX is ( S_MIX, S_NOMIX );
    type T_ENCDEC is ( S_ENC, S_DEC );
    type T_CTRL_KEY is ( S_ADDKEY, S_NOKEY );
    type T_READY is ( C_READY, C_BUSY );
    end aes_pt_params;

