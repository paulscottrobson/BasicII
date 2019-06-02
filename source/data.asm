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

