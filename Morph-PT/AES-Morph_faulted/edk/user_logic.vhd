------------------------------------------------------------------------------
-- user_logic.vhd - entity/architecture pair
------------------------------------------------------------------------------
--
-- ***************************************************************************
-- ** Copyright (c) 1995-2010 Xilinx, Inc.  All rights reserved.            **
-- **                                                                       **
-- ** Xilinx, Inc.                                                          **
-- ** XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS"         **
-- ** AS A COURTESY TO YOU, SOLELY FOR USE IN DEVELOPING PROGRAMS AND       **
-- ** SOLUTIONS FOR XILINX DEVICES.  BY PROVIDING THIS DESIGN, CODE,        **
-- ** OR INFORMATION AS ONE POSSIBLE IMPLEMENTATION OF THIS FEATURE,        **
-- ** APPLICATION OR STANDARD, XILINX IS MAKING NO REPRESENTATION           **
-- ** THAT THIS IMPLEMENTATION IS FREE FROM ANY CLAIMS OF INFRINGEMENT,     **
-- ** AND YOU ARE RESPONSIBLE FOR OBTAINING ANY RIGHTS YOU MAY REQUIRE      **
-- ** FOR YOUR IMPLEMENTATION.  XILINX EXPRESSLY DISCLAIMS ANY              **
-- ** WARRANTY WHATSOEVER WITH RESPECT TO THE ADEQUACY OF THE               **
-- ** IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OR        **
-- ** REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE FROM CLAIMS OF       **
-- ** INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS       **
-- ** FOR A PARTICULAR PURPOSE.                                             **
-- **                                                                       **
-- ***************************************************************************
--
------------------------------------------------------------------------------
-- Filename:          user_logic.vhd
-- Version:           1.00.a
-- Description:       User logic.
-- Date:              Thu Jan 15 09:54:37 2015 (by Create and Import Peripheral Wizard)
-- VHDL Standard:     VHDL'93
------------------------------------------------------------------------------
-- Naming Conventions:
--   active low signals:                    "*_n"
--   clock signals:                         "clk", "clk_div#", "clk_#x"
--   reset signals:                         "rst", "rst_n"
--   generics:                              "C_*"
--   user defined types:                    "*_TYPE"
--   state machine next state:              "*_ns"
--   state machine current state:           "*_cs"
--   combinatorial signals:                 "*_com"
--   pipelined or register delay signals:   "*_d#"
--   counter signals:                       "*cnt*"
--   clock enable signals:                  "*_ce"
--   internal version of output port:       "*_i"
--   device pins:                           "*_pin"
--   ports:                                 "- Names begin with Uppercase"
--   processes:                             "*_PROCESS"
--   component instantiations:              "<ENTITY_>I_<#|FUNC>"
------------------------------------------------------------------------------

-- DO NOT EDIT BELOW THIS LINE --------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;

-- DO NOT EDIT ABOVE THIS LINE --------------------

--USER libraries added here

------------------------------------------------------------------------------
-- Entity section
------------------------------------------------------------------------------
-- Definition of Generics:
--   C_SLV_DWIDTH                 -- Slave interface data bus width
--   C_NUM_REG                    -- Number of software accessible registers
--
-- Definition of Ports:
--   Bus2IP_Clk                   -- Bus to IP clock
--   Bus2IP_Reset                 -- Bus to IP reset
--   Bus2IP_Data                  -- Bus to IP data bus
--   Bus2IP_BE                    -- Bus to IP byte enables
--   Bus2IP_RdCE                  -- Bus to IP read chip enable
--   Bus2IP_WrCE                  -- Bus to IP write chip enable
--   IP2Bus_Data                  -- IP to Bus data bus
--   IP2Bus_RdAck                 -- IP to Bus read transfer acknowledgement
--   IP2Bus_WrAck                 -- IP to Bus write transfer acknowledgement
--   IP2Bus_Error                 -- IP to Bus error response
------------------------------------------------------------------------------

