;
;	Vector Jump table
;
CommandJumpTable:
	.word IllegalToken & $FFFF ; for the $0000 token.
	.word IllegalToken             & $FFFF ; token $2001 "and"
	.word IllegalToken             & $FFFF ; token $2002 "or"
	.word IllegalToken             & $FFFF ; token $2003 "xor"
	.word IllegalToken             & $FFFF ; token $2204 "<"
	.word IllegalToken             & $FFFF ; token $2205 ">"
	.word IllegalToken             & $FFFF ; token $2206 "="
	.word IllegalToken             & $FFFF ; token $2207 "<="
	.word IllegalToken             & $FFFF ; token $2208 ">="
	.word IllegalToken             & $FFFF ; token $2209 "<>"
	.word IllegalToken             & $FFFF ; token $240a "+"
	.word IllegalToken             & $FFFF ; token $240b "-"
	.word IllegalToken             & $FFFF ; token $260c "*"
	.word IllegalToken             & $FFFF ; token $260d "/"
	.word IllegalToken             & $FFFF ; token $260e "mod"
	.word IllegalToken             & $FFFF ; token $260f ">>"
	.word IllegalToken             & $FFFF ; token $2610 "<<"
	.word IllegalToken             & $FFFF ; token $3a11 "rnd()"
	.word IllegalToken             & $FFFF ; token $3a12 "sgn("
	.word IllegalToken             & $FFFF ; token $3a13 "abs("
	.word IllegalToken             & $FFFF ; token $3a14 "len("
	.word IllegalToken             & $FFFF ; token $3c15 ","
	.word IllegalToken             & $FFFF ; token $3c16 ";"
	.word IllegalToken             & $FFFF ; token $3c17 ":"
	.word IllegalToken             & $FFFF ; token $3c18 "("
	.word IllegalToken             & $FFFF ; token $3c19 ")"
	.word IllegalToken             & $FFFF ; token $3e1a "let"

;
;	Token text table. Byte is typeID[7:4] length[3:0]
;
TokenText:
	.text $04,"and"      ; token $2001
	.text $03,"or"       ; token $2002
	.text $04,"xor"      ; token $2003
	.text $12,"<"        ; token $2204
	.text $12,">"        ; token $2205
	.text $12,"="        ; token $2206
	.text $13,"<="       ; token $2207
	.text $13,">="       ; token $2208
	.text $13,"<>"       ; token $2209
	.text $22,"+"        ; token $240a
	.text $22,"-"        ; token $240b
	.text $32,"*"        ; token $260c
	.text $32,"/"        ; token $260d
	.text $34,"mod"      ; token $260e
	.text $33,">>"       ; token $260f
	.text $33,"<<"       ; token $2610
	.text $d6,"rnd()"    ; token $3a11
	.text $d5,"sgn("     ; token $3a12
	.text $d5,"abs("     ; token $3a13
	.text $d5,"len("     ; token $3a14
	.text $e2,","        ; token $3c15
	.text $e2,";"        ; token $3c16
	.text $e2,":"        ; token $3c17
	.text $e2,"("        ; token $3c18
	.text $e2,")"        ; token $3c19
	.text $f4,"let"      ; token $3e1a
	.byte $00

;
;	Constants
;
andTokenID                       = $2001
orTokenID                        = $2002
xorTokenID                       = $2003
lessTokenID                      = $2204
greaterTokenID                   = $2205
equalTokenID                     = $2206
lessequalTokenID                 = $2207
greaterequalTokenID              = $2208
lessgreaterTokenID               = $2209
plusTokenID                      = $240a
minusTokenID                     = $240b
starTokenID                      = $260c
slashTokenID                     = $260d
modTokenID                       = $260e
greatergreaterTokenID            = $260f
lesslessTokenID                  = $2610
rndlparenrparenTokenID           = $3a11
sgnlparenTokenID                 = $3a12
abslparenTokenID                 = $3a13
lenlparenTokenID                 = $3a14
commaTokenID                     = $3c15
semicolonTokenID                 = $3c16
colonTokenID                     = $3c17
lparenTokenID                    = $3c18
rparenTokenID                    = $3c19
letTokenID                       = $3e1a
