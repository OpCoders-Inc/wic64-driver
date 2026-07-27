;---------------------------------------
; pointer storage

sptr           .var $61 ;$62
ptr            .var $63 ;$64


;---------------------------------------
;
; open the driver

.ifdef debug
.null "->link" 
.endif

link    

        .block

        inc wic64_call_bits+0

        ; init external calls like pet2asc 

        #ldxy extern
        jsr initextern

        ; init 

        lda #drv_state_off
        sta drv_state

        ; clear the payload index 

        lda #0
        sta wic64_payload_index
        sta drv_buffer_pos 
        sta drv_buffer_size

        ; allocate buffers

        ; check if network is already up 

        lda #0
        sta wic64_online

        lda #0
        sta wic64_command_mode

        lda $0245 
        and #%100000
        beq done

        lda #1
        sta wic64_online

        done

        rts
        
        .bend


.null "-ulnk"
unlink  
;---------------------------------------

        .block

        inc wic64_call_bits+1

        rts

        .bend


.null "-shnd"
sethand
;---------------------------------------

        .block

        
        bcc cmd 

        #stxy carrier_mode+1

        jmp done 

        cmd 

        #stxy command_mode+1

        done

        inc wic64_call_bits+2

        sec 

        rts

        .bend


.null "-poll"
pollget
;---------------------------------------
;
; when the driver is in command mode, we 
; want to make sure we call the command 
; handler. this is to return status bytes 
; back to the network and cnp libraries
; that normally expect something back 
; from a real modem.

        .block

        inc wic64_call_bits+3

        lda wic64_payload_buff
        bne call_handler

        ; check online

        lda wic64_online
        beq offline 

        ;jsr delay
        #wic64_send_command WIC64_CMD_TCP_READ
        #wic64_recv_data

        lda wic64_payload_size 
        beq offline 

        lda #1
        sta wic64_payload_buff

        lda #0
        sta wic64_command_mode

        jmp call_handler

        offline

        rts 

        call_handler

        ; command mode?

        lda wic64_command_mode
        beq online 

        clc ; <- command mode
        jmp command_mode

        online 

        sec ; <- online/carrier mode
        jmp carrier_mode

        .bend


.null "-dget"

dataget
;---------------------------------------
;

        .block

        inc wic64_call_bits+4

        lda wic64_command_mode
        beq online

        ; -------------------------------

        command

        jsr getbuff 

        dec wic64_payload_buff
        bne send_cmd_byte

        clear  

        pha
        lda #0
        sta wic64_payload_size 
        sta wic64_payload_index
        sta wic64_command_mode
        pla

        ; return the command byte 

        send_cmd_byte

        clc 
        rts

        ; -------------------------------

        online 

        sec ; <- no data yet
        rts

        .bend

.null "-gbuf"
;---------------------------------------
getbuff .block

        lda wic64_payload_buff
        bne get

        rts

        get 
        phx
        ldx wic64_payload_index
        lda wic64_payload,x
        inc wic64_payload_index
        plx

        rts

        .bend 


.null "-dput"
dataput
;---------------------------------------

        .block

        inc wic64_call_bits+5

        sta payload 

        pha 
        tya 
        pha 
        txa 
        pha

        ; store the incoming data for debugging

        ldx wic64_payload_os_index
        sta wic64_payload_os,x 
        inx 
        cpx #64
        bne put

        ldx #0

        put 

        stx wic64_payload_os_index
        
        lda wic64_online
        bne send 

        pla 
        tax 
        pla 
        tay 
        pla

        sec 
        rts 

        send

        ;jsr delay
        #wic64_send_command_with_payload WIC64_CMD_TCP_WRITE, payload
        #wic64_recv_data
        
        pla 
        tax 
        pla 
        tay 
        pla

        clc
        rts

        payload 

        .byte 0,0

        .bend


.null "-srat"
setrate
;---------------------------------------
;
; for right now we should only need to
; return clear carry - eventually we 
; should make sure the wic64 is present


        .block

        inc wic64_call_bits+6

        clc

        rts

        .bend


.null "-ssid"
ssidstat
;---------------------------------------
;
; this will handle returning the
; current sid or joining the ssid 
; 
; for now we are fudging and just 
; sending back carry clear

        .block

        ; set flag that ssid is set 

        bcc readssid

        inc $d020
        inc wic64_call_bits+7

        lda #2
        sta wic64_payload_buff
        
        ; store some fake data in the payload 
        ; for use to use later 

        ldx #0
        lda #"0"
        sta wic64_payload,x 
        inx
        lda #$0d 
        sta wic64_payload,x

        ; set command mode 

        lda #1
        sta wic64_command_mode

        clc     ; <- join wifi

        rts

        readssid

        inc $d020
        inc wic64_call_bits+7

        lda #0
        sec     ; <- read ssid

        rts

        .bend


.null "-osoc"
opensock
;---------------------------------------

        .block

        bcc open 

        close 

        inc wic64_call_bits+8

        ; close socket

        sec     ; <- offline
        rts

        open

        inc wic64_call_bits+8

        ; open socket

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
        sta wic64_payload,x
        inx 
        iny 
        bne l1

        el1

        lda #":"
        sta wic64_payload,x 
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
        sta wic64_payload,x
        inx 
        iny
        bne l2

        el2 

        lda #0
        sta wic64_payload,x

        #wic64_send_command_with_payload WIC64_CMD_TCP_OPEN, wic64_payload
        #wic64_recv_data

        ; !!! we want to do some basic checks here to make sure we are online

        ldx #0
        lda #"1"
        sta wic64_payload,x 
        inx
        lda #$0d 
        sta wic64_payload,x

        lda #2
        sta wic64_payload_buff

        ; set command mode 
        
        lda #1
        sta wic64_command_mode

        lda #1
        sta wic64_online

        clc     ; <- online 
        rts 

        .bend


;.null "-nhdp"
nhdpause
;---------------------------------------

        .block

        inc wic64_call_bits+9

        rts

        .bend

;.null "-nhdr"
nhdresum
;---------------------------------------

        .block

        inc wic64_call_bits+10

        rts

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
        
        cmp #1                ;Self-Mod
        
        bcc next

        rts 

.bend 

handlers 
;---------------------------------------

carrier_mode

        jmp raw_rts

.ifdef debug
;.null "->jcar"
.endif

command_mode

        jmp raw_rts

.ifdef debug
;.null "->jcom"
.endif

