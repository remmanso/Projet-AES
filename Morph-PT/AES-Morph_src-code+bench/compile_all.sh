rm -rf libs/lib_aes_core
rm -rf libs/lib_test_aes_anr
rm -rf libs/lib_test_aes_core
rm -rf libs/lib_test_mc_parity

vlib libs/lib_aes_core
vlib libs/lib_test_aes_anr
vlib libs/lib_test_aes_core
vlib libs/lib_test_mc_parity

vcom -work libs/lib_aes_core vhd/params.vhd
vcom -work libs/lib_aes_core vhd/*.vhd
vcom -work libs/lib_test_aes_anr sim/Test_aes_anr_b.vhd
vcom -work libs/lib_test_aes_core sim/Test_aes_core.vhd
vcom -work libs/lib_test_mc_parity sim/Test_MC_parity.vhd
