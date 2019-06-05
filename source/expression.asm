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
;		Pre-evaluate preparation. Called once per *command* at the start, this resets
;		the temporary string pointer. Strings are only "firmed up" when they are assigned
;		to a string variable or array element.
;
;		So G/C should be reduced because intermediate strings generated in expression
;		evaluation are not maintained, only those that lead to final assignment to something.
;
;		Any m/c routines that use a string should be aware of this. Strings that are not in
;		variables only exist in the lines where they are created.
;
; *******************************************************************************************

EvaluateReset:
		ldy 	#BlockHighMemoryPtr 		; reset temp store pointer, start at high memory.
		lda 	(DBaseAddress),y
		sec 								; allocate 256 bytes down. This gives clear space to
		sbc 	#256 						; 'concrete' a string later on as must be 255 chars or less
		sta 	DTempStringPtr 				; store as temporary string pointer start address.
		rts

; *******************************************************************************************
;
;										Base Evaluate.
;
;		Evaluate expression at (DCodePtr), returning value in YA, type in CS (1 = string)
;		This (and evaluatestring and evaluateinteger) are used when called from a keyword
;
;		For a number returns 32 bit in YA, for a string returns 16 bit address in the 
;		current page.
;
;		When calling from a non-base, e.g. inside a unary function, use EvaluateNext(X)
;		functions.
;
; *******************************************************************************************

Evaluate:
		ldx 	#EXSBase					; reset the stack base
		lda 	#0<<9 						; current precedence level, which is the lowest
											; fall through.

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
		;
		cmp 	#$1000 							; string constant ? 00xx
		bcc 	_ELStringConstant
		cmp 	#$2000 							; constant shift ? 1xxx
		bcc 	_ELConstantShift				
		bra 	_ELKeywordFunction 				; must be 2000-7FFF e.g. identifier or keyword.
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
		inc 	a 								; adding 2 goes to the start of the string (len byte)
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
		and 	#$F000 							; is it a binary operator keyword, 0010 tttx xxxx xxxx
		cmp 	#$2000
		bne 	_ELExit 						; no, exit.

		lda 	EXSPrecType,X 					; get current precedence level
		and 	#$7FFF 							; remove the type bit, so it's the actual level.
		sta 	DTemp1 							; save it.

		tya 									; get token back
		and 	#15<<9 							; mask out the precedence data.
		cmp 	DTemp1 							; compare against current level
		bcc 	_ELExit 						; if too low, then exit this level
		;
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
		pla 									; get operator token back
;
;		Call the keyword in A. The ID is the lower 9 bits.
;		
_ELExecuteA:		
		and 	#$01FF 							; keyword ID.
		asl 	a 								; double it as keyword vector table is word data
		txy 									; save X in Y
		tax 									; double keyword ID in X
		lda 	CommandJumpTable,x 				; this is the vector address
		tyx 									; restore X.
		sta 	_ELCallRoutine+1 				; Self modifying, will not work in ROM.
		;
_ELCallRoutine:
		jsr 	_ELCallRoutine 					; call the new address.
		bra 	_ELGotAtom 						; go round operator level again.
;
;		Exit - put type in C (CS=String) and value in YA.
;
_ELExit:
		lda 	EXSPrecType+0,x 				; put bit 15 - type bit - in carry flag
		asl 	a
		lda 	EXSValueL+0,x 					; put value in YA
		ldy 	EXSValueH+0,x
		rts
