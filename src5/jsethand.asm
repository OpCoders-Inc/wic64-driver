jsethand
;---------------------------------------
;
; C <- set for command handler 
; C <- not set for carrier handler

.block 

    lda #1
    sta $d020

    bcc set_command 

set_carrier

    #stxy mode_carrier+1
    sec
    rts 

set_command

    #stxy mode_command+1
    sec
    rts 

.bend


