
; bit masks for N and V, see below for meaning
V_BIT EQU 0x00000010
N_BIT EQU 0x00000020

	PUBLIC saddsub

SECTION .text : CODE (2)
;
; uint32_t saddsub(add_or_sub, uint_32t A, uint_32t B);
;
;
; @arg bool      (1) ? (A - B) : (A + B)
; @arg uint_32t  number A
; @arg uint_32t  number B
;
; @return  XXXX XXXX XXXX XXNV AAAA AAAA AAAA AAAA (32 bits)
;  where N is 1 if negative, 0 otherwise
;        V is 1 if overflow occurred, 0 otherwise
;        A is the number with MSB at the left
;        X don't care
;
;
; XXX TODO
;  saddsub() is a "special" addition/subtraction function.
;  It adds the two numbers, A and B, then zeros out the
;  16 bits of the 32 bit data.
;  And in bits 16 and 17 (0 offset) it stores the overflow (V)
;  and sign (N) status from the CPSR register.
;
saddsub
	CMP r0, #0
	BEQ _ADD

	; shift the numbers in to the high 4 bits
	LSL r1, #28
	LSL r2, #28

    ; The following add/subtract operation shifts
    ; the result in to the lower 16 bits and
    ; fills the upper 16 bits with zeros.
_SUB:
	;SUB r1 r1 r2  ; r1 = r1 + r2
	SUBS r0, r1, r2, RSR, #28  ; r1 = r1 + r2
	B _DONE;
_ADD:
	;ADD r1 r1 r2  ; r1 = r1 - r2
	ADDS r0, r1, r2, RSR, #28  ; r1 = r1 + r2
_DONE:
    ; add/sub done, and upper 16 bits zero

    ; set the overflow (V) and sign bit (N)
    BVC _V_DONE     ; skip if doesn't need to be set
    LDR r1, =V_BIT  ; V bitmask
    ORR r0, r0, r1  ; apply bitmask, preserving pervious values
_V_DONE:
    BPL _N_DONE     ; skip if doesn't need to be set
    LDR r1, =N_BIT  ; N bitmask
    ORR r0, r0, r1  ; apply bitmask, preserving previous values
_N_DONE:

    ; return value in r0
    BX LR		; return

