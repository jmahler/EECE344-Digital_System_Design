;
; NAME
; ----
;
; RCC utilities
;
; SYNOPSIS
; --------
;
;   // usage for a C program
;
;	// declare
;   extern void RCC_LCD_enable(void):
;	...
;
;   RCC_HSI_enable();
;   RCC_LCD_enable();
;
;   // Set the system clock to HSI
;   RCC_SYSCLK_HSI:
;
;   // reset PWR
;   RCC_PWR_enable();
;
;   RCC_SYSCFG_enable();
;
;   RCC_LSE_enable();
;
;
; AUTHOR
; ------
;
; Jeremiah Mahler <jmmahler@gmail.com>
;
; These utilites are used for the RCC registers.
; 
; These functions can be used from C as shown
; below for the RCC_LCD_enable() function.
;
  

; WARNING: These memory addresses are specific to the
; STM32L-Discovery (ARM Cortex M3) board and
; may not work with other configurations.
;
RCC_BASE		EQU 0x40023800	; base address for RCC_CR

RCC_CR			EQU 0x00  		; offset from RCC_BASE
; bits in RCC_CR
HSION			EQU 0x00000001  ; Bit 0
HSIRDY			EQU 0x00000002  ; Bit 1

RCC_CFGR		EQU 0x08  		; offset from RCC_BASE
SW				EQU	0x00000003  ; Bits 0 and 1
SW0				EQU	0x00000001  ; bit 0 of SW
SW1				EQU	0x00000002  ; bit 1 of SW
SWS				EQU	0x0000000C  ; Bits 2 and 3
SWS_HSI			EQU	0x00000004  ; bit 2 set, 3 clear

RCC_APB1RSTR	EQU 0x18  		; offset from RCC_BASE
LCD_RST			EQU	0x00000200  ; bit 9
PWR_RST			EQU	0x10000000  ; bit 28


RCC_APB1ENR		EQU 0x24  		; offset from RCC_BASE
LCD_EN			EQU	0x00000200  ; bit 9
PWR_EN			EQU	0x10000000  ; bit 28

RCC_APB2ENR		EQU 0x20  		; offset from RCC_BASE
SYSCFGEN		EQU	0x00000001  ; bit 0

RCC_CSR			EQU 0x34		; offset from RCC_BASE
LSEON			EQU 0x00000100 	; bit 8
LSERDY			EQU 0x00000200	; bit 9
; bit banded (BB) offsets for RCC_CSR
;PERIPH_BB_BASE	EQU 0x42000000
; 0x42000000 + ((0x23800 + 0x34)*32) + 8*4 = 0x424706A0
BB_RCC_CSR_LSEON 	EQU 0x424706A0
; 0x42000000 + ((0x23800 + 0x34)*32) + 9*4 = 0x424706A4
BB_RCC_CSR_LSERDY 	EQU 0x424706A4

	; declare public labels for functions
	PUBLIC RCC_HSI_enable
	PUBLIC RCC_SYSCLK_HSI
	PUBLIC RCC_LCD_enable
	PUBLIC RCC_PWR_enable
	PUBLIC RCC_SYSCFG_enable
	PUBLIC RCC_LSE_enable

	SECTION .text : CODE (2)  ; Place the following in the .text section

