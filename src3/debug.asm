
.ifdef debug

;--------------------------------------
; debug trace ring
;
; self-modifying — addresses patched
; at runtime by jlink.
;
; trace data lives in driver memory.
; Find with: s "->trace"
;
; parameters:
;
;   1   caller ID (1-255)

trace_log .macro

    txa
    pha
    tya
    pha
    lda #\1
    jsr trace_do
    pla
    tay
    pla
    tax

.endm

trace_do

    inc $ffff
    ldx $ffff
    txa
    and #$0f
    sta $ffff
    tax
    pla
    sta $ffff,x
    rts

.endif
