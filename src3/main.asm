

jtable
;---------------------------------------

.block 

    jmp jlink       ; +$00 link             -> load driver
    jmp junlink     ; +$03 unlink           -> unload driver 
    jmp jsethand    ; +$06 sethand          -> config data handlers
    jmp jpollget    ; +$09 pollget          -> check for data
    jmp jdataget    ; +$0c dataget          -> get byte rcv/cmd buff
    jmp jdataput    ; +$0f dataput          -> put byte snd buff 
    jmp jsetrate    ; +$12 setrate          -> set baud rate
    jmp jssidstat   ; +$15 ssidstat         -> join ssid (wifi)
    jmp jopensock   ; +$18 opensock         -> open tcp socket
    jmp jnone       ; +$1b nhdpause         -> pause nmi 
    jmp jnone       ; +$1e hndresume        -> resume mni 

.bend

jnone
;---------------------------------------

.block

.ifdef debug
lda #11
sta $d020
jsr delay
.endif

    rts

.bend 


push_cmd_buff
;---------------------------------------
;
;   A -> byte to put in cmd buffer
;   C -> set when buffer is past $ff

.block 

    inc d_cmd_buff_sz
    ldx d_cmd_buff_sz
    sta d_cmd_buff, x

    rts 

.bend 


.ifdef debug
.text "->pop"
.endif

pop_cmd_buff
;---------------------------------------
;
;   A <- byte from the cmd buffer
;   C <- set when stack is now zero

.block 

    clc
    inc d_cmd_buff_pos
    ldx d_cmd_buff_pos
    lda d_cmd_buff, x
    
    ; have we reached the end?

    cpx d_cmd_buff_sz 
    bne return 

    ; reset buffer counters

    sta tempa

    lda #0
    sta d_cmd_buff_pos
    sta d_cmd_buff_sz
    sec

    lda tempa

return

    rts 

tempa 

    .byte 0

.bend 


push_rcv_buff
;---------------------------------------
;
;   A -> byte to put in rcv buffer

.block 

    inc d_rcv_buff_sz
    ldx d_rcv_buff_sz
    sta d_rcv_buff, x

    rts 

.bend 


pop_rcv_buff
;---------------------------------------
;
;   A <- byte from the cmd buffer
;   C <- set when stack is now zero

.block 

    clc
    inc d_rcv_buff_pos
    ldx d_rcv_buff_pos
    lda d_rcv_buff, x
    
    ; have we reached the end?

    cpx d_rcv_buff_sz 
    bne return 

    ; reset buffer counters

    sta tempa

    lda #0
    sta d_rcv_buff_pos
    sta d_rcv_buff_sz
    sec

    lda tempa

return

    rts 

tempa 

    .byte 0

.bend 

push_snd_buff
;---------------------------------------
;
;   A -> byte to put in snd buffer

.block 

    inc d_snd_buff_sz
    ldx d_snd_buff_sz
    sta d_snd_buff, x

    rts 

.bend 


flush_snd_buff
;---------------------------------------
;
;   A -> byte to put in snd buffer

.block

    ; add zero byte to end 

    lda #0
    jsr push_snd_buff 

    ; reset buffer pointers

    sta d_snd_buff_pos
    sta d_snd_buff_sz

    ; call wic64 send 

    lda #WC_TCP_WRITE
    ldx #<d_snd_buff + 1
    ldy #>d_snd_buff + 1
    jsr wic64_do_send_command_with_payload

    ; wait for response

    #w_rcv_dat


.bend 


delay 
;---------------------------------------

.block 

        lda #$02
        sta period+1

        lda #0
        sta jiffylo

        next     
        
        lda jiffylo
        period   
        
        cmp #1  
        
        bcc next

        rts 

.bend 

mode_carrier
;---------------------------------------

    jmp raw_rts 

mode_command 
;---------------------------------------

    jmp raw_rts 