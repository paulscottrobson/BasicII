; *******************************************************************************************
; *******************************************************************************************
;
;		Name : 		run.asm
;		Purpose : 	Run command.
;		Date :		5th June 2019
;		Author : 	paul@robsons.org.uk
;
; *******************************************************************************************
; *******************************************************************************************

; *******************************************************************************************
;
;								End the Program
;
; *******************************************************************************************

Function_END: ;; end
		cop 	#0

; *******************************************************************************************
;
;								Run the program
;
; *******************************************************************************************

Function_RUN: ;; run
		lda 	DBaseAddress 				; work out the first instruction.
		clc 
		adc 	#BlockProgramStart 			; so run from here.
		;
		;		Run instruction at A.
		;
_FRun_NextLineNumber:
		tay 								; put in Y
		lda 	$0000,y 					; read the link token.
		beq 	Function_END 				; if zero, off the end of the program
		lda 	$0002,y 					; read the line number
		sta 	DLineNumber 				; and save it.
		tya 								; get address back
		clc 								; skip over the link/line number
		adc 	#4
		sta 	DCodePtr
		;
		;		Next instruction.
		;
_FRun_NextInstruction:
		jsr 	EvaluateReset 				; start new instruction reset (temp string storage)
		;
		lda 	(DCodePtr)					; what's next
		beq 	_FRun_EndInstruction		; if end of this line, then go to next line.
		cmp 	#colonTokenID 				; colon then skip
		beq 	_FRun_Colon

		tay 								; save in Y
		and 	#$E000 						; see if it is a keyword. 001x
		cmp 	#$2000 						
		bne 	_FRun_TryLET 				; if not, try LET as a default.
		;
		tya 								; get token back
		and 	#$01FF 						; mask out keyword
		asl 	a 							; double it into X
		tax
		;
		inc 	DCodePtr 					; skip over token
		inc 	DCodePtr 	
		jsr 	(CommandJumpTable,x)		; and call that routine
		bra 	_FRun_NextInstruction 		; do the following instruction.
		;
		;		Skip over colon.
		;
_FRun_Colon:
		inc 	DCodePtr 					; skip over token
		inc 	DCodePtr 	
		bra 	_FRun_NextInstruction 		; do the following instruction.
		;
		;		Maybe we can do a LET , is there an identifier ?
		;
_FRun_TryLET:
		jsr 	Function_LET 				; try as a LET.
		bra 	_FRun_NextInstruction 		; if we get away with it, go to next instruction.
		;
		;		End of instruction. Go to next line.
		;
_FRun_EndInstruction:
		lda 	DCodePtr 					; address of terminating NULL.
		inc 	a 							; go to link for next line
		inc 	a
		bra 	_FRun_NextLineNumber
