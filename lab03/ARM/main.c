/*
 * NAME
 * ----
 *
 * main.c
 *
 * DESCRIPTION
 * -----------
 *
 * This code serves several purposes.
 *
 * - It acts as an SPI master and sends/receives data.
 *
 * - It assumes the 8-bit data it receives is two 4-bit
 *   unsigned numbers.
 *
 * - It performs addition of the USER button is released
 *   and subtraction if pressed.
 *
 * - It display the result on the LCD as an unsigned number
 *   and it also includes the negative and overflow flags.
 * 
 * - It sends the 8-bit result through the SPI.
 *
 * More detailed descriptions can be found in the documentation
 * included with this project or in the source code.
 *
 * AUTHOR
 * ------
 *
 * Jeremiah Mahler <jmmahler@gmail.com>
 *
 */

#include "stm32l1xx.h"
#include "stdio.h"
#include "discover_board.h"
#include "stm32l_discovery_lcd.h"

#include "button.h"

/* The configure_* functions are used to
 * encapsulate the configuration of a specific
 * device.  Refer to the function itself for
 * further documentation.
 */
// declare functions (at end of file)
void configure_SPI();
void configure_LCD();
void configure_LEDs();

// The "special" add/sub operation
extern uint32_t saddsub(uint32_t, uint32_t, uint32_t);

void main() {

	unsigned int k;  // for loop counter
	// to display string on LCD
	char str[20];
	// send and recieve buffers for SPI
	uint8_t SPI1_Tx;
	uint8_t SPI1_Rx;
	uint8_t addr;
	uint8_t res;

    enum states {START, SPI_SEND_RECEIVE, DISPLAY, PAUSE, SPI_MANAGER};
    char state;

    enum states2 {START2, SW_RESULT, SW_SKIP, READ_MEM, RESULT_MEM, DONE};
    char state2;

#define LOWER_4_BITS 0x0000000F
#define UPPER_4_BITS 0x000000F0
// overflow and sign bitmask (from saddsub)
#define V_BIT 0x00000010
#define N_BIT 0x00000020
// bitmask for number portion of result from saddsub
#define NUM 0x0000000F


	// {{{ ### INITIALIZATION ###

	enable_button();

	configure_LEDs();

	configure_LCD();

	configure_SPI();

	// }}}

	// {{{ ### MAIN LOOP ###

	//GPIO_ResetBits(GPIOB, GPIO_Pin_6);  // turn off blue LED
	k = 0;
	SPI1_Tx = 0x00;  // initial data to send
	SPI1_Rx = 0x00;  // received data is stored here
	state = START;

	while (1) {
        if (SPI_SEND_RECEIVE == state) {
            if (SPI_I2S_GetFlagStatus(SPI1, SPI_I2S_FLAG_BSY)) {
                // kill some time
                asm("nop");
            } else if (SPI_I2S_GetFlagStatus(SPI1, SPI_I2S_FLAG_RXNE)) {
                // a transaction was completed

                GPIO_SetBits(GPIOB, GPIO_Pin_5);  // SS_L = 1, disable

                // read the received data from the last transaction
                //SPI_I2S_ClearFlag(SPI1, SPI_I2S_FLAG_RXNE);
                SPI1_Rx = SPI_I2S_ReceiveData(SPI1);
                // wait if needed
                //while (SPI_I2S_GetFlagStatus(SPI1, SPI_I2S_FLAG_RXNE));

                // next state
                state = SPI_MANAGER;
            } else if (SPI_I2S_GetFlagStatus(SPI1, SPI_I2S_FLAG_TXE)) {
                // we can transmit more data

                GPIO_ResetBits(GPIOB, GPIO_Pin_5);  // SS_L = 0, enable

                // transmit a byte
                SPI_I2S_SendData(SPI1, SPI1_Tx);
                while (SPI_I2S_GetFlagStatus(SPI1, SPI_I2S_FLAG_TXE));
            }
        } else if (SPI_MANAGER == state) {
            // a full-duplex send/receive has been completed

            if (state2 == RESULT_MEM) {
                res = SPI1_Rx;

                state = DISPLAY;
                state2 = DONE;
                /*
            } else if (state2 == READ_MEM) {
                

                state = SPI_SEND_RECEIVE;
                state2 = RESULT_MEM;
                */
            } else if (state2 == SW_RESULT) {
                addr = SPI1_Rx;

                SPI1_Tx = addr | 0x80;  // read memory address
                
                state = SPI_SEND_RECEIVE;
                state2 = RESULT_MEM;
            } else {
                // send command to read switches

                SPI1_Tx = 0x74 | 0x80;  // read switches

                // next state
                state2 = SW_RESULT;
                state = SPI_SEND_RECEIVE;
            }
        } else if (DISPLAY == state) {
            // ** LCD DISPLAY **

            // prepare the string
            sprintf(str, "%x %c %x", addr, 'R', res);

            LCD_GLASS_Clear();
            LCD_GLASS_DisplayString((unsigned char *) str);

            state = PAUSE; // next state
        } else {
            // default PAUSE
            if (++k > 1e5) {
                k = 0;

                // next state
                state = SPI_MANAGER;
            }
        }
	}
	// }}}

}

