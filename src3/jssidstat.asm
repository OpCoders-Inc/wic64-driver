
.ifdef debug
.text "->jssid"
.endif

jssidstat
;---------------------------------------
;
;   C -> set to read ssid
;   C -> not set to join ssid (wifi)

.block 

    #trace_log 8

    bcc read_ssid

join_ssid 

; todo: connect to wifi

; todo: check connected status

; set ack command to network

.ifdef debug
lda #2
sta $d020
jsr delay
.endif

    lda #"0"
    jsr push_cmd_buff
    lda #$0d
    jsr push_cmd_buff

    clc 
    rts

read_ssid 

.ifdef debug
lda #2
sta $d020
jsr delay
.endif

    lda #0
    sec 
    rts 

.bend