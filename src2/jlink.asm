
.ifdef debug
.text "->jlink"
.endif

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

; init drivers vars

    lda #d_state_none
    sta d_state

end 

    rts

.bend
