; *******************************************************************************************
; *******************************************************************************************
;
;		Name : 		expression.asm
;		Purpose : 	Expression Evaluation
;		Date :		2nd June 2019
;		Author : 	paul@robsons.org.uk
;
; *******************************************************************************************
; *******************************************************************************************









; *******************************************************************************************
;
;							Check both the L and R values are integers
;
; *******************************************************************************************

CheckNumeric:
		lda 	EXSPrecType+0,x 				; check bit 15 of both types are zero
		ora 	EXSPrecType+2,x
		bmi 	_CNError
		rts
_CNError:
		jsr 	ReportError
		.text	"Numeric value expected",0

; *******************************************************************************************
;
;							   Make the returned value an integer
;
; *******************************************************************************************

ResetTypeInteger:
		lda 	EXSPrecType+0,x 				; clear bit 15 of type, forcing an integer return.
		and 	#$7FFF
		sta 	EXSPrecType+0,x
		rts