// {{{ configure_SPI()
/*
 * configure_SPI() - configure the SPI (SPI1) interface
 * 
 * SYNOPSIS
 * --------
 *
 *  configure_SPI();
 *
 *  // refer to stm32lxx_spi.c in the standard peripheral library (ST)
 *  // for the most complete description.
 *
 *  uint8_t SPI1_Tx;
 *  uint8_t SPI1_Rx;
 *
 *  SPI1_Rx = SPI_I2S_ReceiveData(SPI1);
 *  SPI_I2S_SendData(SPI1, SPI1_Tx);
 *
 *  SPI_I2S_GetFlagStatus(SPI1, SPI_I2S_FLAG_BSY)
 *  SPI_I2S_GetFlagStatus(SPI1, SPI_I2S_FLAG_TXE)
 *
 * DESCRIPTION
 * -----------
 *
 * This configuration of SPI uses SPI1 of the STM32L Discovery board.
 * This results in the following pin assignments.
 *
 *  SPI   pin
 *  ---   ---
 *  SCK   PA5
 *  MOSI  PA12
 *  MISO  PA11
 *  NSS   PB5  *
 *
 *  * Pin PB5 for slave select (NSS) is not a result of
 *    the SPI configuration.  But here it is configured as an
 *    output so it can be "bit banged" by the code controlling
 *    the SPI transactions.
 *
 * The following SPI configuration options were set.
 * These should be set identically on the slave which is being
 * communicated with.
 *
 *  name   value   description
 *  ----   -----   -----------
 *  MSB    first   most significant bit)
 *  CPOL   0       polarity
 *  CPHA   0       phase
 *
 * The slowest baud rate has been chosen since this application
 * emphasizes reliability as opposed to speed.
 * Testing found this to be approximately 60 kb/s
 *
 * The data size transferred is 8-bits.
 * This could be easily configured for 16-bits if needed.
 */
