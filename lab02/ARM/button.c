#include "button.h"

void enable_button()
{
	int i = 0;

	// [Pg. 144]{STRM0038}
	// The RI registers can only be accessed when the comparator
	// interface clock is enabled.
	RCC->APB1ENR |= RCC_APB1ENR_COMPEN;

	// [Pg. 274]{STRM0038}

	// 1.) enable comparator 1
	COMP->CSR |= COMP_CSR_CMP1EN;

	// 2.) wait until comparator is ready
	while (i++ < 5e5);	 // a cheap timer. TODO: build a better one

	// 3.) set the SCM bit in the RI_ASCR1 register	
	RI->ASCR1 |= RI_ASCR1_SCM;

	// 4.a) close the VCOMP ADC switch
	RI->ASCR1 |= RI_ASCR1_VCOMP;

	// 4.b) close the I/O analog switch 
	RI->ASCR1 |= RI_ASCR1_CH_0;

	// Then the value can be read in COMP_CSR COMP1_OUT
}

inline
unsigned int button_pressed() {
	return (COMP->CSR & COMP_CSR_CMP1OUT);
}
