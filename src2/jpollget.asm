
.ifdef debug
.text "->jpoll"
.endif

jpollget
;---------------------------------------
;

.block 

.ifdef debug
lda #4
sta $d020
jsr delay
.endif

chk_snd_buff

    lda d_snd_buff_sz
    beq chk_rcv_buff
    jmp do_snd_buff

chk_rcv_buff

    lda d_rcv_buff_sz
    beq chk_cmd_buff
    jmp do_rcv_buff

chk_cmd_buff

    lda d_cmd_buff_sz
    beq chk_wic_pay
    jmp do_cmd_buff

chk_wic_pay

    ; check network status
    ; 
    ; todo: this is a hack

    lda $0245
    cmp #$3f 
    bne end 


.ifdef debug
lda #10
sta $d020
jsr delay
.endif

    lda #0
    sta w_payload 
    sta w_payload + 1

    ; payload available?

    lda #WC_TCP_AVAIL
    jsr wic64_do_send_command

    ldx #<w_payload
    ldy #>w_payload
    jsr delay
    jsr wic64_do_recv_data

    ; any data?

    lda w_payload
    bne wic_read
    lda w_payload + 1
    bne wic_read
    jmp end

    ; get payload size 

wic_read

    ; store payload in rcv buffer 

    lda #WC_TCP_READ
    jsr wic64_do_send_command

    ; get header 

    jsr delay
    jsr wic64_do_recv_header
    sta d_payload_sts
    stx d_payload_sz
    sty d_payload_sz + 1

    ; make sure there is data 

    lda d_payload_sz
    bne wic_rcv_data 
    lda d_payload_sz + 1
    bne wic_rcv_data
    jmp end

    lda #0 
    sta d_rcv_buff_pos

    ldx #0

wic_rcv_data

    jsr wic64_read_byte
    jsr push_rcv_buff
    dec d_payload_sz
    bne wic_rcv_data

end

    rts 

do_cmd_buff

    clc 
    jmp mode_carrier

do_rcv_buff

    sec 
    jmp mode_carrier

do_snd_buff

    sta tempa
    jsr flush_snd_buff
    lda tempa

    clc
    rts 

tempa 
tempx

    .byte 0

.bend


