; *******************************************************************************************
; *******************************************************************************************
;
;		Name : 		utility.asm
;		Purpose : 	General Utility functions
;		Date :		4th June 2019
;		Author : 	paul@robsons.org.uk
;
; *******************************************************************************************
; *******************************************************************************************

; *******************************************************************************************
;
;								Report Error, at return address
;
; *******************************************************************************************
	
ErrorHandler:
		rep 	#$30 						; in case we changed it.
		nop
_EH1:	bra 	_EH1

; *******************************************************************************************
;
;				Default handler for keywords, produces error if not implemented
;
; *******************************************************************************************

IllegalToken:
		#error 	"Illegal Token"

; *******************************************************************************************
;
;										Report Syntax Error
;
; *******************************************************************************************

SyntaxError:
		#error 	"Syntax Error"

; *******************************************************************************************
;
;								Check what the next token is
;
; *******************************************************************************************

ExpectToken:
		cmp 	(DCodePtr) 					; does it match the next token
		bne 	_CTKError					; error if not
		inc 	DCodePtr 					; skip the token
		inc 	DCodePtr
		rts	
_CTKError:
		#error	"Missing token"

; *******************************************************************************************

ExpectRightBracket:							; shorthand because right parenthesis common
		pha
		lda 	#rparenTokenID
		jsr 	ExpectToken
		pla
		rts

ExpectComma:
		pha
		lda 	#commaTokenID 				; shorthand because comma is used a fair bit.
		jsr 	ExpectToken
		pla
		rts

