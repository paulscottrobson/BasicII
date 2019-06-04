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

DPageNumber = DPBaseAddress+0 				; page number of workspace area (upper 8 bits of address)
DBaseAddress = DPBaseAddress+2 				; low memory for workspace area
DHighAddress = DPBaseAddress+4 				; high memory for workspace area

DCodePtr = DPBaseAddress+6 					; address of code - current token.

DTemp1 = DPBaseAddress + 8 					; *** LONG *** Temporary value
DTemp2 = DPBaseAddress + 12 				; *** LONG *** Temporary value

DSignCount = DPBaseAddress + 16 			; Sign count in division.
DConstantShift = DPBaseAddress + 18 		; Constant Shift used in expression evaluation

DRandom = DPBaseAddress + 20 				; *** LONG *** Random Seed

DTempStringPtr = DPBaseAddress + 24 		; Temporary string allocation (working down)
DStartTempString = DPBaseaddress + 26 		; Start of current temporary string
DCurrentTempString = DPBaseaddress + 28 	; Next free in current temporary string

DVariableDataAddress = DPBaseAddress + 30 	; Address of 4 byte data

; ********************************************************************************
;
;			Expression Stack. There are three entries, low and high word
;			and combined type/precedence word.
;
; ********************************************************************************

EXSBase = $100 								; Initial value of X at lowest stack level.

											; offsets from stack base (each stack element = 2 bytes)
EXSValueL = 0 								; Low word
EXSValueH = 16  							; High word
EXSPrecType = 32							; Type (bit 15, string = 1), rest are precedence bits.


