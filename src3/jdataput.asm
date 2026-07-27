
.ifdef debug
.text "->jdput"
.endif

jdataput
;---------------------------------------
;
;   A -> byte to push

.block

    #trace_log 6

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