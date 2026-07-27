
.ifdef debug
.text "->jlink"
.endif

jlink
;---------------------------------------
;

.block 

.ifdef debug
lda #0
sta $d020
jsr delay

; patch trace_do with runtime addresses
; (must be done before any trace_log call)

    lda #<trace_ptr
    sta trace_do + 1
    sta trace_do + 4
    sta trace_do + 10
    lda #>trace_ptr
    sta trace_do + 2
    sta trace_do + 5
    sta trace_do + 11
    lda #<trace_ring
    sta trace_do + 15
    lda #>trace_ring
    sta trace_do + 16

.endif

    #trace_log 1

; init external calls like pet2asc 

    #ldxy extern
    jsr initextern

; init drivers vars

    lda #d_state_none
    sta d_state

end 

    rts

.bend
