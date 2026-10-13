;----[ nhd.wic64.zi.a ]------------------

;Network Hardware Driver:
;WiC64: User Port Parallel
;ZiModem-like Firmware

;Adaptation from Swiftlink driver.

         .include "//os/h/:modules.h"

         #inc_s "app"
         #inc_s "network"
         #inc_s "nhd"
         #inc_s "pointer"

         #inc_s "memory"
         #inc_s "screen"
         #inc_s "service"

         *= $7800  ;4-page Relocatable

;---------------------------------------

;User Port CIA2 Registers

ddra     = $dd02  ;PA Direction (PA2)
ddrb     = $dd03  ;PB Direction
porta    = $dd00  ;PA (PA2 bit)
portb    = $dd01  ;PB Data
icr      = $dd0d  ;Interrupt Control
crb      = $dd0f  ;Control Register B

;Constants for WiC64

wic_sig  = $57    ;'W' Signature
pa2_bit  = $04    ;PA2 Mask (high=send, low=recv)
flag2    = $10    ;FLAG2 IRQ Mask

ystash   = $97    ;Temporary storage

;---------------------------------------
linkjt   jmp link
         jmp unlink

         jmp sethand ;Set handler
         jmp pollget ;Poll incoming buf

         jmp rsget   ;Read  in  a byte
         jmp rsput   ;Write out a byte

         jmp setrate ;Set baud rate (stub for WiC64)
         jmp ssidstat;Read/Join SSID
         jmp opensock;Open Socket

         ;Auxiliary Routines

         jmp r2pause ;Pause IRQs
         jmp r2resum ;Resume IRQs

;---------------------------------------

link     ;Config IRQ for WiC64.
         .block
         #ldxy extern
         jsr initextern

         ;Allocate Rx Buffer

         lda #mapsys
         ldx #1 ;page
         jsr pgalloc

         ldx #0
         #stxy swibuf  ;Reuse var names for now

         stx swidbs ;Rx Buf Start Index
         stx swidbe ;Rx Buf End   Index

         stx rbuf_cnt ;Rx Buf Count

         ;Allocate Tx Buffer

         lda #mapsys
         ldx #1 ;page
         jsr pgalloc

         ldx #0
         #stxy swobuf

         stx swodbs ;Tx Buf Start Index
         stx swodbe ;Tx Buf End   Index

         stx tbuf_cnt ;Tx Buf Count

         ;--- Initialize WiC64 ----------

         ;TODO: Set up CIA2 directions, enable IRQs

         ;Backup IRQ Vector

         #rdxy $0314;$0315
         #stxy previrq

         ;Configure WiC64 IRQ

         #ldxy wicirq
         #stxy $0314;$0315

         lda #<done
         sta linkjt+1

done     rts
         .bend

previrq  .word 0


unlink   ;Free Memory, Restore IRQ Vector
         .block
         jsr r2pause

         #rdxy previrq
         #stxy $0314;$0315

         ;Free Rx Buffer

         ldy swibuf+1
         ldx #1 ;page
         jsr pgfree

         ;Free Tx Buffer

         ldy swobuf+1
         ldx #1 ;page
         jsr pgfree

         rts
         .bend

;---------------------------------------

delay    ;Delay A*Jiffies Long
         ;A -> Number of Jiffies
         .block
         sta period+1

         lda #0
         sta jiffylo

next     lda jiffylo
period   cmp #1                ;Self-Mod
         bcc next

         rts
         .bend


wicirq   ;IRQ Handler for WiC64

         ;TODO: Save context, check ICR for FLAG2/PC2

         ;Process Rx or Tx based on PA2 direction

         ;Read/Write to buffers accordingly

         pla     ;A <- stack (placeholder)
         rti

;---------------------------------------

sethand  ;Set incoming data handlers
         ;C -> Clr = Command Mode
         ;C -> Set = Carrier Detect Mode
         ;RegPtr -> Handler routine ptr

         ;TODO: Implement similar to original

         rts


carrier  ;Check "online" status for WiC64
         ;TODO: Perhaps check connection via command

         clc     ;Placeholder offline
         rts


pollget  ;Poll incoming data buffer
         ;Notify handler if available

         ;TODO: If using polling instead of IRQ, check here

         rts


rsget    ;Read a byte from Rx Buffer
         ;C <- Set = Buffer Empty

         ;TODO: Similar buffer logic

         clc
         rts


rsput    ;Write a byte to Tx Buffer
         ;A -> byte to send

         ;TODO: Buffer and trigger send

         clc
         rts

;---------------------------------------
;Auxiliary Routines

;TODO: WiC64 commands as binary packets

setrate  ;Stub: WiC64 has no baud rate
         clc
         rts

ssidstat ;Read/Join SSID
         ;C -> Clr = Read
         ;C -> Set = Join, RegPtr -> Struct

         ;TODO: Send cmd $10 or $02

         clc
         rts

opensock ;Open/Close TCP Socket
         ;C -> Clr = Open, RegPtr -> Struct
         ;C -> Set = Close

         ;TODO: Cmd $21/$63 for connect/disconnect

         clc
         rts

;---------------------------------------

r2pause  ;Pause IRQs
         ;TODO: Mask ICR

         rts


r2resum  ;Resume IRQs
         ;TODO: Unmask ICR

         rts

;---------------------------------------
extern
         #inc_h "memory"
pgfree   #syscall lmem,pgfree_
pgalloc  #syscall lmem,pgalloc_

         #inc_h "service"
quitapp  #syscall lser,quitapp_

         #inc_h "string"
pet2asc  #syscall lstr,pet2asc_  ;If needed for strings

         .byte $ff ;Terminator
         
