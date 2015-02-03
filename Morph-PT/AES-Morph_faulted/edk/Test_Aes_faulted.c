
#include "xparameters.h"
#include "xio.h"
#include "stdio.h"
#include "xuartlite.h"
#include "xgpio.h"
#include "xstatus.h"
#include "xbasic_types.h"
#include "xil_types.h"
#include "xil_assert.h"
#include "xstatus.h"

//====================================================

#define AES_mWriteSlaveReg(RegNumber, Data) \
 	XIo_Out32((XPAR_AES_FAULTED_0_BASEADDR) + 4*(RegNumber), (Xuint32)(Data))
 	// xil_io_out32
 	
#define AES_mReadSlaveReg(RegNumber) \
 	XIo_In32((XPAR_AES_FAULTED_0_BASEADDR) + 4*(RegNumber))
 	// xil_io_in32
	
#define LED_CHANNEL 1

int SwitchInput(u16 DeviceId, u32 *DataRead);
int UartLiteSelfTest(u16 DeviceId);

XGpio GpioInput; 
XUartLite UartLite;

int main (void) {
	Xuint32 result0, result1, result2, result3;
	Xuint32 error, cpt_cipher = 0, cpt_cipher_faulted = 0, cpt_fausse_a = 0;
	volatile Xuint32 rdy = 0, rdy_data_out = 0;

	int Status_uart, Status_gpio, enable_random_fault = 0;
	u32 data_switch = 0;

	Status_uart = UartLiteSelfTest(XPAR_RS232_UART_1_DEVICE_ID);
	if (Status_uart != XST_SUCCESS) {
		return XST_FAILURE;
	}

	print("-- Entering main() --\r\n");

	Status_gpio = SwitchInput(XPAR_DIP_SWITCHES_8BIT_DEVICE_ID, &data_switch);
	if ((data_switch & 0x00000001) && 0x00000001) {
		if ((data_switch & 0x00000002) && 0x00000002) {
			AES_mWriteSlaveReg( 1, 0x0000000B );// initialisation avec detecteur et fautes aléatoire
			print("Initialisation avec detecteur et avec generation de fautes aléatoires\r\n");
			enable_random_fault = 1;
		} else {
			AES_mWriteSlaveReg( 1, 0x0000000A );// initialisation avec detecteur et sans fautes aléatoire
			print("Initialisation avec detecteur et sans génération de fautes aléatoires\r\n");
		}
	}
	else {
		if ((data_switch & 0x00000002) && 0x00000002) {
			AES_mWriteSlaveReg( 1, 0x00000003 );// initialisation sans detecteur et fautes aléatoire
			print("Initialisation sans detecteur et avec generation de fautes aléatoires\r\n");
			enable_random_fault = 1;
		} else {
			AES_mWriteSlaveReg( 1, 0x00000002 );// initialisation sans detecteur et sans fautes aléatoire
			print("Initialisation sans detecteur et sans génération de fautes aléatoires\r\n");
		}
	}
	Xuint32 i;
	for (i = 0; i < 1000000; i++) {
		;
	}
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
	if (error == 1) {
		if (enable_random_fault == 0)
			print("chiffrement fauté\r\n");
		cpt_cipher_faulted ++;
	}
	else if (error == 2) {
		if (enable_random_fault == 0)
			print("fausse alarme\r\n");
		cpt_fausse_a++;
	}
	cpt_cipher++;
	if ((cpt_cipher % 1000000) == 0 && cpt_cipher != 0 && enable_random_fault == 1) {
		xil_printf("nb_chiffrement : %d  \r\n", cpt_cipher);
		xil_printf("chiffrement fauté : %d ", cpt_cipher_faulted * 100 / cpt_cipher);print("%\r\n");
		xil_printf("fausse alarme : %d ", cpt_fausse_a * 100 / cpt_cipher);print("%\r\n");
	}
		
  }
  
  //putnum( result );

  return 0;
}

int SwitchInput(u16 DeviceId, u32 *DataRead)
{
	 int Status;

	 /*
	  * Initialize the GPIO driver so that it's ready to use,
	  * specify the device ID that is generated in xparameters.h
	  */
	 Status = XGpio_Initialize(&GpioInput, DeviceId);
	 if (Status != XST_SUCCESS) {
		  return XST_FAILURE;
	 }

	 /*
	  * Set the direction for all signals to be inputs
	  */
	 XGpio_SetDataDirection(&GpioInput, LED_CHANNEL, 0xFFFFFFFF);

	 /*
	  * Read the state of the data so that it can be  verified
	  */
	 *DataRead = XGpio_DiscreteRead(&GpioInput, LED_CHANNEL);

	 return XST_SUCCESS;

}

int UartLiteSelfTest(u16 DeviceId)
{
	int Status;

	/*
	 * Initialize the UartLite driver so that it is ready to use.
	 */
	Status = XUartLite_Initialize(&UartLite, DeviceId);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	/*
	 * Perform a self-test to ensure that the hardware was built correctly.
	 */
	Status = XUartLite_SelfTest(&UartLite);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	return XST_SUCCESS;
}

