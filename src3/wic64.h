
WC_GET_VER_STR  = $00
WC_GET_VER_NUM  = $26

WC_GET_WIFI_NW  = $0c
WC_IS_CONFIG    = $2f
WC_IS_CONNECT   = $2c
WC_CONN_SSID    = $02
WC_CONN_SSID_I  = $0d

WC_GET_MAC      = $14
WC_GET_SSID     = $10

WC_HTTP_GET     = $01

WC_TCP_OPEN     = $21
WC_TCP_AVAIL    = $30
WC_TCP_READ     = $22
WC_TCP_WRITE    = $23
WC_TCP_CLOSE    = $2e

WC_GET_TIME     = $15

WC_GET_STS_MSG  = $2a

WC_ECHO         = $fe

ddra     = $dd02
ddrb     = $dd03
porta    = $dd00
portb    = $dd01
icr      = $dd0d

;--------------------------------------
; send command
;
; use this macro when you need to send a command with
; no payload, for example the GET_VERSION_STRING
; command requires no additional parameters
;
; paramaters:
;
;   1   wic64 command 

w_snd_cmd .macro

    lda #\1
    jsr wic64_do_send_command

.endm

;--------------------------------------
; send command with payload 
;
; use this macro when you do need to send a command with
; no payload, for example the ECHO command 
; requires a string, in addition the macro 
; will determine the size of the payload before
; sending and add that to the command
;
; parameters:
;
;   1   wic64 command
;   2   pointer to payload 
; 

w_snd_cmd_pay .macro

    lda #\1
    ldx #<\2
    ldy #>\2
    jsr wic64_do_send_command_with_payload

.endm


;--------------------------------------
; recv data from wic64
;
; use this macro to read data coming back from the
; wic64 and store it in payload
;
; paramaters:
;
;   1   pointer to data  

w_rcv_dat .macro

    ldx #<wic64_payload
    ldy #>wic64_payload
    
    jsr wic64_do_recv_data

.endm


;--------------------------------------
; recv data from wic64 to memory
;
; use this macro to read data coming back from the
; wic64 and store it in memory
;
; paramaters:
;
;   1   pointer to data  

w_recv_datmem .macro

    ldx #<\1
    ldy #>\1
    
    jsr wic64_do_recv_data

.endm



