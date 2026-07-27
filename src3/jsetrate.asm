
.ifdef debug
.text "->jrate"
.endif

jsetrate
;---------------------------------------

.block 

    #trace_log 7

    clc
    rts 

.bend 