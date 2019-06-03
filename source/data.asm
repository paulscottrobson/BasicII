; ********************************************************************************
; ********************************************************************************
;
;		Name: 		data.asm
;		Purpose:	Data Description for Basic
;		Date:		2nd June 2019
;		Author:		Paul Robson (paul@robsons.org.uk)
;
; ********************************************************************************
; ********************************************************************************

; ********************************************************************************
;
;								This is the Zero Page Data
;
; ********************************************************************************

DPBaseAddress = $00 						; Base address used for direct page.
											; (e.g. variables start at DP+nn)

DPageNumber = DPBaseAddress 				; page number of workspace area
DBaseAddress = DPBaseAddress+2 				; low memory for workspace area
DHighAddress = DPBaseAddress+4 				; high memory for workspace area

DCodePtr = DPBaseAddress+6 					; address of code - current token.

DTemp1 = DPBaseAddress + 8 					; LONG Temporary value
DTemp2 = DPBaseAddress + 12 				; LONG Temporary value
DSignCount = DPBaseAddress + 16 			; Sign count in division.
DTempStringPtr = DPBaseAddress + 18 		; Temporary string allocation (working down)
DConstantShift = DPBaseAddress + 20 		; Constant Shift

EXSBase = $100 								; Initial value of X at lowest stack level.

											; offsets from stack base (each stack element = 2 bytes)
EXSValueL = 0 								; Low word
EXSValueH = 16  							; High word
EXSPrecType = 32							; Type (bit 15, string = 1), rest are precedence bits.


