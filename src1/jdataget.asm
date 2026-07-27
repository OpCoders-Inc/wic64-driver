jdataget
;---------------------------------------
;
;   A <- byte from buffer 
;   C <- set when no data 
;   C <- clear when there is data

.block

    stx tempx

chk_cmd_buff

    lda d_cmd_buff_sz
    beq chk_wic_buff 
    jmp do_cmd_buff 

chk_wic_buff

    lda d_payload_sz
    beq return 
    jmp do_wic_buff

return 

    sec ; <- no data
    rts


do_cmd_buff 

    jsr pop_cmd_buff
    ldx tempx
    clc 
    rts

do_wic_buff 

    jsr wic64_do_recv_mode
    jsr wic64_read_byte
    dec d_payload_sz
    ldx tempx
    clc 
    rts

tempx

    .byte 0

.bend