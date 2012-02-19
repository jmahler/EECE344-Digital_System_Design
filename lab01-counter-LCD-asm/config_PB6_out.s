













































































;
; config_PB6_out()
;
; author: Jeremiah Mahler <jmmahler@gmail.com>
; last modified: 2012-18-Feb
;
; This function is used to configure pin PB6 of the
; general purpose output port B (GPIOB) as an output
; so that it can be set or cleared.
; On the STM32L-Discovery this would normally be used
; to blink the blue LED on this pin.
;
; To use this code from C you must declare an external function:
;
;   extern void config_PB6_out(void);
;
; Then configure the port by calling the function:
;
;   config_PB6_out();
;
; And then the output can be clear/set using:
;
;   GPIOB->BSRRH = 1<<6;  // clear PB6
;   GPIOB->BSRRL = 1<<6;  // set PB6
;

; base addresses and offsets for memory addresses
;
; WARNING: These addresses are specific to the
; ARM Cortex-M3 used on the STM32L-Discovery board
; and may not work with other configurations.
;
RCC_BASE	EQU 0x40023800
AHBENR		EQU 0x1C

GPIOB_BASE	EQU 0x40020400
MODER		EQU 0x00

; bit masks
BIT2		EQU 0x00000002
BIT12		EQU 0x00001000
BIT12_13	EQU 0x00003000

	PUBLIC config_PB6_out	  ; our public label for this function
	SECTION .text : CODE (2)  ; Place the following in the .text section

config_PB6_out:
	; To configure PB6 as a general purpose output:
	;   1. enable port B
	;   2. configure GPIOB mode for output (bits 12 and 13)

	;  1. enable port B
	;
	;  RCC->AHBENR  |= RCC_AHBENR_GPIOBEN; // enable port B
	;
	LDR r0, =RCC_BASE		; load RCC_BASE memory address
	LDR r1, [r0, #AHBENR]	; get current value at [RCC_BASE + AHBENR]

	LDR r2, =BIT2			; mask needed to set bit 2
	ORR r1, r1, r2			; set bit 2

	STR r1, [r0, #AHBENR]	; store the new value

	;   2. configure GPIOB mode
	;
	;  GPIOB->MODER &= ~(0x03<<(2*6));     // clear 12 and 13
	;  GPIOB->MODER |= 0x01<<(2*6);        // set 12
	;
	LDR r0, =GPIOB_BASE		; load GPIOB_BASE memory address
	LDR r1, [r0, #MODER]	; get current value at [GPIOB_BASE + MODER]

	LDR r2, =BIT12_13		; mask for bits 12 and 13
	BIC r1, r1, r2			; clear bits 12 and 13

	LDR r2, =BIT12			; mask for bit 12
	ORR r1, r1, r2			; set bit 12

	STR r1, [r0, #MODER]	; store the new value

	BX LR					; Return to calling function

	END						; End of assembly file
