; *******************************************************************************************
; *******************************************************************************************
;
;		Name : 		basic.asm
;		Purpose : 	Basic start up
;		Date :		2nd June 2019
;		Author : 	paul@robsons.org.uk
;
; *******************************************************************************************
; *******************************************************************************************

StartOfBasicCode:

	.include "temp/tokens.inc"						; tokens include file (generated)
	.include "temp/block.inc"						; block constants include file (generated)
	.include "data.asm" 							; data definition.
	.include "expression.asm"
	.include "binary/arithmetic.asm"				; binary arithmetic/string operators
	.include "binary/bitwise.asm"
	.include "binary/comparison.asm"
	.include "binary/divide.asm"
	.include "binary/multiply.asm"

; *******************************************************************************************
;
;							Enter BASIC / switch to new instance
;
;	A 	should be set to the page number (e.g. the upper 8 bits)
;	X 	is the base address of the BASIC workspace (lower 16 bits)
;	Y 	is the end address of the BASIC workspace (lower 16 bits)
;
;	Assumes S and DP are set. DP memory is used but not saved on instance switching.
;
; *******************************************************************************************

SwitchBasicInstance:
	rep 	#$30 									; 16 bit AX mode.
	and 	#$00FF 									; make page number 24 bit
	sta 	DPageNumber 							; save page, base, high
	stx		DBaseAddress
	sty 	DHighAddress

	xba 											; put the page number (goes in the DBR) in B
	pha 											; then copy it into B.
	plb
	plb 

	ldy 	#BlockHighMemoryPtr 					; reset temp store pointer
	lda 	(DBaseAddress),y
	sec 											; allocate 256 bytes
	sbc 	#256
	sta 	DTempStringPtr 							; store as temporary string pointer.

	lda 	#$4100+8 								; initialise Code Pointer
	sta 	DCodePtr 
	ldx 	#EXSBase
	lda 	#0<<9 									; current precedence level.
	nop
	jsr 	EvaluateLevel 							; evaluate it.
	nop
halt1:
	cop 	#0
	bra 	halt1

IllegalToken:
	jsr 	ReportError
	.text 	"Bad token",0
SyntaxError:
	jsr 	ReportError
	.text 	"Syntax Error",0
	
ReportError:
	nop
	bra 	ReportError