entity user_logic is
  generic
  (
    -- ADD USER GENERICS BELOW THIS LINE ---------------
    --USER generics added here
    -- ADD USER GENERICS ABOVE THIS LINE ---------------

    -- DO NOT EDIT BELOW THIS LINE ---------------------
    -- Bus protocol parameters, do not add to or delete
    C_SLV_DWIDTH                   : integer              := 32;
    C_NUM_REG                      : integer              := 14
    -- DO NOT EDIT ABOVE THIS LINE ---------------------
  );
  port
  (
    -- ADD USER PORTS BELOW THIS LINE ------------------
    --USER ports added here
    -- ADD USER PORTS ABOVE THIS LINE ------------------

    -- DO NOT EDIT BELOW THIS LINE ---------------------
    -- Bus protocol ports, do not add to or delete
    Bus2IP_Clk                     : in  std_logic;
    Bus2IP_Reset                   : in  std_logic;
    Bus2IP_Data                    : in  std_logic_vector(0 to C_SLV_DWIDTH-1);
    Bus2IP_BE                      : in  std_logic_vector(0 to C_SLV_DWIDTH/8-1);
    Bus2IP_RdCE                    : in  std_logic_vector(0 to C_NUM_REG-1);
    Bus2IP_WrCE                    : in  std_logic_vector(0 to C_NUM_REG-1);
    IP2Bus_Data                    : out std_logic_vector(0 to C_SLV_DWIDTH-1);
    IP2Bus_RdAck                   : out std_logic;
    IP2Bus_WrAck                   : out std_logic;
    IP2Bus_Error                   : out std_logic
    -- DO NOT EDIT ABOVE THIS LINE ---------------------
  );

  attribute SIGIS : string;
  attribute SIGIS of Bus2IP_Clk    : signal is "CLK";
  attribute SIGIS of Bus2IP_Reset  : signal is "RST";

end entity user_logic;

------------------------------------------------------------------------------
-- Architecture section
------------------------------------------------------------------------------

architecture IMP of user_logic is

  --USER signal declarations added here, as needed for user logic
  component aes_core port (
    clk, rst : in std_logic;
    start_cipher, load_key : in std_logic; -- active HIGH 
    enable_fault : in std_logic;
    data_in : in std_logic_vector( 127 downto 0 ); 
    input_key : in std_logic_vector( 127 downto 0 ); 
    -- enc_mode : in std_logic; -- 0 = ENCRYPTION, 1 = DECRYPTION
    
    rndms_in : in std_logic_vector( 5 downto 0 ); 
    enable_full_red : in std_logic; 
    enable_partial_red : in std_logic;
    enable_detect_code : in std_logic; 
    
    data_out : out std_logic_vector( 127 downto 0 ); 
    data_out_ok : out std_logic; 
    error_out : out std_logic; 
    ready_out : out std_logic -- 1 = AVAILABLE, 0 = BUSY
    ); -- rst active LOW, see aes_globals.vhd
  end component;

  signal s_data_in, s_key_loaded, s_data_out : std_logic_vector(127 downto 0);
  signal s_start_cipher, s_load_key, s_enable_fault : std_logic;
  signal s_enable_full_red, s_enable_partial_red, s_enable_detect_code : std_logic;
  signal s_data_out_ok, s_ready_out, s_error_out : std_logic;
  signal s_flag : integer range 0 to 100;
  signal s_rndms_in : std_logic_vector(5 downto 0);

	type T_STATE is (IDLE, RESET_ACTIVE, INIT);
	signal state : T_STATE;
  ------------------------------------------
  -- Signals for user logic slave model s/w accessible register example
  ------------------------------------------
  signal slv_reg0                       : std_logic_vector(0 to C_SLV_DWIDTH-1);--start_cipher
  signal slv_reg1                       : std_logic_vector(0 to C_SLV_DWIDTH-1);--enable_fault -> bit 0, 
                                                                                --enable_full_red -> bit 1,
                                                                                --enable_partial_red -> bit 2,
                                                                                --enable_detect_code-> bit 3
  signal slv_reg2                       : std_logic_vector(0 to C_SLV_DWIDTH-1);--data_out_ok
  signal slv_reg3                       : std_logic_vector(0 to C_SLV_DWIDTH-1);--ready_out
  signal slv_reg4                       : std_logic_vector(0 to C_SLV_DWIDTH-1);--error_out
  signal slv_reg5                       : std_logic_vector(0 to C_SLV_DWIDTH-1);--rndms_in
  signal slv_reg6                       : std_logic_vector(0 to C_SLV_DWIDTH-1);--data_in(31 downto 0)
  signal slv_reg7                       : std_logic_vector(0 to C_SLV_DWIDTH-1);--data_in(63 downto 32)
  signal slv_reg8                       : std_logic_vector(0 to C_SLV_DWIDTH-1);--data_in(95 downto 64)
  signal slv_reg9                       : std_logic_vector(0 to C_SLV_DWIDTH-1);--data_in(127 downto 96)
  signal slv_reg10                      : std_logic_vector(0 to C_SLV_DWIDTH-1);--data_out(31 downto 0)
  signal slv_reg11                      : std_logic_vector(0 to C_SLV_DWIDTH-1);--data_out(63 downto 32)
  signal slv_reg12                      : std_logic_vector(0 to C_SLV_DWIDTH-1);--data_out(95 downto 64)
  signal slv_reg13                      : std_logic_vector(0 to C_SLV_DWIDTH-1);--data_out(127 downto 96)
  signal slv_reg_write_sel              : std_logic_vector(0 to 13);
  signal slv_reg_read_sel               : std_logic_vector(0 to 13);
  signal slv_ip2bus_data                : std_logic_vector(0 to C_SLV_DWIDTH-1);
  signal slv_read_ack                   : std_logic;
  signal slv_write_ack                  : std_logic;