; Enable the HSI clock
RCC_HSI_enable:
	LDR r0, =RCC_BASE		; load base memory address

	; enable HSI by setting the HSION bit
	LDR r1, [r0, #RCC_CR]	; get current value
	LDR r2, =HSION			; bit mask at bit 0
	ORR r1, r1, r2			; set the HSION bit
	STR r1, [r0]			; store the new value

	; wait for HSI to become ready (HSIRDY == 1)
WAIT_HSIRDY
	LDR r1, [r0, #RCC_CR]	; load the current value
	AND r2, r1, #HSIRDY		; select the HSIRDY bit
	CMP r2, #HSIRDY			; is it set?
	BNE WAIT_HSIRDY			; if not set, keep waiting (branch)

	BX LR					; return to calling function


; Set the system clock to HSI
RCC_SYSCLK_HSI:
	LDR r0, =RCC_BASE		; load base memory address

	; set SW to 0:1
	LDR r1, [r0, #RCC_CFGR]	; get current value
	LDR r2, =SW				; load bit mask for SW bits
	BIC r3, r1, r2			; clear both SW bits
	LDR r2, =SW0			; load bit mask for SW0 bit
	ORR r3, r3, r2			; set the SW0 bit
	STR r3, [r0, #RCC_CFGR]	; store the new value

	; wait until status (SWS) is updated
	LDR r2, =SWS			; load bit mask for SWS bits
	LDR r3, =SWS_HSI		; load bit mask for SWS_HSI bits
WAIT_SWS_HSI
	LDR r1, [r0, #RCC_CFGR]	; get current value
	AND r4, r1, r2			; select the bits we are interested in
	CMP r4, r3				; compare to the HSI enabled bits
	BNE WAIT_SWS_HSI		; branch if HSI not set yet

	BX LR					; return to calling function

; enable and reset the LCD
RCC_LCD_enable:
	LDR r0, =RCC_BASE		; load base memory address

	; enable the LCD
	LDR r1, [r0, #RCC_APB1ENR]	; get the current value
	LDR r2, =LCD_EN				; load the LCD bit mask
	ORR r1, r1, r2				; set the bits
	STR r1, [r0, #RCC_APB1ENR]	; store the new value

	; reset the LCD
	LDR r1, [r0, #RCC_APB1RSTR]	; get the current value
	LDR r2, =LCD_RST		; load the LCD bit mask
	ORR r1, r1, r2			; set the LCD_RST bit
	STR r1, [r0, #RCC_APB1RSTR]	; store the new value
	BIC r1, r1, r2			; clear the LCD_RST bit
	STR r1, [r0, #RCC_APB1RSTR]	; store the new value

	BX LR					; return to calling function

RCC_PWR_enable:

	; enable PWR
	LDR r1, [r0, #RCC_APB1ENR]	; get the current value
	LDR r2, =PWR_EN				; load the PWR bit mask
	ORR r1, r1, r2				; set the bits
	STR r1, [r0, #RCC_APB1ENR]	; store the new value

	; reset PWR
	LDR r0, =RCC_BASE			; load base memory address
	LDR r1, [r0, #RCC_APB1RSTR]	; get the current value
	LDR r2, =PWR_RST			; load the PWR_RST bit mask
	ORR r1, r1, r2				; SET the bit
	STR r1, [r0, #RCC_APB1RSTR]	; store the new value
	BIC r1, r1, r2				; clear the bit
	STR r1, [r0, #RCC_APB1RSTR]	; store the new value

	BX LR						; return to calling function

RCC_SYSCFG_enable:

	; enable SYSCFG
	LDR r1, [r0, #RCC_APB2ENR]	; get the current value
	LDR r2, =SYSCFGEN			; load the bit mask
	ORR r1, r1, r2				; set the bits
	STR r1, [r0, #RCC_APB2ENR]	; store the new value

	BX LR						; return to calling function

RCC_LSE_enable:

	; enable the LSE
	LDR r0, =BB_RCC_CSR_LSEON	; load the address
	MOV r2, #1					; to set bit
	STR r2, [r0]				; store the new bit

	; wait for it to become ready
	LDR r0, =BB_RCC_CSR_LSERDY	; load the address
	MOV r2, #1					; bit mask used to check equality
WAIT_LSERDY
	LDR r1, [r0]				; load the current bit value
	CMP r1, r2					; compare bit to 1
	BNE WAIT_LSERDY				; keep waiting if not equal to 1
	; LSERDY == 1 (it's ready)

	BX LR						; return to calling function

; LSERDY (== 1)

	BX LR						; return to calling function

	END						; End of assembly file
