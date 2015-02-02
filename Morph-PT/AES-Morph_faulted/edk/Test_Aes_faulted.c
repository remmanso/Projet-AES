
#include "xparameters.h"
#include "xio.h"
#include "stdio.h"

//====================================================

#define AES_mWriteSlaveReg(RegNumber, Data) \
 	XIo_Out32((XPAR_AES_FAULTED_0_BASEADDR) + 4*(RegNumber), (Xuint32)(Data))
 	// xil_io_out32
 	
#define AES_mReadSlaveReg(RegNumber) \
 	XIo_In32((XPAR_AES_FAULTED_0_BASEADDR) + 4*(RegNumber))
 	// xil_io_in32


int main (void) {
  Xuint32 result0, result1, result2, result3;
  Xuint32 error;
  volatile Xuint32 rdy = 0, rdy_data_out = 0;

  //print("-- Entering main() --\r\n");
  
  //print("Performing multiplication: 13*11 = ");
  AES_mWriteSlaveReg( 1, 10 );// initialisation
  while (1) {
	  rdy = AES_mReadSlaveReg( 3 );
	  while (rdy != 1)
	  {
		rdy = AES_mReadSlaveReg( 3 );
	  }
	  AES_mWriteSlaveReg( 6, 0xe0370734 );
	  AES_mWriteSlaveReg( 7, 0x313198a2 );
	  AES_mWriteSlaveReg( 8, 0x885a308d );
	  AES_mWriteSlaveReg( 9, 0x3243f6a8 );
	  AES_mWriteSlaveReg( 0, 1 ); // Write '1' in register 0 - start command
	  AES_mWriteSlaveReg( 0, 0 ); // Write '0' in register 0 - cancel start command
	  
	  rdy_data_out = AES_mReadSlaveReg( 2 );
	  while (rdy_data_out != 1) {
		 rdy_data_out = AES_mReadSlaveReg( 2 );
	  }
	  result0 = AES_mReadSlaveReg( 10 );
	  result1 = AES_mReadSlaveReg( 11 );
	  result2 = AES_mReadSlaveReg( 12 );
	  result3 = AES_mReadSlaveReg( 13 );
	  error = AES_mReadSlaveReg( 4 );
  }
  
  //putnum( result );

  return 0;
}

