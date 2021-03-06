; *******************************************************************************************
; *******************************************************************************************
;
;		Name : 		variable.asm
;		Purpose : 	Variable Handlers.
;		Date :		4th June 2019
;		Author : 	paul@robsons.org.uk
;
; *******************************************************************************************
; *******************************************************************************************

; *******************************************************************************************
;
;		Find variable at CodePtr. Return CS if it doesn't exist. If exists, save the
;		Variable Data Address in DVariableDataAddress and return Carry Clear, and
;		advance the token pointer past the identifier.
;
; *******************************************************************************************

FindVariable:
		lda 	(DCodePtr)					; get the first token
		cmp 	#$401B 						; $4001-$401A represent fast variables A-Z
		bcs 	_FVStandard 				; if >= then it is stored in the hashed entries.
		;
		;		Fast variable. We can do this dead quick :)
		;
		and 	#$001F 						; now 1-26
		dec 	a 							; now 0-25
		asl 	a 							; now 0-100
		asl 	a 							; and clears carry.
		adc 	#BlockFastVariables 		; address offset in block
		adc 	DBaseAddress 				; now contains the base address + offset + address
		sta 	DVariableDataAddress 		; save address
		inc 	DCodePtr 					; skip over token
		inc 	DCodePtr
		clc 								; and return CC == okay.
		rts
		;
		;		Okay ... it's a standard variable. First we find out which hash entry.
		;
_FVStandard:
		jsr 	VariableFirstTokenToHash 	; get the hash address
		sta 	DTemp1 						; put it in DTemp1
		;
		;		Now, search through the linked list.
		;
_FVNext:
		lda 	(DTemp1) 					; read the next link.
		beq 	_FVFail						; if zero, the variable does not exist.
		sta 	DTemp1 						; make this the one we are checking.

		ldy 	#2 							; get the address of the string into DTemp2
		lda 	(DTemp1),y
		sta 	DTemp2 
		;
		;		Compare the tokens at (DCodePtr) and (DTemp2)
		;
		ldy 	#0 							
_FVCompare:
		lda 	(DCodePtr),y 				; compare the two tokens
		cmp 	(DTemp2),y
		bne 	_FVNext 					; if they are different, go to the next list entry.
		iny 								; advance token pointer by 2
		iny
		and 	#$2000 						; check the continuation bit.
		bne 	_FVCompare 					; if set, then try the next two tokens, clear = match.
		lda 	(DCodePtr)					; push the first token on the stack
		pha
		;
		;		Advance code pointer past token.
		;
		tya 								; Y is the amount to advance it by.
		clc
		adc 	DCodePtr
		sta 	DCodePtr		
		;
		;		Check for array, by looking at the first token.
		;
		pla 								; restore first token
		and 	#$0800 						; is it an array.
		bne 	_FVIndexed 					; if so, need to calculate and apply the index.
		;
		lda 	DTemp1 						; copy current record + 6 to DVariableDataAddress
		clc
		adc 	#6
		sta 	DVariableDataAddress
		;
		clc 								; return with carry clear.
		rts

_FVFail:									; didn't find the right one, so return with CS.								
		sec
		rts
		;
		;		Handle Arrays
		;
_FVIndexed:
		lda 	DTemp1 						; address of the array record
		pha 								; save on stack
		jsr 	EvaluateNextInteger 		; this is the index.
		cpy 	#0 							; fail if upper word non zero.
		bne 	_FVIndexFail
		ply 								; array record into Y.
		cmp 	$0004,y 					; compare index vs highest index
		bcc 	_FVIndexOkay 				; if index <= highest it's okay.
		beq 	_FVIndexOkay
_FVIndexFail:		
		#error	"Bad Array Index"

_FVIndexOkay:
		asl 	a 							; multiply the index by 4
		asl 	a 							; also clearing the carry.
		sty 	DTemp1 						; add the address record
		adc 	DTemp1 	
		adc 	#6 							; add 6 for the header
		sta 	DVariableDataAddress 
		jsr 	ExpectRightBracket
		clc 								; return with carry clear
		rts

; *******************************************************************************************
;
;			Utility : given the first token in A, get the address of the hash link.
;										(Breaks DTemp1)
;
;		Note : if BasicBlock.HASHTABLESIZE is changed, then this will have to follow
;			   it as the "x 32" is done without multiplication for speed reasons.
;
; *******************************************************************************************

VariableFirstTokenToHash:
		pha 								; save token
		and 	#BlockHashMask 				; create a hash index
		asl 	a 							; double it, because it's a word address
		sta 	DTemp1 						; save it
		pla 								; restore first token.
		xba 								; type bits were in 11 and 12, now they're in 3 and 4
		and 	#$0018 						; isolate those type bits
		asl 	a 							; This makes A = type bits x 16
		asl 	a 							; A = type bits x 32 and clears carry.
		adc 	DTemp1 						; add offset in the table
		adc 	#BlockHashTable 			; now its an offset in the block
		adc 	DBaseAddress 				; now it's an address
		rts

; *******************************************************************************************
;
;		Create the variable named at Y, with a high index of A - e.g. it has A+1
;		units allocated to it.
;
; *******************************************************************************************

CreateVariable:
		phy 								; save the name on the stack.
		pha 								; save the high index on the stack.
		;
		;		Get the hash address.
		;
		lda 	$0000,y 					; first token of identifier
		jsr 	VariableFirstTokenToHash 	; convert to hash link address
		sta 	DSignCount 					; save in another temporary variable.
		;
		;		Get the size back,Work out the memory required
		;
		pla 								; restore size, push back
		pha
		inc 	a 							; one extra as it is 0..A
		asl 	a 							; 4 bytes
		asl 	a 							; also does CLC.
		adc 	#6 							; this is the header (link,name,size)
		sta 	DTemp1						; save total bytes required.
		;
		;		Allocate from low memory.
		;
		ldy 	#BlockLowMemoryPtr 			; get the address of the next free byte
		lda 	(DBaseAddress),y 			; save it on the stack for later.
		pha
		clc 								; add bytes required and write back
		adc 	DTemp1
		sta 	(DBaseAddress),y 			
		pla 								; DTemp2 now points to the variable.
		sta 	DTemp2
		;
		;		Erase the new variable memory.
		;
		ldy		#0 							; erase the new variable
_CRVErase:
		lda 	#$0000
		sta 	(DTemp2),y
		iny
		iny
		cpy 	DTemp1
		bne 	_CRVErase
		;
		;		Copy the name and high index into the new variable.
		;
		ldy 	DTemp2 						; Y is address of new variable.
		pla 								; restore the high index
		sta 	$0004,y
		pla 								; restore the name.
		sta 	$0002,y
		;
		;		Link it in to the variable list.
		;
		lda 	(DSignCount) 				; get the address in the current link.
		sta 	$0000,y 					; save as the link to the next
		tya 	
		sta 	(DSignCount)				; this record is the new head of list.
		rts
