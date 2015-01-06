onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix hexadecimal /a_test_aes_core/UUT/clk
add wave -noupdate -radix hexadecimal /a_test_aes_core/UUT/data_in
add wave -noupdate -radix hexadecimal /a_test_aes_core/UUT/data_out
add wave -noupdate -divider DETECT_COMP
add wave -noupdate -radix hexadecimal /a_test_aes_core/UUT/s_realign
add wave -noupdate -radix hexadecimal /a_test_aes_core/UUT/DETECTOR_CODE/s_data_in_unmasked
add wave -noupdate -radix hexadecimal /a_test_aes_core/UUT/DETECTOR_CODE/s_parity_data_in
add wave -noupdate /a_test_aes_core/UUT/DETECTOR_CODE/s_data_out_parity
add wave -noupdate -radix hexadecimal /a_test_aes_core/UUT/DETECTOR_CODE/s_parity_data_in_debug
add wave -noupdate -radix hexadecimal /a_test_aes_core/UUT/DETECTOR_CODE/alarm
add wave -noupdate -divider R1
add wave -noupdate -radix hexadecimal /a_test_aes_core/UUT/round_for(1)/ROUND_I/data_in
add wave -noupdate -radix hexadecimal /a_test_aes_core/UUT/round_for(1)/ROUND_I/data_out
add wave -noupdate -divider R2
add wave -noupdate -radix hexadecimal /a_test_aes_core/UUT/round_for(2)/ROUND_I/data_in
add wave -noupdate -radix hexadecimal /a_test_aes_core/UUT/round_for(2)/ROUND_I/data_out
add wave -noupdate -divider R2
add wave -noupdate -radix hexadecimal /a_test_aes_core/UUT/round_for(3)/ROUND_I/data_in
add wave -noupdate -radix hexadecimal /a_test_aes_core/UUT/round_for(3)/ROUND_I/data_out
add wave -noupdate -divider R3
add wave -noupdate -radix hexadecimal /a_test_aes_core/UUT/round_for(4)/ROUND_I/data_in
add wave -noupdate -radix hexadecimal /a_test_aes_core/UUT/round_for(4)/ROUND_I/data_out
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {5265288 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 222
configure wave -valuecolwidth 200
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {4314679 ps} {4433499 ps}
