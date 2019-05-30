;
;	Vector Jump table
;
CommandJumpTable:
	.word IllegalToken & $FFFF ; for the $0000 token.
	.word IllegalToken             & $FFFF ; token $4001 "and"
	.word IllegalToken             & $FFFF ; token $4002 "or"
	.word IllegalToken             & $FFFF ; token $4003 "xor"
	.word IllegalToken             & $FFFF ; token $4404 "<"
	.word IllegalToken             & $FFFF ; token $4405 ">"
	.word IllegalToken             & $FFFF ; token $4406 "="
	.word IllegalToken             & $FFFF ; token $4407 "<="
	.word IllegalToken             & $FFFF ; token $4408 ">="
	.word IllegalToken             & $FFFF ; token $4409 "<>"
	.word IllegalToken             & $FFFF ; token $480a "+"
	.word IllegalToken             & $FFFF ; token $480b "-"
	.word IllegalToken             & $FFFF ; token $4c0c "*"
	.word IllegalToken             & $FFFF ; token $4c0d "/"
	.word IllegalToken             & $FFFF ; token $4c0e "mod"
	.word IllegalToken             & $FFFF ; token $4c0f ">>"
	.word IllegalToken             & $FFFF ; token $4c10 "<<"
	.word IllegalToken             & $FFFF ; token $5011 "?"
	.word IllegalToken             & $FFFF ; token $5012 "!"
	.word IllegalToken             & $FFFF ; token $5013 "$"
	.word IllegalToken             & $FFFF ; token $7414 "rnd()"
	.word IllegalToken             & $FFFF ; token $7415 "sgn("
	.word IllegalToken             & $FFFF ; token $7416 "abs("
	.word IllegalToken             & $FFFF ; token $7417 "len("
	.word IllegalToken             & $FFFF ; token $7818 ","
	.word IllegalToken             & $FFFF ; token $7819 ";"
	.word IllegalToken             & $FFFF ; token $781a ":"
	.word IllegalToken             & $FFFF ; token $781b "("
	.word IllegalToken             & $FFFF ; token $781c ")"
	.word IllegalToken             & $FFFF ; token $7c1d "let"

;
;	Token text table. Byte is typeID[7:4] length[3:0]
;
TokenText:
	 .text $04,"and"      ; token $4001
	 .text $03,"or"       ; token $4002
	 .text $04,"xor"      ; token $4003
	 .text $12,"<"        ; token $4404
	 .text $12,">"        ; token $4405
	 .text $12,"="        ; token $4406
	 .text $13,"<="       ; token $4407
	 .text $13,">="       ; token $4408
	 .text $13,"<>"       ; token $4409
	 .text $22,"+"        ; token $480a
	 .text $22,"-"        ; token $480b
	 .text $32,"*"        ; token $4c0c
	 .text $32,"/"        ; token $4c0d
	 .text $34,"mod"      ; token $4c0e
	 .text $33,">>"       ; token $4c0f
	 .text $33,"<<"       ; token $4c10
	 .text $42,"?"        ; token $5011
	 .text $42,"!"        ; token $5012
	 .text $42,"$"        ; token $5013
	 .text $d6,"rnd()"    ; token $7414
	 .text $d5,"sgn("     ; token $7415
	 .text $d5,"abs("     ; token $7416
	 .text $d5,"len("     ; token $7417
	 .text $e2,","        ; token $7818
	 .text $e2,";"        ; token $7819
	 .text $e2,":"        ; token $781a
	 .text $e2,"("        ; token $781b
	 .text $e2,")"        ; token $781c
	 .text $f4,"let"      ; token $7c1d
	.byte $00

;
;	Constants
;
andTokenID                       = $4001
orTokenID                        = $4002
xorTokenID                       = $4003
lessTokenID                      = $4404
greaterTokenID                   = $4405
equalTokenID                     = $4406
lessequalTokenID                 = $4407
greaterequalTokenID              = $4408
lessgreaterTokenID               = $4409
plusTokenID                      = $480a
minusTokenID                     = $480b
starTokenID                      = $4c0c
slashTokenID                     = $4c0d
modTokenID                       = $4c0e
greatergreaterTokenID            = $4c0f
lesslessTokenID                  = $4c10
questionTokenID                  = $5011
plingTokenID                     = $5012
dollarTokenID                    = $5013
rndlparenrparenTokenID           = $7414
sgnlparenTokenID                 = $7415
abslparenTokenID                 = $7416
lenlparenTokenID                 = $7417
commaTokenID                     = $7818
semicolonTokenID                 = $7819
colonTokenID                     = $781a
lparenTokenID                    = $781b
rparenTokenID                    = $781c
letTokenID                       = $7c1d
