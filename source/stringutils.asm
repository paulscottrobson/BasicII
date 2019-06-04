; *******************************************************************************************
; *******************************************************************************************
;
;		Name : 		stringutils.asm
;		Purpose : 	String Utilities
;		Date :		4th June 2019
;		Author : 	paul@robsons.org.uk
;
; *******************************************************************************************
; *******************************************************************************************

; *******************************************************************************************
;
;		Allocate temporary storage for string of length A, return address in A.
;
; *******************************************************************************************

StringTempAllocate:
		and 	#$00FF 						; check it's a byte size
		eor 	#$FFFF 						; 2's complement add to temporary pointer.
		clc 								; this adds one, for the length.
		adc 	DTempStringPtr
		sta 	DTempStringPtr
		pha 
		lda 	#$0000
		sep 	#$20 						; zero the length of this new string.
		sta		(DTempStringPtr)
		rep 	#$20
		pla
		sta 	DStartTempString 			; start of temporary string.
		sta 	DCurrentTempString 			; save current temporary string
		inc 	DCurrentTempString 			; step over length byte.
		rts

; *******************************************************************************************
;
;			  Copy String at A to the most recently allocated temporary storage.
;
; *******************************************************************************************

StringCreateCopy:
		tay 								; put pointer to string in Y
		lda 	$0000,y 					; read the first byte, the length.
		and 	#$00FF 						; mask out the length byte.
		beq 	_SCCExit 					; do nothing if length zero.
		phx 								; save X and put the character count in X
		tax
		sep 	#$20 						; switch to 8 bit mode.
_SCCCopy:
		iny 								; advance and read (first time skips length)
		lda 	$0000,y
		sta 	(DCurrentTempString) 		; write into target
		inc 	DCurrentTempString 			; bump target pointer
		lda 	(DStartTempString)			; one more character
		inc 	a
		sta 	(DStartTempString)
		dex 								; do X times
		bne 	_SCCCopy
		rep 	#$20 						; switch back to 16 bit mode
		plx
_SCCExit:
		rts
