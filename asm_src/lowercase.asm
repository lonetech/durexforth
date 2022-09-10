CHAR_TO_LOWERCASE ; ( a -- a )
      bit .c0mask
      beq .lowercaserts
      and #$1f
      ora #$40
.lowercaserts rts
.c0mask !byte $c0
