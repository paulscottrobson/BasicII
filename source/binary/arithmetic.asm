; *******************************************************************************************
; *******************************************************************************************
;
;		Name : 		arithmetic.asm
;		Purpose : 	Simple binary operators 
;		Date :		2nd June 2019
;		Author : 	paul@robsons.org.uk
;
; *******************************************************************************************
; *******************************************************************************************

; *******************************************************************************************
;
;								32 bit add / Concatenate strings
;
; *******************************************************************************************

Binary_Add: ;; + 
	lda 	EXSPrecType+0,x 					; check both same type
	eor 	EXSPrecType+2,x
	bmi 	_BATypeError
	lda 	EXSPrecType+0,x 					; see if they are strings
	bmi 	_BAConcatenateString 				; if so , do the concatenation code.
	clc
	lda		EXSValueL+0,x
	adc 	EXSValueL+2,x
	sta 	EXSValueL+0,x
	lda		EXSValueH+0,x
	adc 	EXSValueH+2,x
	sta 	EXSValueH+0,x
	rts
	;
_BATypeError:
	jsr 	ReportError
	.text 	"+ operator can't mix types",$00
	;
_BALengthError:
	jsr 	ReportError
	.text 	"String too long",$00
	;
	;		String concatenation
	;
_BAConcatenateString:
	lda 	EXSValueL+0,x 						; save pointers in DTemp1/DTemp2
	sta 	DTemp1
	lda 	EXSValueL+2,x
	sta 	DTemp2
	nop

; *******************************************************************************************
;
;											 32 bit subtract
;
; *******************************************************************************************

Binary_Subtract: ;; - 
	jsr 	CheckBothNumeric 					; check both values are numeric
	sec
	lda		EXSValueL+0,x
	sbc 	EXSValueL+2,x
	sta 	EXSValueL+0,x
	lda		EXSValueH+0,x
	sbc 	EXSValueH+2,x
	sta 	EXSValueH+0,x
	rts

; *******************************************************************************************
;
;									Logical shift right
;
; *******************************************************************************************

Binary_ShiftRight: ;; >>
	jsr 	CheckBothNumeric 					; check both values are numeric
	lda 	EXSValueL+2,x
	and 	#63
	beq		_Binary_SRExit
_Binary_SRLoop:
	lsr 	EXSValueH+0,x
	ror 	EXSValueL+0,x
	dec 	a
	bne 	_Binary_SRLoop
_Binary_SRExit:
	rts

; *******************************************************************************************
;
;									Logical shift left
;
; *******************************************************************************************

Binary_ShiftLeft: ;; << 
	jsr 	CheckBothNumeric 					; check both values are numeric
	lda 	EXSValueL+2,x
	and 	#63
	beq		_Binary_SLExit
_Binary_SLLoop:
	asl 	EXSValueL+0,x
	rol 	EXSValueH+0,x
	dec 	a
	bne 	_Binary_SLLoop
_Binary_SLExit:
	rts
