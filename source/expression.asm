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
;		Evaluate a term/operator sequence at the current precedence level. A contains the
;		precedence level shifted 9 left (matching the keyword position). X contains the 
;		expression stack offset.
;
;		Returns value in YA and CS if string.
;
;		Precedence climber : See expression.py in documents
;
; *******************************************************************************************

EvaluateLevel:
		sta 	EXSPrecType+0,x 				; save precedence level, also sets type to integer.
		lda 	(DCodePtr)						; look at the next token
		beq 	_ELExpressionSyntax 			; EOL token, there's an error.
		bmi 	_ELConstant 					; 8000-FFFF constant.
		cmp 	#$1000 							; string constant ? 00xx
		bcc 	_ELStringConstant
		cmp 	#$2000 					
		bcc 	_ELConstantShift				; constant shift ? 1xxx
		bcs 	_ELKeywordFunction 				; must be 2000-7FFF e.g. identifier or keyword.
;
;		Branch to syntax error (expression missing)
;
_ELExpressionSyntax:	
		jmp 	SyntaxError
;
;		0000 0000 llll llll String constant.
;
_ELStringConstant:
		lda 	DCodePtr 						; get the address of the token
		inc 	a 								; adding 2, start of the string
		inc 	a 	
		sta 	EXSValueL+0,x 					; the LSB of the string.
		stz 	EXSValueH+0,x 					; the MSB is always zero.
		lda 	EXSPrecType+0,x 				; make type string
		ora 	#$8000
		sta 	EXSPrecType+0,x
		clc
		lda 	(DCodePtr) 						; add length to pointer to skip over
		adc 	DCodePtr
		sta 	DCodePtr
		bra 	_ELGotAtom
;
;		0001 cccc cccc cccc Constant shift
;
_ELConstantShift:
		sta 	DConstantShift 					; update constant shift
		inc 	DCodePtr 						; shift over constant shift
		inc 	DCodePtr 						; fall through to constant code.
;
;		1ccc cccc cccc cccc Constant Integer (with shift)
;
_ELConstant:
		lda 	(DCodePtr)						; get the token (for fall through)
		asl 	a 								; shift left, also gets rid of the high bit
		sta 	EXSValueL+0,x 					; this is the low word
		lda 	DConstantShift 					; get the constant shift
		and 	#$0FFF 							; mask off bits 12-15
		lsr 	a 								; rotate bit 0 into carry
		sta 	EXSValueH+0,x 					; this is the high word
		ror 	EXSValueL+0,x 					; rotate carry into the low word
		stz 	DConstantShift 					; reset the constant shift to zero.
		inc 	DCodePtr 						; skip over code pointer
		inc 	DCodePtr
;
;		Have the atom.
;
_ELGotAtom:
		lda 	(DCodePtr)						; get the next token.
		tay 									; save in Y, temporarily.
		and 	#$E000 							; is it a keyword, 001x xxxx xxxx xxxx
		cmp 	#$2000
		bne 	_ELExit 						; no, exit.

		lda 	EXSPrecType,X 					; get current precedence level
		and 	#$7FFF 							; remove the type bit.
		sta 	DTemp1 							; save it.

		tya 									; get token back
		and 	#15<<9 							; mask out the precedence data.
		cmp 	DTemp1 							; compare against current level
		bcc 	_ELExit 						; if too low, then exit back.
		phy 									; save operator token on stack.
		inc 	DCodePtr 						; skip over it
		inc 	DCodePtr

		clc 									; precedence data still in A, add 1 level to it
		adc 	#1<<9					
		inx 									; calculate the RHS at the next stack level.
		inx
		jsr 	EvaluateLevel 
		dex
		dex

		pla 									; get operator back
		and 	#$01FF 							; keyword ID.
		asl 	a 								; double it as keyword vector table is word data
		txy 									; save X in Y
		tax 									; double keyword ID in X
		lda 	CommandJumpTable,x 				; this is the vector address
		tyx 									; restore X.
		sta 	_ELCallRoutine+1 				; Self modifying, will not work in ROM.
_ELCallRoutine:
		jsr 	_ELCallRoutine
		bra 	_ELGotAtom 						; go round operator level again.
;
;		Exit - put type in C (CS=String) and value in YA.
;
_ELExit:
		lda 	EXSPrecType+0,x 				; put bit 15 in carry flag
		asl 	
		lda 	EXSValueL+0,x 					; put value in YA
		ldy 	EXSValueH+0,x
		rts
;
;		Code to handle non-constant atoms : - ( and Unary Functions 001xx and Identifiers 01xx
;
_ELKeywordFunction:
		inc 	DCodePtr 						; skip over the token/function/identifier
		inc 	DCodePtr
		cmp 	#minusTokenID
		beq 	_ELMinusAtom
		bra 	_ELKeywordFunction
;
;		Handle -<atom>
;
_ELMinusAtom:
		inx 									; make space
		inx
		lda 	#8<<9 							; means binary operation will be impossible.
		jsr 	EvaluateLevel
		dex
		dex
		sec 									; do the subtraction
		lda 	#0
		sbc 	EXSValueL+2,x
		sta 	EXSValueL+0,x
		lda 	#0
		sbc 	EXSValueH+2,x
		sta 	EXSValueH+0,x
		bra 	_ELGotAtom

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
		