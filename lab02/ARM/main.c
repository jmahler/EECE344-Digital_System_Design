
#include "stm32l1xx.h"
#include "stdio.h"
#include "discover_board.h"
#include "stm32l_discovery_lcd.h"

#include "button.h"

void configure_SPI();

void main() {
	unsigned int k;  // for loop counter
	char str[20];
	GPIO_InitTypeDef GPIOB_init;
	uint8_t SPI1_Tx;
	uint8_t SPI1_Rx;

	// Enable the High Speed Internal (HSI) clock
	RCC_HSICmd(ENABLE);
	// Select the HSI as SYSCLK
	RCC_SYSCLKConfig(RCC_SYSCLKSource_HSI);

	// Enable PWR
	RCC_APB1PeriphClockCmd(RCC_APB1Periph_PWR, ENABLE);

	// Enable SYSCFG
	RCC_APB2PeriphClockCmd(RCC_APB2Periph_SYSCFG, ENABLE);

	// enable access to the RTC domain and registers
	// needed for the LCD
	RCC_APB1PeriphClockCmd(RCC_APB1Periph_LCD, ENABLE);
	PWR_RTCAccessCmd(ENABLE);
	RCC_RTCCLKConfig(RCC_RTCCLKSource_LSE);

	// LSE enable
	// clock needed for RTCCLK and LCD
	// must be done after PWR_RTCAccessCmd(ENABLE);
	RCC_LSEConfig(RCC_LSE_ON);
	
	LCD_GLASS_Configure_GPIO();
	LCD_GLASS_Init();

	enable_button();
	// XXX - don't put this after SPI or it will disrupt the GPIO config

	configure_SPI();

	// setup as output so we can toggle the LED or outputs
	// PB5 is for SS_L used with SPI
	// PB6 is for the blue LED
	// PB7 is for the green LED
	RCC_AHBPeriphClockCmd(RCC_AHBPeriph_GPIOB, ENABLE);
	//GPIOB_init.GPIO_Pin = GPIO_Pin_5 | GPIO_Pin_6 | GPIO_Pin_7;
	GPIOB_init.GPIO_Pin = GPIO_Pin_5;
	GPIOB_init.GPIO_Mode = GPIO_Mode_OUT;
	GPIOB_init.GPIO_Speed = GPIO_Speed_400KHz; // very low speed
	GPIOB_init.GPIO_OType = GPIO_OType_PP;
	GPIOB_init.GPIO_PuPd = GPIO_PuPd_NOPULL;
	GPIO_Init(GPIOB, &GPIOB_init);

	SPI_Cmd(SPI1, ENABLE);

	//GPIO_ResetBits(GPIOB, GPIO_Pin_6);  // turn off blue LED
	//k = 0;
	SPI1_Tx = 0x4F;  // initial data to send
	SPI1_Rx = 0x00;  // received data is stored here
	while (1) {

		// If there was an SPI error, turn on the blue LED
		//if (SPI_I2S_GetFlagStatus(SPI1, SPI_FLAG_CRCERR | SPI_FLAG_MODF | SPI_I2S_FLAG_FRE)) {
		//	GPIO_SetBits(GPIOB, GPIO_Pin_6);  // turn on blue LED
		//}

		if (SPI_I2S_GetFlagStatus(SPI1, SPI_I2S_FLAG_BSY)) {
			// wait
			asm("nop");
		} else if (SPI_I2S_GetFlagStatus(SPI1, SPI_I2S_FLAG_RXNE)) {
			// a transaction was completed
			GPIO_SetBits(GPIOB, GPIO_Pin_5);  // SS_L = 1, disable

			// read the received data from the last transaction
			//SPI_I2S_ClearFlag(SPI1, SPI_I2S_FLAG_RXNE);
			SPI1_Rx = SPI_I2S_ReceiveData(SPI1);
			while (SPI_I2S_GetFlagStatus(SPI1, SPI_I2S_FLAG_RXNE));
		} else if (SPI_I2S_GetFlagStatus(SPI1, SPI_I2S_FLAG_TXE)) {
			// transmit buffer is ready for more data

			GPIO_ResetBits(GPIOB, GPIO_Pin_5);  // SS_L = 0, enable

			// transmit a byte
			SPI_I2S_SendData(SPI1, SPI1_Tx);
			//while (SPI_I2S_GetFlagStatus(SPI1, SPI_I2S_FLAG_TXE));
		}

		if (++k > 1e5) {
			k = 0;

			// toggle LED on PB6, to show we are alive
			//if (!button_pressed()) {
			//	GPIO_ToggleBits(GPIOB, GPIO_Pin_7); // green LED
			//}

			// display the recieved byte on the LCD
			sprintf(str, "%x", SPI1_Rx);
			LCD_GLASS_Clear();
			LCD_GLASS_DisplayString((unsigned char *) str);

			// setup to echo the received data
			SPI1_Tx = SPI1_Rx;

/*
			// alternate between two values
			if (SPI1_Rx == 0x4F) {
				SPI1_Tx = 0xF4;
			} else {
				SPI1_Tx = 0x4F;
			}
*/
		}
	}
}

