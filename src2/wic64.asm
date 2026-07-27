
; switch wic64 to send mode (wic receives command)
; ---------------------------------------------------------
    wic64_do_send_mode

        .block

        lda ddra 
        ora #$04 
        sta ddra 

        lda porta 
        ora #$04 
        sta porta 

        lda #$ff 
        sta ddrb 

        rts

        .bend

; switch wic64 to transmit mode (wic sends data)
; ---------------------------------------------------------
    wic64_do_recv_mode

        .block 

        lda #$00
        sta ddrb 
        lda porta 
        and #251 
        sta porta 

        rts

        .bend

; read byte from wic64
; ---------------------------------------------------------

    wic64_read_byte

        .block

        lda icr 
        and #$10 
        beq wic64_read_byte
        lda portb 
        rts

        .bend 

; write byte to wic64 
; ---------------------------------------------------------
    wic64_write_byte

        .block

        sta portb 

    dowrite

        lda icr
        and #$10
        beq dowrite

        rts

        .bend 

; send wic64 command
; ---------------------------------------------------------
;
;   Sends a command without a Payload to the Wic64.
;
;   Parameters:
;
;       .A  wic64 command 
;

    wic64_do_send_command

        .block 

        ; store the command 

        pha 

        jsr wic64_do_send_mode

        ; send 4 byte command to get the ip address

        lda #"r"                ; protocol
        jsr wic64_write_byte
        pla                     ; command
        jsr wic64_write_byte
        lda #$00                ; payload low
        jsr wic64_write_byte
        lda #$00                ; payload high
        jsr wic64_write_byte

        rts

        .bend


; send wic64 command with payload
; ---------------------------------------------------------
;
;   Sends a command with a Payload to the Wic64.
;
;   Parameters:
;
;       .A  wic64 command 
;       .X  pointer to payload low byte 
;       .Y  pointer to payload high byte 

    wic64_do_send_command_with_payload

        .block 

        pha

        ; get payload size 

        lda #$00
        sta wic64_payload_size
        sta wic64_payload_size + 1

        txa
        sta $fa 
        tya
        sta $fb

        ldy #$00

    loop1

        lda ($fa),y
        beq send

        inc wic64_payload_size
        bne next
        inc wic64_payload_size + 1

    next

        iny

        bne loop1

    send
        
        jsr wic64_do_send_mode

        ; send command to wic64 with payload 

        lda #"r"                        ; protocol
        jsr wic64_write_byte
        pla                             ; command
        jsr wic64_write_byte
        lda wic64_payload_size          ; payload low
        jsr wic64_write_byte
        lda wic64_payload_size + 1      ; payload high
        jsr wic64_write_byte

        ldy #$00

    loop2

        lda ($fa),y
        beq done 
        jsr wic64_write_byte
        iny 
        bne loop2

    done

        rts

        .bend


; ---------------------------------------------------------
;
;   Wait for Wic64 to return data.

wic64_do_wait_return

    .block

    lda #$00
    sta c1
    lda #$00 
    sta c2

    lda #$10
    bit $dd0d
    bne success

    lda #$10

wait 

    bit $dd0d
    bne success

    dec c2
    bne wait
    dec c1
    bne wait

success

    rts        

    .bend

; ---------------------------------------------------------
;
;   Receives the header from the Wic64 and
;   stores the payload size.
;
;   Parameters:
;
;   Affects:
;
;       .A  header status 
;       .X  header size low 
;       .Y  header size high 

wic64_do_recv_header

    .block

    ; wait for data

    jsr wic64_do_wait_return

    ; put wic64 into receive mode

    jsr wic64_do_recv_mode

    ; read dummy byte 

    jsr wic64_read_byte

    ; get status and store it

    jsr wic64_read_byte
    sta temp

    ; get payload low

    jsr wic64_read_byte
    sta temp + 1

    ; get payload hi

    jsr wic64_read_byte
    sta temp + 2

    lda temp + 2
    tay 
    lda temp + 1
    tax 
    lda temp

    rts 

temp

    .byte 0,0,0

    .bend 


; ---------------------------------------------------------
;
;   Receives data from Wic64 and stores in
;   requested storage location.
;
;   Parameters:
;
;       .X  pointer to data low byte 
;       .Y  pointer to data high byte 

    wic64_do_recv_data

        .block 

        ; ???

        stx ptr_payload 
        sty ptr_payload + 1

        lda #$00
        sta c1
        lda #$00 
        sta c2

        lda #$10
        bit $dd0d
        bne success

        lda #$10

        wait 

        bit $dd0d
        bne success

        dec c2
        bne wait
        dec c1
        bne wait

        rts        

        success

        jsr wic64_do_recv_mode

        ; read dummy byte 

        jsr wic64_read_byte

        ; get status and store it

        jsr wic64_read_byte
        sta wic64_status

        ; get payload low

        jsr wic64_read_byte
        tay
        sta wic64_payload_size 

        ; get payload hi

        jsr wic64_read_byte
        tax 
        sta wic64_payload_size + 1

        ; no data check 

        clc

        cpy #$00
        bne recv
        cpx #$00
        bne recv

        sec 

        rts

    recv 

        ; save payload size 

        lda wic64_payload_size
        sta wic64_payload_work

        lda wic64_payload_size + 1
        sta wic64_payload_work + 1

        ; store payload for later 

        lda ptr_payload
        sta $fa 
        lda ptr_payload + 1
        sta $fb 

        ldy #$00

    recv_data

        jsr wic64_read_byte 
        sta ($fa),y
        iny
        dec wic64_payload_work
        bne recv_data
        dec wic64_payload_work + 1
        lda wic64_payload_work + 1
        cmp #$ff
        bne recv_data

        rts 

ptr_payload

    .word 0

        .bend

c1 .byte 0
c2 .byte 0


.text "wic64-data"

wic64_call_bits         ; 1

    .repeat 16,0

wic64_online            ; 2

    .repeat 16,0

wic64_payload_index     ; 3

    .repeat 16,0

wic64_payload_buff      ; 4

    .repeat 16,0

wic64_status            ; 5

    .repeat 16,0

wic64_payload_size      ; 6

    .repeat 16,0

wic64_payload_work      ; 7

    .repeat 16,0

wic64_payload           ; 8

    .repeat 64,0

wic64_payload_os_index  ; 12

    .repeat 16,0

wic64_payload_os        ; 13

    .repeat 64,0

wic64_command_mode      ; 16

    .repeat 16,0
