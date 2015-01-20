Library lib_aes_core ;

configuration cfg_Bench_Aes_faulted  of A_test_aes_core_faulted is
  for exp
        for UUT : aes_core use entity lib_aes_core.aes_core(arch) ;
        end for ;
  end for ;
end cfg_Bench_Aes_faulted ;
