
.ifdef debug
.text "->jdget"
.endif


jdataget
;---------------------------------------
;
;   A <- byte from buffer 
;   C <- set when no data 
;   C <- clear when there is data

.block

    #trace_log 5

    stx tempx

chk_rcv_buff

    lda d_rcv_buff_sz
    beq chk_cmd_buff 
    jmp do_rcv_buff

chk_cmd_buff

    lda d_cmd_buff_sz
    beq return 
    jmp do_cmd_buff 

return 

    sec ; <- no data
    rts


do_cmd_buff 

    jsr pop_cmd_buff
    ldx tempx
    clc 
    rts

do_rcv_buff 

    jsr pop_rcv_buff
    ldx tempx
    bcs return 
    clc 
    rts

tempx

    .byte 0

.bend