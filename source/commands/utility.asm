; *******************************************************************************************
; *******************************************************************************************
;
;		Name : 		utility.asm
;		Purpose : 	Things that don't belong anywhere else.
;		Date :		5th June 2019
;		Author : 	paul@robsons.org.uk
;
; *******************************************************************************************
; *******************************************************************************************

; *******************************************************************************************
;
;						Assert <expr> causes error if <expr> is zero
;
; *******************************************************************************************

Function_ASSERT: ;; assert
		jsr 	EvaluateInteger 			; something that returns an integer.
		sty 	DTemp1 						; check if result is zero.
		ora 	Dtemp1
		beq 	_FAssFail
		rts
_FAssFail:
		#error 	"assert failed"

