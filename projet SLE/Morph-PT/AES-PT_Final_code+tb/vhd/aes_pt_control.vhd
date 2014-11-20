------------------------------------------------------
------------------------------------------------------

library IEEE;
    use IEEE.std_logic_1164.all;
library WORK;
    use WORK.aes_pt_params.all;

entity aes_pt_control is port (
    go_crypt, go_key, encdec : in std_logic;
    ready_out : out T_READY;
    data_out_ok : out std_logic;
    ctrl_dec : out T_ENCDEC;
    ctrl_mix : out T_CTRL_MIX;
    ctrl_in : out T_CTRL_IN;
    ctrl_key : out T_CTRL_KEY;
    next_key, next_rcon : out std_logic;
    reset, clk : in std_logic
    );
    end aes_pt_control;


-- Architecture of the Component
architecture arch of aes_pt_control is
    type T_STATE is ( IDLE, ST_KEY_0, ST_KEY_1, ST_KEY_2, 
                            ST_DU_L1, ST_DU_L2, ST_DU_LK, -- ST_DU_L0, 
														ST_DU_R0, ST_DU_R1, ST_DU_R2, ST_DU_F0, ST_DU_F1, ST_DU_F2, ST_DU_O0, ST_DU_O1, ST_DU_O2 );
    signal state : T_STATE;
    signal s_data_out_ok, s_next_key, s_next_rcon : std_logic;
    signal s_ready_out : T_READY;
    signal s_ctrl_dec : T_ENCDEC;
    signal s_ctrl_mix : T_CTRL_MIX;
    signal s_ctrl_in : T_CTRL_IN;
    signal s_ctrl_key : T_CTRL_KEY;
    signal s_num_rounds, s_iter : integer range 0 to 14;
begin
    process( clk )
        variable num_rounds : integer range 0 to 14;
    begin
        if ( clk'event and clk='1' ) then
			 if ( reset=RESET_ACTIVE ) then
            if (encdec='0') then
                s_ctrl_dec <= S_ENC;
            else
                s_ctrl_dec <= S_DEC;
                end if;
            s_ready_out <= C_READY;
            s_data_out_ok <= '0';
            s_ctrl_mix <= S_NOMIX;
            s_ctrl_in <= S_H_IN;
            s_ctrl_key <= S_NOKEY;
            s_next_key <= '0';
            s_next_rcon <= '0';
            state <= IDLE;
        else
            case state is
                when IDLE =>
                    s_ready_out <= C_READY;
                    s_data_out_ok <= '0';
                    s_ctrl_mix <= S_NOMIX;
                    s_ctrl_in <= S_H_IN;
                    s_ctrl_key <= S_NOKEY;
                    s_next_key <= '0';
                    s_next_rcon <= '0';
                    if ( go_key='1' ) then
                        s_num_rounds <= 9; s_iter <= 10; -- 128 bit
                        if ( encdec='1' ) then -- Go to decryption key
                            s_ready_out <= C_BUSY;
                            s_next_key <= '0';
                            s_next_rcon <= '0';
                            state <= ST_KEY_0;
                            end if;
                    elsif ( go_crypt='1' ) then -- Start encryption/decryption
                        if (encdec='0') then
                            s_ctrl_dec <= S_ENC;
                        else
                            s_ctrl_dec <= S_DEC;
                            end if;
                        s_ready_out <= C_BUSY;
                        s_data_out_ok <= '0';
                        s_ctrl_mix <= S_MIX;
                        s_ctrl_in <= S_H_IN;
                        s_ctrl_key <= S_NOKEY;
                        s_next_key <= '0';
                        s_next_rcon <= '0';
                        s_iter <= s_num_rounds;
                        state <= ST_DU_L1; -- L0
                        end if;
                --------------------------------------------------------
                when ST_KEY_0 =>
                    s_next_key <= '0';
                    s_next_rcon <= '0';
                    if ( s_iter=0 ) then
                        state <= IDLE;
                        s_ctrl_dec <= S_DEC; --
                        s_ready_out <= C_READY;
                    else
                        s_ctrl_dec <= S_ENC; --^
                        state <= ST_KEY_1;
                        end if;
                when ST_KEY_1 =>
                    s_next_key <= '0';
                    s_next_rcon <= '0';
                    s_ctrl_dec <= S_ENC;
                    state <= ST_KEY_2;
                    s_iter <= s_iter - 1;
                when ST_KEY_2 =>
                    s_next_key <= '1';
                    if ( s_iter=0 ) then
                        s_next_rcon <= '0';
                    else
                        s_next_rcon <= '1';
                        end if;
                    state <= ST_KEY_0;
                --------------------------------------------------------
--                when ST_DU_L0 => 
--                    state <= ST_DU_L1; 
                when ST_DU_L1 => -- BEGINNING
                    state <= ST_DU_L2;
                when ST_DU_L2 =>
                    s_ctrl_key <= S_ADDKEY;
                    state <= ST_DU_LK;
                when ST_DU_LK =>
                    s_ctrl_mix <= S_MIX;
                    s_ctrl_in <= S_V_IN;
                    if ( s_ctrl_dec=S_ENC ) then
                        s_ctrl_key <= S_ADDKEY;
                    else
                        s_ctrl_key <= S_NOKEY;
                        end if;
                    s_next_key <= '0';
                    s_next_rcon <= '0';
                    state <= ST_DU_R0;
                when ST_DU_R0 => -- GENERIC ROUND
                    s_next_key <= '1';
                    s_next_rcon <= '1';
                    state <= ST_DU_R1;
                when ST_DU_R1 =>
                    s_next_key <= '0';
                    s_next_rcon <= '0';
                    s_iter <= s_iter-1;
                    state <= ST_DU_R2;
                when ST_DU_R2 =>
                    s_next_key <= '0';
                    s_next_rcon <= '0';
                    if ( s_iter=0 ) then
                        state <= ST_DU_F0;
                    else
                        state <= ST_DU_R0;
                        end if;
                when ST_DU_F0 => -- FINAL ROUND
                    s_next_key <= '1';
                    s_next_rcon <= '1';
                    s_ctrl_mix <= S_NOMIX;
                    state <= ST_DU_F1;
                when ST_DU_F1 =>
                    s_next_key <= '0';
                    s_next_rcon <= '0';
                    state <= ST_DU_F2;
                when ST_DU_F2 =>
                    s_data_out_ok <= '1';
                    s_ctrl_in <= S_H_IN;
                    s_ctrl_mix <= S_MIX;
                    s_ctrl_key <= S_NOKEY;
                    s_ready_out <= C_READY;
                    state <= ST_DU_O0;
                when ST_DU_O0 => -- OUTPUT
                    state <= ST_DU_O1;
                when ST_DU_O1 =>
                    state <= ST_DU_O2;
                when ST_DU_O2 =>
                    if ( go_crypt='1' ) then
                        s_ctrl_key <= S_ADDKEY;
                        state <= ST_DU_R0;
                    else
                        state <= IDLE;
                        end if;
                --------------------------------------------------------
                end case;
            end if; -- reset
			 end if; -- clk
        end process;

        ready_out <= s_ready_out;
        data_out_ok <= s_data_out_ok;
        ctrl_dec <= s_ctrl_dec;
        ctrl_mix <= s_ctrl_mix;
        ctrl_in <= s_ctrl_in;
        ctrl_key <= s_ctrl_key;
        next_key <= s_next_key;
        next_rcon <= s_next_rcon;
    end arch;