;
;		Code to handle non-constant atoms : - ( and Unary Functions 001xx and Identifiers 01xx
;
_ELKeywordFunction:
		cmp 	#$4000 							; identifier (e.g. variable) if in range $4000-$7FFF
		bcs 	_ELVariable 					; (we've already discounted 8000-FFFF)
		;
		cmp 	#minusTokenID 					; special case keywords -(atom) (expression)
		beq 	_ELMinusAtom
		cmp 	#lparenTokenID
		beq 	_ELParenthesis
		;
		tay 									; save token in Y
		and 	#$FE00 							; look for 0011 101x ? i.e. a unary function.
		cmp 	#$3A00 							; if it isn't then exit
		bne 	_ELExit
;
;		Handle Unary Function
;
_ELUnaryFunction:
		inc 	DCodePtr 						; skip over the unary function token, which is in Y
		inc 	DCodePtr
		tya 									; get token back
		bra 	_ELExecuteA 					; and execute it using the lower 9 bits of the token.
;
;		Handle variable (sequence of identifier tokens)
;
_ELVariable:
		lda 	(DCodePtr)						; get first token
		pha 									; save on stack.
		jsr 	FindVariable 					; does the variable exist ?
		bcs 	_ELUnknownVariable				; if not, goto error.

		lda 	(DVariableDataAddress) 			; copy value into expression stack
		sta 	EXSValueL+0,x
		ldy 	#2
		lda 	(DVariableDataAddress),y
		sta 	EXSValueH+0,x

		pla 									; get the first token back off the stack.
		and 	#$1000 							; non-zero if it is a string.
		asl 	EXSPrecType+0,x 				; shift the prectype left
		adc 	#$FF00 							; put string bit into the carry bit
		ror 	EXSPrecType+0,x 				; rotate the string bit in.
		brl 	_ELGotAtom
;
;		Handle (Parenthesis)
;
_ELParenthesis:
		inc 	DCodePtr 						; skip over the ( token
		inc 	DCodePtr
		jsr 	EvaluateNext 					; calculate the value in parenthesis, using next space on the stack.
		jsr 	ExpectRightBracket 				; check for ) which should close the parenthesised expression.
		lda 	EXSValueL+2,x 					; copy the value in directly from level 2 to level 0.
		sta 	EXSValueL+0,x
		lda 	EXSValueH+2,x
		sta 	EXSValueH+0,x
		brl 	_ELGotAtom 						; and go round looking for the next binary operator
;
;		Handle -<atom> simple unary negation
;
_ELMinusAtom:
		inc 	DCodePtr 						; skip over the - token
		inc 	DCodePtr
		inx 									; make space
		inx
		lda 	#8<<9 							; means binary operation will be impossible.
		jsr 	EvaluateLevel 					; we just want the next atom. (does allow -(xxx))
		dex
		dex
		sec 									; do the subtraction 0-result to negate it.
		lda 	#0
		sbc 	EXSValueL+2,x
		sta 	EXSValueL+0,x
		lda 	#0
		sbc 	EXSValueH+2,x
		sta 	EXSValueH+0,x
		jmp 	_ELGotAtom

_ELUnknownVariable:
		#error	"Undeclared variable"

; *******************************************************************************************
;
;							Check both the L and R values are integers
;
; *******************************************************************************************

CheckBothNumeric:
		lda 	EXSPrecType+0,x 				; check bit 15 of both types are zero
		ora 	EXSPrecType+2,x
		bmi 	_CNError
		rts
_CNError:
		#error	"Numeric values expected"

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
		
; *******************************************************************************************
;
;		Calculate a result at the next stack level. This is used when expression evaluation
;		is required within expression evaluation, e.g. unary functions, parenthesis, negation
;		and so on. The value is in YA, or ESXValue?+2,x
;
; *******************************************************************************************

EvaluateNext:
		inx 									; stack forward
		inx
		lda 	#0<<9 							; lowest precedence.
		jsr 	EvaluateLevel 					; do at next level
		dex 									; reset stack
		dex
		rts

; *******************************************************************************************
;
;					Evaluate and check result is integer or string
;
;		  Four of these, one for each type, one for inline function/main function
;
; *******************************************************************************************

EvaluateInteger:
		jsr 	Evaluate
		bcs 	EIType
		rts
EIType:		
		#error 	"Number expected"

EvaluateNextInteger:
		jsr 	EvaluateNext
		bcs 	EIType
		rts

EvaluateString:
		jsr 	Evaluate
		bcc 	ESType
		rts
ESType:		
		#error 	"String expected"

EvaluateNextString:
		jsr 	EvaluateNext
		bcc 	ESType
		rts

