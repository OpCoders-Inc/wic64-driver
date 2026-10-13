jdataput
;---------------------------------------
;
;   A -> byte to push

.block

    stx tempx

    ; push next byte to send buffer 

    jsr push_snd_buff

.ifdef debug
lda #6
sta $d020
jsr delay
.endif


    ldx tempx 
    
    clc 
    rts 

tempx 

    .byte 0

.bend 