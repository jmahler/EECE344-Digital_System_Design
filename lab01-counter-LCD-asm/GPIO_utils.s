;
; NAME
; ----
;
; GPIO_utils - utilities for the GPIO of the ARM Cortex-M3
;
; SYNOPSIS
; --------
;
;  // usage from C
;  extern void config_PB6_out(void);
;  ...
;
;  // Configure PB6 of GPIOB as an output
;  // On the STML32L-Discovery this pin has a blue LED.
;  config_PB6_out();
;  
;  PB6_set();
;  PB6_clear();
;  PB6_toggle();
;
; AUTHOR
; ------
; 
;   Jeremiah Mahler <jmmahler@gmail.com>
;


; base addresses and offsets for memory addresses
;
; WARNING: These addresses are specific to the
; ARM Cortex-M3 used on the STM32L-Discovery board
; and may not work with other configurations.
;
; variables with 'BB' involve "bit banding"
; Refer to [Pg. 43, ST_REF] and [Pg. 46, ARM_TECH] for
; a description of bit banding and the offset calculations.
; (REFERENCES given at the end of this file)
;
RCC_BASE	EQU 0x40023800
AHBENR		EQU 0x1C

GPIOB_BASE	EQU 0x40020400
MODER		EQU 0x00
IDR			EQU 0x10

ODR			EQU 0x14
ODR6		EQU 0x00000040  ; bit 6
;PERIPH_BB_BASE	EQU 0x42000000
; bit banded (BB) access to GPIOB_ODR6
; PERPIPH_BB_BASE + (((GPIOB_BASE - GPIO_BASE) + ODR) * 32) + Bit6*4 =0x42408298
; 0x42000000 + ((0x20400 + 0x14) * 32) + 6*4 = 0x42408298
BB_GPIOB_ODR6 EQU 0x42408298

BSRR		EQU 0x18
BR6			EQU 0x00400000  ; bit 22, set
BS6			EQU 0x00000040  ; bit 6, clear
; 0x42000000 + ((0x20400 + 0x18) * 32) + 6*4 = 0x42408318
BB_GPIOB_BS6 EQU 0x42408318
; 0x42000000 + ((0x20400 + 0x18) * 32) + 22*4 = 0x42408358
BB_GPIOB_BR6 EQU 0x42408358


; bit masks
BIT2		EQU 0x00000002
BIT12		EQU 0x00001000
BIT12_13	EQU 0x00003000

	; public labels for these functions
	PUBLIC config_PB6_out
	PUBLIC PB6_clear
	PUBLIC PB6_set
	PUBLIC PB6_toggle

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

PB6_clear:
	;  GPIOB->BSRRH = 1<<6;  // clear PB6
;	LDR r0, =GPIOB_BASE		; load GPIOB_BASE memory address
;	LDR r2, =BR6			; load the bitmask
;	STR r2, [r0, #BSRR]		; store new value
	; bit banded version
	LDR r0, =BB_GPIOB_BR6	; the bit band alias address
	MOV r2, #1				; to set the bit	
	STR r2, [r0]			; store the new bit

	BX LR					; Return to calling function

PB6_set:
	;  GPIOB->BSRRL = 1<<6;  // set PB6
	;LDR r0, =GPIOB_BASE	; load GPIOB_BASE memory address
	;LDR r2, =BS6			; load the bitmask
	;STR r2, [r0, #BSRR]	; store new value
	; bit banded version
	LDR r0, =BB_GPIOB_BS6	; the bit band alias address
	MOV r2, #1				; to set the bit	
	STR r2, [r0]			; store the new bit

	BX LR					; Return to calling function

PB6_toggle:
;	LDR r0, =GPIOB_BASE		; load GPIOB_BASE memory address
;	LDR r1, [r0, #ODR]		; load value
;	LDR r2, =ODR6			; load the bit mask
;	EOR r1, r1, r2			; toggle the bit
;	STR r1, [r0, #ODR]		; store the new value
	; bit banded version
	LDR r0, =BB_GPIOB_ODR6	; load GPIOB_BASE memory address
	LDR r1, [r0]			; load value
	MOV r2, #1				; load the bit mask
	EOR r1, r1, r2			; toggle the bit
	STR r1, [r0]			; store the new value

	BX LR					; Return to calling function


	END						; End of assembly file

;
; REFERENCES:
;
;  [ARM_TECH]  Cortex-M3 - Technical Reference Manual, Revision r2p1, 2010
;			   http://www.arm.com
;
;  [ST_REF]  RM0038 Reference manual - STM32L151xx, STM32L152xx, ..., 2012
;			 http://www.st.com
;
