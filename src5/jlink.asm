jlink
;---------------------------------------
;

.block 

.ifdef debug
lda #0
sta $d020
jsr delay
.endif

; init external calls like pet2asc 

    #ldxy extern
    jsr initextern

end 

    rts

.bend
