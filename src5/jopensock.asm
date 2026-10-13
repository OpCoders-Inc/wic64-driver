jopensock
;---------------------------------------
;

.block 

    ; get cnp host info
    
    #stxy !ptr 

    ldy #tcp_host
    lda (!ptr),y 
    sta !sptr+0
    iny 
    lda (!ptr),y 
    sta !sptr+1

    ldx #0
    ldy #0

    l1

    lda (!sptr),Y
    beq el1
    jsr pet2asc 
    sta w_payload,x
    inx 
    iny 
    bne l1

    el1

    lda #":"
    sta w_payload,x 
    inx
    
    ldy #tcp_port 
    lda (!ptr),y 
    sta !sptr+0
    iny 
    lda (!ptr),y 
    sta !sptr+1

    ldy #0

    l2 

    lda (!sptr),y
    beq el2
    sta w_payload,x
    inx 
    iny
    bne l2

    el2 

    lda #0
    sta w_payload,x


    ; connect to host 

    
    lda #WC_TCP_OPEN
    ldx #<w_payload
    ldy #>w_payload
    jsr wic64_do_send_command_with_payload

    #w_rcv_dat

    ; set ack command to network

.ifdef debug
lda #5
sta $d020
jsr delay
.endif

    lda #"1"
    jsr push_cmd_buff
    lda #$0d
    jsr push_cmd_buff

    clc 
    rts

.bend
