; send buffer position

d_snd_buff_pos

    .repeat 16,0

; send buffer size

d_snd_buff_sz

    .repeat 16,0

; send buffer -> data to send using wic64 to host
;
; todo: replace with 1 page of allocated memory 

d_snd_buff

    .repeat 64,0

; recv buffer position

d_rcv_buff_pos

    .repeat 16,0

; recv buffer size

d_rcv_buff_sz

    .repeat 16,0

; recv buffer -> data from the wic64
;
; todo: replace with 1 page of allocated memory 

d_rcv_buff

    .repeat 256,0

; cmd buffer position

d_cmd_buff_pos

    .repeat 16,0

; cmd buffer size

d_cmd_buff_sz

    .repeat 16,0

; cmd buffer -> command data for network/cnp


d_cmd_buff

    .repeat 16,0


d_payload_sts

    .repeat 16,0

d_payload_sz

    .repeat 16,0

w_payload

    .repeat 64,0
