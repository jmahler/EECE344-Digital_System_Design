;
; RTC utilities
;
; author: Jeremiah Mahler <jmmahler@gmail.com>
; last modified: 2012-19-Feb
;
; These utilites are used for the RTC registers.
; 
; These functions can be used from C as shown
; below for the RCC_LCD_enable() function.
;
;	// declare
;   extern void RTC_access_enable(void):
;	// call
;   RTC_access_enable():
;  

; WARNING: These memory addresses are specific to the
; STM32L-Discovery (ARM Cortex M3) board and
; may not work with other configurations.
;

RTC_BASE		EQU 0x40002800

RTC_CR			EQU 0x00
RTC_DR			EQU 0x04
RTC_ISR			EQU 0x0C
RTC_PRER		EQU 0x10
RTC_WUTR		EQU 0x14
RTC_CALIBR		EQU 0x18
RTC_ALRMR		EQU 0x1C

; Other bases beyond RTC are needed as well
RCC_BASE		EQU 0x40023800	; base address for RCC_CR
RCC_APB1ENR		EQU 0x24  		; offset from RCC_BASE
PWREN			EQU 0x10000000 	; bit 28
RCC_CSR			EQU 0x34		; offset from RCC_BASE
RTCSEL			EQU	0x00030000	; bits 16 and 17
RTCSEL_LSE		EQU	0x00010000	; [0:1]
RTCSEL_LSI		EQU	0x00020000	; [1:0]
RTCEN			EQU	0x00400000	; bit 22

PWR_BASE		EQU 0x40007000	; base address for PWR_BASE
PWR_CR			EQU 0x00		; offset from PWR_BASE
DBP				EQU 0x00000100	; DBP, bit 8

RTC_WPR			EQU 0x24

	; declare public labels for functions
	PUBLIC RTC_access_enable

	SECTION .text : CODE (2)  ; Place the following in the .text section

; RTC_access_enable
;
; Enabling access to the RTC is a somewhat complicated
; process and this function takes care of all the steps.
; Currently it is configured to use the LSE clock but this
; could be changed if needed.
;
RTC_access_enable:

	; 1. Enable the power interface clock by setting the
	; PWREN bits in the RCC_APB1ENR register [Pg. 59 REFMAN]
	LDR r0, =RCC_BASE			; load base memory address
	LDR r1, [r0, #RCC_APB1ENR]	; load the current value
	LDR r2, =PWREN				; load bitmask
	ORR r1, r1, r2				; set the bit
	STR r1, [r0, #RCC_APB1ENR]	; store the new value

	; 2. Set the DBP bit in the PWR_CR register [Pg. 59, REFMAN]
	LDR r0, =PWR_BASE			; load base memory address
	LDR r1, [r0, #PWR_CR]		; load the current value
	LDR r2, =DBP				; load the bitmask
	ORR r2, r1, r2				; set the bit
	STR r2, [r0, #PWR_CR]		; store the new value

	; 3. Select the RTC clock source through RTCSEL[1:0] bits
	; in RCC_CSR register [Pg. 59, REFMAN]
	LDR r0, =RCC_BASE			; load base memory address
	LDR r1, [r0, #RCC_CSR]		; load the current value
	LDR r2, =RTCSEL				; load the bit mask
	; The LSE clock is chosen here, could also use the LSI, etc
	BIC r1, r1, r2				; clear the RTCSEL bits
	LDR r2, =RTCSEL_LSE			; load the bit mask
	ORR r1, r1, r2				; set the bits
	STR r1, [r0, #RCC_CSR]		; store the new value

	; 4. Enable the RTC clock by programming the RTCEN bit
	; in the RCC_CSR register.
	LDR r0, =RCC_BASE			; load base memory address
	LDR r1, [r0, #RCC_CSR]		; load the current value
	LDR r2, =RTCEN				; bit mask
	ORR r1, r1, r2				; set the bit
	STR r1, [r0, #RCC_CSR]		; store the new value

	; disable write protection [Pg. 441, REFMAN]
	LDR r0, =RTC_BASE		; load base memory address
	LDR r1, =0xCA			; bits for step #1
	STRB r1, [r0, #RTC_WPR]	; store the new value
	LDR r1, =0x53			; bits for step #2
	STRB r1, [r0, #RTC_WPR]	; store the new value

	BX LR					; return to calling function


	END						; End of assembly file

;
;  REFERENCES:
;
;  [REFMAN]  RM0038 Reference Manual, STM32L151xx, STM32L152xx,
;			 STM32L162xx, advanced ARM-based 32-bit MCUs
;			 http://www.st.com/internet/com/TECHNICAL_RESOURCES/TECHNICAL_LITERATURE/REFERENCE_MANUAL/CD00240193.pdf
;
