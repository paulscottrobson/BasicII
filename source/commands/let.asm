; *******************************************************************************************
; *******************************************************************************************
;
;		Name : 		let.asm
;		Purpose : 	Assignment Statement
;		Date :		5th June 2019
;		Author : 	paul@robsons.org.uk
;
; *******************************************************************************************
; *******************************************************************************************

Function_Let: ;; let
		lda 	(DCodePtr) 					; push the identifier token on the stack.
		pha
		jsr 	FindVariable 				; find the variable that we will set the value of.
		bcc		_FLetFound		

		;
		;		The variable doesn't exist, so we need to create it, except for arrays.
		;		
		nop
		
		;
		;		We have identified the variable, now see which type.
		;
_FLetFound:
		pla 								; token to A
		ldy 	DVariableDataAddress 		; push the target address on the stack
		phy
		and 	#$1000 						; check to see if it is a string assignment
		bne 	_FLetStringAssign
		;
		;		Assign to an integer.
		;
		lda 	#equalTokenID 				; check for the equal presence.
		jsr 	ExpectToken
		jsr 	EvaluateInteger 			; get an integer.
		tyx 								; result is now in XA
		ply 								; target address in Y
		sta 	$0000,y 					; save low word
		txa 								
		sta 	$0002,y 					; save high word
		rts 								; and complete.
		;
		;		Assign to a string.
		;
_FLetStringAssign:
		lda 	#equalTokenID 				; check for the equal presence.
		jsr 	ExpectToken
		jsr 	EvaluateString 				; get a string.
		jsr 	StringMakeConcrete			; make it a concrete string, allocate permanently
		ply 								; target address in Y
		sta 	$0000,y 					; set LSW
		lda 	#$0000
		sta 	$0002,y 					; clear LSW as its a string
		rts
