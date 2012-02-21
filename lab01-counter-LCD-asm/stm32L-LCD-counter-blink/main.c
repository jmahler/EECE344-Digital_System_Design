/*
 * NAME
 * ----
 * 
 * lab project #1 - an LCD counter and blinking LED
 * 
 * INTRODUCTION
 * ------------
 *
 * This program was written for the STML32L-Discovery board
 * with the ARM Cortex-M3 chip.
 * It starts at zero and incriments a counter forever
 * while also displaying the current count on the LCD screen.
 * For each count the blue LED on pin PB6 is blinked.
 *
 * All of the initilization, excluding the LCD, is done
 * by calling functions which are written in pure assembly.
 * These also provide examples of how to use "bit banding"
 * in the peripheral bit band region.
 * 
 * More information about the STML32L-Discovery can be found
 * on ST's website [http://www.st.com/internet/evalboard/product/250990.jsp]
 * The LCD and other libraries which were used in this project
 * can also be found here.
 *
 * This project was completed as part of the class EECE 344,
 * Digital System Design, at Chico State [www.csuchico.edu]
 * during the Spring of 2012.
 *  
 * AUTHOR
 * ------
 *
 *   Jeremiah Mahler <jmmahler@gmail.com>
 *
 */

#include "stm32l1xx.h"
#include "stdio.h"
#include "discover_board.h"
#include "stm32l_discovery_lcd.h"

void  RCC_Configuration(void);
void  RTC_Configuration(void);

extern void config_PB6_out(void);
extern void RCC_HSI_enable(void);
extern void RCC_SYSCLK_HSI(void);
extern void RCC_LCD_enable(void);
extern void RCC_PWR_enable(void);
extern void RCC_SYSCFG_enable(void);
extern void RCC_LSE_enable(void);
extern void RTC_access_enable(void);
extern void PB6_set(void);
extern void PB6_clear(void);
extern void PB6_toggle(void);

int main() {
	unsigned int k = 0;  // used for counter
	unsigned short count = 0;
	char strDisp[20] ;

	// ### INITILIZATION ###

	// Enable the High Speed Internal (HSI) Clock
	RCC_HSI_enable();

	// Select the HSI for the SYSCLK
	RCC_SYSCLK_HSI();

	// Enable comparator clock LCD and PWR mngt
	RCC_LCD_enable();
	RCC_PWR_enable();

	// Enable SYSCFG
	RCC_SYSCFG_enable();

	// Allow access to the RTC
	// Also selects the RTCCLK as LSE
	RTC_access_enable();

	// LSE Enable,
	// this clock is needed for the RTCCLK and LCD
	RCC_LSE_enable();

	// Initializes the LCD
	LCD_GLASS_Configure_GPIO();
	LCD_GLASS_Init();

	// configure PB6 as an output
	config_PB6_out();

	// ### TOGGLE PB6, increment counter on LCD ###

	while(1) {
		k++;

		// Toggle at approximately 1 Hz
		if (k >= 10e5) {
			PB6_toggle();

			//sprintf(strDisp, "%d", ++count);  // decimal
			sprintf(strDisp, "%x", ++count);  // hex
			//sprintf(strDisp, "%o", ++count);  // octal

			LCD_GLASS_Clear();
			LCD_GLASS_DisplayString((unsigned char *) strDisp);

			k = 0; // reset counter
		}
	}
}

