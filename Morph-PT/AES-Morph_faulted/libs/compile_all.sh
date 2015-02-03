rm -rf lib_aes_core
rm -rf lib_test_aes_anr
rm -rf lib_test_aes_core
rm -rf lib_test_mc_parity
rm -rf lib_test_aes_faulted_random

vlib lib_aes_core
vlib lib_test_aes_anr
vlib lib_test_aes_core_faulted
vlib lib_test_mc_parity
vlib lib_test_aes_faulted_random

vcom -work lib_aes_core ../vhd/params.vhd
vcom -work lib_aes_core ../vhd/*.vhd
vcom -work lib_test_aes_anr ../sim/Test_aes_anr_b.vhd
vcom -work lib_test_aes_core_faulted ../sim/Test_aes_core_faulted.vhd
vcom -work lib_test_aes_core_faulted ../sim/cfg_Bench_Aes_faulted.vhd
vcom -work lib_test_mc_parity ../sim/Test_MC_parity.vhd
vcom -work lib_test_aes_faulted_random ../sim/Test_aes_faulted_random.vhd