begin

  --USER logic implementation added here

	FSM_PROC : process( Bus2IP_Clk ) 
	begin
		if ( Bus2IP_Clk'event and Bus2IP_Clk='1' ) then
			if ( Bus2IP_Reset='1' ) then 
				state <= RESET_ACTIVE;
			else
				case state is
					when INIT => 
						s_key_loaded <= X"2b7e151628aed2a6abf7158809cf4f3c";
						s_load_key <= '1';
						s_rndms_in <= "111111";
						state <= IDLE;
					when IDLE => 
						s_key_loaded <= (others => '0');
						s_load_key <= '0';
						s_rndms_in <= "000000";
					when RESET_ACTIVE =>
						s_key_loaded <= (others => '0');
						s_load_key <= '0';
						s_rndms_in <= "000000";
						state <= INIT;
					when others => null;
				end case;
			end if;
		end if;
	end process FSM_PROC;


  FLAG_PROC : process (Bus2IP_Clk, Bus2IP_Reset)
  begin
    if (Bus2IP_Clk ='1' and Bus2IP_Clk'event) then
      if (Bus2IP_Reset ='1') then
        s_flag <= 0;
      elsif (slv_reg0(C_SLV_DWIDTH-1) = '0') then
        s_flag <= 0;
      elsif (slv_reg0(C_SLV_DWIDTH-1) = '1') then
        if (s_flag <= 100) then
          s_flag <= s_flag + 1;
        end if;
      end if;
    end if;
  end process FLAG_PROC;
        
  s_start_cipher <= '1' when (s_flag = 1) else '0';
  s_data_in <= slv_reg9 & slv_reg8 & slv_reg7 & slv_reg6 when (s_flag = 1) else (others => '0');
  
  s_enable_full_red <= slv_reg1(1) when (s_ready_out = '1' and Bus2IP_Reset = '0') 
    else '0' when (Bus2IP_Reset = '1')
    else s_enable_full_red;

  s_enable_partial_red <= slv_reg1(2) when (s_ready_out = '1' and Bus2IP_Reset = '0') 
    else '0' when (Bus2IP_Reset = '1')
    else s_enable_partial_red;

  s_enable_detect_code <= slv_reg1(3) when (s_ready_out = '1' and Bus2IP_Reset = '0') 
    else '0' when (Bus2IP_Reset = '1')
    else s_enable_detect_code;

  s_enable_fault <= slv_reg1(0) when (s_ready_out = '0')
    else '0';

  I_AES : aes_core port map (
    clk  => Bus2IP_Clk,
    rst => Bus2IP_Reset,
    start_cipher  => s_start_cipher,
    load_key => s_load_key,
    enable_fault => s_enable_fault,
    data_in => s_data_in,
    input_key => s_key_loaded,
    rndms_in => s_rndms_in,
    enable_full_red => s_enable_full_red,
    enable_partial_red => s_enable_partial_red,
    enable_detect_code => s_enable_detect_code,
    data_out => s_data_out,
    data_out_ok => s_data_out_ok,
    error_out => s_error_out,
    ready_out => s_ready_out
  );

  PROC_OUT : process (Bus2IP_Clk, Bus2IP_Reset)
  begin
    if (Bus2IP_Clk = '1' and Bus2IP_Clk'event) then
      if (Bus2IP_Reset = '1') then
        slv_reg2 <= (others => '0');
        slv_reg3 <= (others => '0');
        slv_reg4 <= (others => '0');
        slv_reg10 <= (others => '0');
        slv_reg11 <= (others => '0');
        slv_reg12 <= (others => '0');
        slv_reg13 <= (others => '0');
      elsif (s_data_out_ok = '1') then
        slv_reg2(C_SLV_DWIDTH-1) <= s_data_out_ok;
        slv_reg3(C_SLV_DWIDTH-1) <= s_ready_out;
        slv_reg4(C_SLV_DWIDTH-1) <= s_error_out;
        slv_reg10 <= s_data_out(31 downto 0);
        slv_reg11 <= s_data_out(63 downto 32);
        slv_reg12 <= s_data_out(95 downto 64);
        slv_reg13 <= s_data_out(127 downto 96);
      end if;
    end if;
  end process PROC_OUT;

  ------------------------------------------
  -- Example code to read/write user logic slave model s/w accessible registers
  -- 
  -- Note:
  -- The example code presented here is to show you one way of reading/writing
  -- software accessible registers implemented in the user logic slave model.
  -- Each bit of the Bus2IP_WrCE/Bus2IP_RdCE signals is configured to correspond
  -- to one software accessible register by the top level template. For example,
  -- if you have four 32 bit software accessible registers in the user logic,
  -- you are basically operating on the following memory mapped registers:
  -- 
  --    Bus2IP_WrCE/Bus2IP_RdCE   Memory Mapped Register
  --                     "1000"   C_BASEADDR + 0x0
  --                     "0100"   C_BASEADDR + 0x4
  --                     "0010"   C_BASEADDR + 0x8
  --                     "0001"   C_BASEADDR + 0xC
  -- 
  ------------------------------------------
  slv_reg_write_sel <= Bus2IP_WrCE(0 to 13);
  slv_reg_read_sel  <= Bus2IP_RdCE(0 to 13);
  slv_write_ack     <= Bus2IP_WrCE(0) or Bus2IP_WrCE(1) or Bus2IP_WrCE(2) or Bus2IP_WrCE(3) or Bus2IP_WrCE(4) or Bus2IP_WrCE(5) or Bus2IP_WrCE(6) or Bus2IP_WrCE(7) or Bus2IP_WrCE(8) or Bus2IP_WrCE(9) or Bus2IP_WrCE(10) or Bus2IP_WrCE(11) or Bus2IP_WrCE(12) or Bus2IP_WrCE(13);
  slv_read_ack      <= Bus2IP_RdCE(0) or Bus2IP_RdCE(1) or Bus2IP_RdCE(2) or Bus2IP_RdCE(3) or Bus2IP_RdCE(4) or Bus2IP_RdCE(5) or Bus2IP_RdCE(6) or Bus2IP_RdCE(7) or Bus2IP_RdCE(8) or Bus2IP_RdCE(9) or Bus2IP_RdCE(10) or Bus2IP_RdCE(11) or Bus2IP_RdCE(12) or Bus2IP_RdCE(13);

  -- implement slave model software accessible register(s)
  SLAVE_REG_WRITE_PROC : process( Bus2IP_Clk ) is
  begin

    if Bus2IP_Clk'event and Bus2IP_Clk = '1' then
      if Bus2IP_Reset = '1' then
        slv_reg0 <= (others => '0');
        slv_reg1 <= (others => '0');
        --slv_reg2 <= (others => '0');
        --slv_reg3 <= (others => '0');
        --slv_reg4 <= (others => '0');
        slv_reg5 <= (others => '0');
        slv_reg6 <= (others => '0');
        slv_reg7 <= (others => '0');
        slv_reg8 <= (others => '0');
        slv_reg9 <= (others => '0');
        --slv_reg10 <= (others => '0');
        --slv_reg11 <= (others => '0');
        --slv_reg12 <= (others => '0');
        --slv_reg13 <= (others => '0');
      else
        case slv_reg_write_sel is
          when "10000000000000" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                slv_reg0(byte_index*8 to byte_index*8+7) <= Bus2IP_Data(byte_index*8 to byte_index*8+7);
              end if;
            end loop;
          when "01000000000000" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                slv_reg1(byte_index*8 to byte_index*8+7) <= Bus2IP_Data(byte_index*8 to byte_index*8+7);
              end if;
            end loop;
          when "00100000000000" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                --slv_reg2(byte_index*8 to byte_index*8+7) <= Bus2IP_Data(byte_index*8 to byte_index*8+7);
              end if;
            end loop;
          when "00010000000000" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                --slv_reg3(byte_index*8 to byte_index*8+7) <= Bus2IP_Data(byte_index*8 to byte_index*8+7);
              end if;
            end loop;
          when "00001000000000" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                --slv_reg4(byte_index*8 to byte_index*8+7) <= Bus2IP_Data(byte_index*8 to byte_index*8+7);
              end if;
            end loop;
          when "00000100000000" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                slv_reg5(byte_index*8 to byte_index*8+7) <= Bus2IP_Data(byte_index*8 to byte_index*8+7);
              end if;
            end loop;
          when "00000010000000" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                slv_reg6(byte_index*8 to byte_index*8+7) <= Bus2IP_Data(byte_index*8 to byte_index*8+7);
              end if;
            end loop;
          when "00000001000000" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                slv_reg7(byte_index*8 to byte_index*8+7) <= Bus2IP_Data(byte_index*8 to byte_index*8+7);
              end if;
            end loop;
          when "00000000100000" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                slv_reg8(byte_index*8 to byte_index*8+7) <= Bus2IP_Data(byte_index*8 to byte_index*8+7);
              end if;
            end loop;
          when "00000000010000" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                slv_reg9(byte_index*8 to byte_index*8+7) <= Bus2IP_Data(byte_index*8 to byte_index*8+7);
              end if;
            end loop;
          when "00000000001000" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                --slv_reg10(byte_index*8 to byte_index*8+7) <= Bus2IP_Data(byte_index*8 to byte_index*8+7);
              end if;
            end loop;
          when "00000000000100" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                --slv_reg11(byte_index*8 to byte_index*8+7) <= Bus2IP_Data(byte_index*8 to byte_index*8+7);
              end if;
            end loop;
          when "00000000000010" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                --slv_reg12(byte_index*8 to byte_index*8+7) <= Bus2IP_Data(byte_index*8 to byte_index*8+7);
              end if;
            end loop;
          when "00000000000001" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                --slv_reg13(byte_index*8 to byte_index*8+7) <= Bus2IP_Data(byte_index*8 to byte_index*8+7);
              end if;
            end loop;
          when others => null;
        end case;
      end if;
    end if;

  end process SLAVE_REG_WRITE_PROC;

  -- implement slave model software accessible register(s) read mux
  SLAVE_REG_READ_PROC : process( slv_reg_read_sel, slv_reg0, slv_reg1, slv_reg2, slv_reg3, slv_reg4, slv_reg5, slv_reg6, slv_reg7, slv_reg8, slv_reg9, slv_reg10, slv_reg11, slv_reg12, slv_reg13 ) is
  begin

    case slv_reg_read_sel is
      when "10000000000000" => slv_ip2bus_data <= slv_reg0;
      when "01000000000000" => slv_ip2bus_data <= slv_reg1;
      when "00100000000000" => slv_ip2bus_data <= slv_reg2;
      when "00010000000000" => slv_ip2bus_data <= slv_reg3;
      when "00001000000000" => slv_ip2bus_data <= slv_reg4;
      when "00000100000000" => slv_ip2bus_data <= slv_reg5;
      when "00000010000000" => slv_ip2bus_data <= slv_reg6;
      when "00000001000000" => slv_ip2bus_data <= slv_reg7;
      when "00000000100000" => slv_ip2bus_data <= slv_reg8;
      when "00000000010000" => slv_ip2bus_data <= slv_reg9;
      when "00000000001000" => slv_ip2bus_data <= slv_reg10;
      when "00000000000100" => slv_ip2bus_data <= slv_reg11;
      when "00000000000010" => slv_ip2bus_data <= slv_reg12;
      when "00000000000001" => slv_ip2bus_data <= slv_reg13;
      when others => slv_ip2bus_data <= (others => '0');
    end case;

  end process SLAVE_REG_READ_PROC;

  ------------------------------------------
  -- Example code to drive IP to Bus signals
  ------------------------------------------
  IP2Bus_Data  <= slv_ip2bus_data when slv_read_ack = '1' else
                  (others => '0');

  IP2Bus_WrAck <= slv_write_ack;
  IP2Bus_RdAck <= slv_read_ack;
  IP2Bus_Error <= '0';

end IMP;