void configure_SPI() {
	GPIO_InitTypeDef GPIO_init;
	SPI_InitTypeDef SPI_init;

	// refer to stm32l1xx_spi.c for the steps
	// that are required to configure SPI

	// enable peripheral clock for SPI1
	RCC_APB2PeriphClockCmd(RCC_APB2Periph_SPI1, ENABLE);
	//RCC_APB2PeriphResetCmd(RCC_APB2Periph_SPI1, ENABLE);

	// Enable SCK, MOSI, MISO, and NSS GPIO clocks?
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
	//SPI_init.SPI_DataSize = SPI_DataSize_16b;
	SPI_init.SPI_CPOL = SPI_CPOL_Low;	// CPOL = 0
	SPI_init.SPI_CPHA = SPI_CPHA_1Edge;	// CPHA = 0
	SPI_init.SPI_NSS = SPI_NSS_Soft;  // NSS => SPI_CR1
	SPI_init.SPI_BaudRatePrescaler = SPI_BaudRatePrescaler_256;  // slow
	SPI_init.SPI_FirstBit = SPI_FirstBit_MSB;
	//SPI_init.SPI_CRCPolynomial = ?
	SPI_Init(SPI1, &SPI_init);

	SPI_Cmd(SPI1, ENABLE);

	// Configure PB5 so it can be bit-banged (NSS, SS_L)
	RCC_AHBPeriphClockCmd(RCC_AHBPeriph_GPIOB, ENABLE);
	// (re-use the previous GPIO_Init structure)
	GPIO_init.GPIO_Pin = GPIO_Pin_5;
	GPIO_init.GPIO_Mode = GPIO_Mode_OUT;
	GPIO_init.GPIO_Speed = GPIO_Speed_400KHz; // very low speed
	GPIO_init.GPIO_OType = GPIO_OType_PP;
	GPIO_init.GPIO_PuPd = GPIO_PuPd_NOPULL;
	GPIO_Init(GPIOB, &GPIO_init);
}
// }}}

// {{{ configure_LCD()

/*
 * configure_LCD();
 *
 * Configures the CLD so it can be used to display characters.
 *
 * SYNOPSIS
 * --------
 *
 *   configure_LCD();
 *
 *   while (1) {
 *     // do something
 *      
 *      // refresh display
 *      //
 *      // If this doesn't display right make sure you aren't
 *      // repeating too quickly.
 *      LCD_Glass_clear();
 *      LCD_GLASS_DisplayString((unsigned char*) str);
 *   }
 *
 */
void configure_LCD() {
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

	LCD_GLASS_Clear();
}
// }}}

// {{{ configure_LEDs
/*
 * configure_LEDs()
 *
 * The STM32L Discovery has two LEDS on the board
 * which can be turned on and off.
 * There is a blue LED on PB6 and a green one on PB7.
 * This function configures them so they can be turned on,
 * off or toggled.
 * 
 *  SYNOPSIS
 *  --------
 *  
 *  configure_LEDs();
 *
 *  GPIO_ToggleBits(GPIOB, GPIO_Pin_6); // TOGGLE blue LED
 *  GPIO_ToggleBits(GPIOB, GPIO_Pin_7); // TOGGLE green LED
 *
 *  GPIO_SetBits(GPIOB, GPIO_Pin_6);  // turn ON blue LED
 *  GPIO_SetBits(GPIOB, GPIO_Pin_7);  // turn ON green LED
 *
 *  GPIO_ResetBits(GPIOB, GPIO_Pin_6);  // turn OFF blue LED
 *  GPIO_ResetBits(GPIOB, GPIO_Pin_7);  // turn OFF green LED
 * 
 */
void configure_LEDs() {
	GPIO_InitTypeDef GPIOB_init;

	// setup as output so we can toggle the LED or outputs
	// PB6 is for the blue LED
	// PB7 is for the green LED
	RCC_AHBPeriphClockCmd(RCC_AHBPeriph_GPIOB, ENABLE);

	GPIOB_init.GPIO_Pin = GPIO_Pin_6 | GPIO_Pin_7;
	GPIOB_init.GPIO_Mode = GPIO_Mode_OUT;
	GPIOB_init.GPIO_Speed = GPIO_Speed_400KHz; // very low speed
	GPIOB_init.GPIO_OType = GPIO_OType_PP;
	GPIOB_init.GPIO_PuPd = GPIO_PuPd_NOPULL;
	GPIO_Init(GPIOB, &GPIOB_init);
}
// }}}

// vim:foldmethod=marker