void configure_SPI() {
	GPIO_InitTypeDef GPIO_init;
	SPI_InitTypeDef SPI_init;

	// refer to stm32l1xx_spi.c for the steps
	// that are required to configure SPI

	// enable peripheral clock for SPI1
	RCC_APB2PeriphClockCmd(RCC_APB2Periph_SPI1, ENABLE);
	//RCC_APB2PeriphResetCmd(RCC_APB2Periph_SPI1, ENABLE);

	// TODO Enable SCK, MOSI, MISO, and NSS GPIO clocks?
	//RCC_AHBPeriphClockCmd();
	RCC_AHBPeriphClockCmd(RCC_AHBPeriph_GPIOA, ENABLE);

	// Peripherals alternate function:
	// connect pins to peripherals
	GPIO_PinAFConfig(GPIOA, GPIO_PinSource5, GPIO_AF_SPI1);  // SCK, PA5
	GPIO_PinAFConfig(GPIOA, GPIO_PinSource12, GPIO_AF_SPI1); // MOSI, PA12
	GPIO_PinAFConfig(GPIOA, GPIO_PinSource11, GPIO_AF_SPI1); // MISO, PA11
//	GPIO_PinAFConfig(GPIOA, GPIO_PinSource5 | GPIO_PinSource12 | GPIO_PinSource11, GPIO_AF_SPI1); // MISO, PA11
	// configure pin alternate function
	GPIO_init.GPIO_Pin = GPIO_Pin_5 | GPIO_Pin_12 | GPIO_Pin_11;
	GPIO_init.GPIO_Mode = GPIO_Mode_AF;
	GPIO_init.GPIO_Speed = GPIO_Speed_40MHz;  // high speed
	GPIO_init.GPIO_OType = GPIO_OType_PP;
	GPIO_init.GPIO_PuPd = GPIO_PuPd_NOPULL;
	GPIO_Init(GPIOA, &GPIO_init);

	// program the polarity, phase, etc
	SPI_StructInit(&SPI_init);  // default values
	SPI_init.SPI_Direction = SPI_Direction_2Lines_FullDuplex;
	SPI_init.SPI_Mode = SPI_Mode_Master;
	SPI_init.SPI_DataSize = SPI_DataSize_8b;
	SPI_init.SPI_CPOL = SPI_CPOL_Low;	// CPOL = 0
	SPI_init.SPI_CPHA = SPI_CPHA_1Edge;	// CPHA = 0
	SPI_init.SPI_NSS = SPI_NSS_Soft;  // NSS => SPI_CR1
	SPI_init.SPI_BaudRatePrescaler = SPI_BaudRatePrescaler_256;
	SPI_init.SPI_FirstBit = SPI_FirstBit_MSB;
	//SPI_init.SPI_CRCPolynomial = ?
	SPI_Init(SPI1, &SPI_init);
}
