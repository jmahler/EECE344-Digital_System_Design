#include "stm32l1xx.h"
#include "stdio.h"
#include "discover_board.h"
#include "stm32l_discovery_lcd.h"

void  RCC_Configuration(void);
void  RTC_Configuration(void);
extern void config_PB6_out(void);

int main() {
	unsigned int k = 0;  // used for counter
	unsigned short count = 0;
	char strDisp[20] ;

	// Configure RCC Clocks
	RCC_Configuration();

	// Configure RTC Clocks
	RTC_Configuration();

	// Initializes the LCD
	LCD_GLASS_Configure_GPIO();
	LCD_GLASS_Init();

	// configure PB6 as an output
	config_PB6_out();

	// ### TOGGLE PB6, increment counter on LCD
	while(1) {
		k++;

		// Toggle at approximately 1 Hz
		if (k == 5e5) {
			GPIOB->BSRRH = 1<<6;  // clear PB6
		} else if (k >= 1e6) {
			GPIOB->BSRRL = 1<<6;  // set PB6

			sprintf(strDisp, "%d", ++count);
			LCD_GLASS_Clear();
			LCD_GLASS_DisplayString( (unsigned char *) strDisp );

			k = 0; // reset counter
		}
	}
}

void RCC_Configuration(void)
{  
	// Enable HSI Clock
	RCC_HSICmd(ENABLE);

	// Wait till HSI is ready
	while (RCC_GetFlagStatus(RCC_FLAG_HSIRDY) == RESET)
	{}

	RCC_SYSCLKConfig(RCC_SYSCLKSource_HSI);

	RCC_MSIRangeConfig(RCC_MSIRange_6);

	// Enable  comparator clock LCD and PWR mngt
	RCC_APB1PeriphClockCmd(RCC_APB1Periph_LCD | RCC_APB1Periph_PWR, ENABLE);

	// Enable ADC clock & SYSCFG
	RCC_APB2PeriphClockCmd(RCC_APB2Periph_SYSCFG, ENABLE);
}


void RTC_Configuration(void)
{
	// Allow access to the RTC
	PWR_RTCAccessCmd(ENABLE);

	// Reset Backup Domain
	//RCC_RTCResetCmd(ENABLE);
	//RCC_RTCResetCmd(DISABLE);

	/* LSE Enable */
	RCC_LSEConfig(RCC_LSE_ON);

	/* Wait till LSE is ready */
	while (RCC_GetFlagStatus(RCC_FLAG_LSERDY) == RESET)
	{}

	RCC_RTCCLKCmd(ENABLE);

	/* LCD Clock Source Selection */
	RCC_RTCCLKConfig(RCC_RTCCLKSource_LSE);
}

