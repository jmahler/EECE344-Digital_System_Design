/*
 * NAME
 * ----
 *
 * main.c
 *
 * DESCRIPTION
 * -----------
 *
 * The CPLD board defines access to a "bus" through
 * a protocol over the SPI.  This code provides an
 * interface so that a user can read/write to this
 * bus by adjusting the input switches (also on the bus)
 * and reading the LCD (on the ARM).
 * 
 * The SPI protocol consists of two bytes.
 * The first byte contains the 7-bit address and a
 * 1 bit read/write bit.  Depending on if this byte
 * is a read or a write data will be sent or received.
 *
 * For more details refer to the documentation (doc/)
 * included with this project.
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
uint8_t SPI_once(uint8_t);
void NSS_enable();
void NSS_disable();

// bitmasks to select the address and rw bit
#define ADDR_BITS 0x7F
#define RW_BIT    0x80

void main() {

    // to display string on LCD
    char str[10];
    // send and recieve buffers for SPI
    uint8_t SPI1_Tx;
    uint8_t SPI1_Rx;
    // 7-bit addr, 1 bit rw
    uint8_t addr;
    uint8_t rw;

    uint8_t to_write;

    enum state {START,
                ENTER_CMD,
                READ_CMD_1,
                READ_CMD_2,
                ENTER_DATA,
                READ_DATA_1,
                READ_DATA_2,
                EXECUTE_1,
                EXECUTE_2,
                DISPLAY_RESULTS};
    char state;

    // {{{ ### INITIALIZATION ###

    enable_button();

    configure_LEDs();

    configure_LCD();

    configure_SPI();

    // }}}

    // {{{ ### MAIN LOOP ###

    SPI1_Tx = 0x00;  // initial data to send
    SPI1_Rx = 0x00;  // received data is stored here
    state = START;

    // This state machine is easier to understand along
    // with the "State diagram of ARM operation" diagram
    // included in this projects documentation (doc/).

    while (1) {
        if (ENTER_CMD == state) {
            // prepare the string
            sprintf(str, "CMD");

            LCD_GLASS_Clear();
            LCD_GLASS_DisplayString((unsigned char *) str);

            wait_button_press();

            // next state
            state = READ_CMD_1;
        } else if (READ_CMD_1 == state) {
            NSS_enable();

            SPI1_Tx = 0x74 | 0x80;  // read switches

            // perform one SPI transaction (8-bits)
            // ignore the return value
            SPI_once(SPI1_Tx);

            state = READ_CMD_2;
        } else if (READ_CMD_2 == state) {
            SPI1_Tx = 0x00;  // form feed, can be any value

            SPI1_Rx = SPI_once(SPI1_Tx);

            addr = SPI1_Rx & ADDR_BITS;
            rw   = SPI1_Rx & RW_BIT;
            // NOTE, the rw bit is left in its highest bit

            NSS_disable();

            if (rw)
                state = EXECUTE_1;
            else
                state = ENTER_DATA;
        } else if (ENTER_DATA == state) {
            sprintf(str, "DATA");

            LCD_GLASS_Clear();
            LCD_GLASS_DisplayString((unsigned char *) str);

            wait_button_press();

            state = READ_DATA_1;
        } else if (READ_DATA_1 == state) {
            NSS_enable();

            SPI1_Tx = 0x74 | 0x80;  // read switches

            // perform one SPI transaction (8-bits)
            // ignore the return value
            SPI_once(SPI1_Tx);

            state = READ_DATA_2;
        } else if (READ_DATA_2 == state) {

            to_write = SPI_once(SPI1_Tx);

            NSS_disable();

            state = EXECUTE_1;
        } else if (EXECUTE_1 == state) {
            NSS_enable();

            SPI1_Tx = addr | rw;

            SPI_once(SPI1_Tx);

            state = EXECUTE_2;
        } else if (EXECUTE_2 == state) {
            if (rw)
                SPI1_Tx = 0x00;  // form feed, can be any value
            else
                SPI1_Tx = to_write;

            SPI1_Rx = SPI_once(SPI1_Tx);

            NSS_disable();

            state = DISPLAY_RESULTS;
        } else if (DISPLAY_RESULTS == state) {

            // *The LCD can only display 6 characters
            if (rw) 
                sprintf(str, "%.2x%c %.2x", addr, 'R', SPI1_Rx);
            else
                sprintf(str, "%.2x%c %.2x", addr, 'W', to_write);

            LCD_GLASS_Clear();
            LCD_GLASS_DisplayString((unsigned char *) str);

            wait_button_press();
            
            state = ENTER_CMD; // next state
        } else {
            state = ENTER_CMD;
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
//    GPIO_PinAFConfig(GPIOA, GPIO_PinSource5 | GPIO_PinSource12 | GPIO_PinSource11, GPIO_AF_SPI1); // MISO, PA11
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
    SPI_init.SPI_CPOL = SPI_CPOL_Low;    // CPOL = 0
    SPI_init.SPI_CPHA = SPI_CPHA_1Edge;    // CPHA = 0
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

void NSS_disable() {
    GPIO_SetBits(GPIOB, GPIO_Pin_5);  // NSS = 1, disable
}

void NSS_enable() {
    GPIO_ResetBits(GPIOB, GPIO_Pin_5);  // NSS = 0, enable
}

// {{{ SPI_once()
/*
 * SPI_once();
 *
 * SPI_once() is used to perform one SPI send/receive
 * operation.  The value to be sent is given as an
 * argument and the value received is the return value.
 *
 * It does not control the NSS pin, this is left to
 * the controlling block.
 *
 */

uint8_t SPI_once(const uint8_t SPI1_Tx) {
    uint8_t SPI1_Rx;
    unsigned int i;

    while (1) {
        if (SPI_I2S_GetFlagStatus(SPI1, SPI_I2S_FLAG_BSY)) {
            // kill some time
            asm("nop");
        } else if (SPI_I2S_GetFlagStatus(SPI1, SPI_I2S_FLAG_RXNE)) {
            // a transaction was completed

            // read the received data from the last transaction
            //SPI_I2S_ClearFlag(SPI1, SPI_I2S_FLAG_RXNE);

            SPI1_Rx = SPI_I2S_ReceiveData(SPI1);

            break;
        } else if (SPI_I2S_GetFlagStatus(SPI1, SPI_I2S_FLAG_TXE)) {
            // we can transmit more data

            // transmit a byte
            SPI_I2S_SendData(SPI1, SPI1_Tx);
            while (SPI_I2S_GetFlagStatus(SPI1, SPI_I2S_FLAG_TXE));
        }
    }

    for (i = 0; i < 1e5; i++)
        asm("nop");

    return SPI1_Rx;
}
// }}}

// vim:foldmethod=marker
