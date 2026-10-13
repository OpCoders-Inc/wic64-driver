;----[ nhd.slxx.zi.a ]------------------

;Network Hardware Driver:
;Swiftlink: up to 34.8K
;ZiModem Firmware

;Original Source:
;Noel Nyman, Kent Sullivan, Bryan Minugh
;Geoduck Development Systems, and
;Dr. Evil labs.

         .include "//os/h/:modules.h"

         #inc_s "app"
         #inc_s "network"
         #inc_s "nhd"
         #inc_s "pointer"

         #inc_s "memory"
         #inc_s "screen"
         #inc_s "service"

         *= $7800  ;4-page Relocatable

         ;*= $1000


;---------------------------------------

sw       = $de00 ;Define before include.

         #inc_s "io_swiftlink"

ystash   = $97 ;Temporary storage

;---------------------------------------
linkjt   jmp link
         jmp unlink

         jmp sethand ;Set handler
         jmp pollget ;Poll incoming buf

         jmp rsget ;Read  in  a byte
         jmp rsput ;Write out a byte

         jmp setrate  ;Set baud rate
         jmp ssidstat ;Read]Join SSID
         jmp opensock ;Open Socket

         ;Auxiliary RS-232 Routines

         jmp r2pause ;Pause  NMIs
         jmp r2resum ;Resume NMIs

;---------------------------------------

link     ;Config NMI for Swiftlink.
         .block
         #ldxy extern
         jsr initextern

         ;Allocate Rx Buffer

         lda #mapsys
         ldx #1 ;page
         jsr pgalloc

         ldx #0
         #stxy swibuf

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

         ;--- Initialize 6551 ----------

         ;-- Control Register --

         lda #swb_9600  ;Default Baud
         ora #swx_brc   ;Baud Rate Clock

         ;8 word bits is $00
         ;1 stop bit  is $0

         ;ora #swx_w8b  ;8 word bits
         ;ora #swx_stp  ;2 stop bits

         sta sw_ctrl

         ;-- Command Register --

         ;Data Term.Ready
         ;Enable  Rx Interrupts
         ;Disable Tx Interrupts
         ;Assert  Ready to Send

         lda #swc_dtr.swt_tmrl

         sta sw_cmd

         ;Config NMI masks for sw_cmd

         sta swn_rx     ;NMI: Rx only

         ;Enable Rx Interrupts
         ;Enable Tx Interrupts
         ;Assert Ready to Send

         lda #swc_dtr.swt_torl

         sta swn_rxtx   ;NMI: Rx]Tx


         ;Backup NMI Vector

         #rdxy $0318;$0319
         #stxy prevnmi

         ;Configure Swiftlink NMI

         #ldxy slinknmi
         #stxy $0318;$0319

         lda #<done
         sta linkjt+1

done     rts
         .bend

prevnmi  .word 0


unlink   ;Free Memory, Restor NMI Vector
         .block
         jsr r2pause

         #rdxy prevnmi
         #stxy $0318;$0319

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


slinknmi ;NMI Handler for Swiftlink

         ;KERNAL could be in or out.

         pha     ;A -> stack
         txa
         pha     ;X -> stack
         tya
         pha     ;Y -> stack

         ;Addition to original routine

         lda $01
         pha     ;ProcPort -> stack

         and #%11111100 ;Mode 0: RAM+RAM
         ora #%00000010 ;Mode 2:  IO+KER
         sta $01

         ;lda $01        ; 3 Cycles
         ;pha            ; 3 Cycles

         ;and #%11111100 ; 2 Cycles
         ;ora #%00000010 ; 2 Cycles
         ;sta $01        ; 3 Cycles
                         ;--------
         ;Total Added:   ;13 Cycles
         ;-cld           ;-2 Cycles
         ;Net Added:     ;11 Cycles


         ;Check for Tx or Rx Ready

         lda sw_stat
         and #sws_rrd.sws_trd
         beq chkrstr ;Not a Tx or Rx NMI

         ;Mask Rx and Tx Interrupts.

         ldx #swc_dtr.swc_irq.swt_tmrl
         stx sw_cmd

         ;Either Rx has data or Tx ready

         and #sws_rrd
         beq txbyte

         ;--- Receive a byte ---

         lda sw_data     ;A <- Data Byte

         ldy swidbe      ;End of buffer
         sta (swibuf),y  ;Store in buf

         inc swidbe
         inc rbuf_cnt

         lda sw_stat
         and #sws_trd
         beq *-5

txbyte   ;--- Transmit a byte ---

         lda tbuf_cnt
         beq rxenable

         ldy swodbs     ;Start of buffer
         lda (swobuf),y ;Ready from buf
         sta sw_data

         inc swodbs
         dec tbuf_cnt
         beq rxenable   ;Tx Buffer Empty

         lda swn_rxtx
         .byte $2c

rxenable lda swn_rx
         sta sw_cmd

endnmi   pla     ;ProcPort <- stack
         sta $01

         pla     ;Y <- stack
         tay
         pla     ;X <- stack
         tax
         pla     ;A <- stack
         rti

chkrstr  ;No CIA-based NMIs, must be the
         ;Restore key. Check for STOP.

         cld          ;Just in case

         jsr $f6bc    ;Scan STOP Row
         jsr $ffe1    ;Read STOP status
         bne endnmi

         ;Loop until STOP is
         ;no longer depressed.

         jsr $f6bc    ;Scan STOP Row
         jsr $ffe1    ;Read STOP status
         beq *-6

         jsr quitapp
         jmp endnmi

;---------------------------------------

sethand  ;Set incoming data handlers
         ;C -> Clr = Command Mode
         ;C -> Set = Carrier Detect Mode
         ;RegPtr -> Handler routine ptr

         ;C <- clr = Command Mode
         ;C <- Set = Carrier Detected
         .block
         bcc *+10

         #stxy dcdmode+1
         bcs carrier

         #stxy cmdmode+1

         ;fallthrough... carrier
         .bend

carrier  ;C <- SET = Online  Mode
         ;C <- CLR = Command Mode

         ;Z <- SET = Online  Mode
         ;Z <- CLR = Command Mode

         sec ;Carrier Detect (Online)

         lda sw_stat
         and #sws_dcd
         beq *+3

         clc ;No Carrier (Offline)
         rts


pollget  ;Poll incoming data buffer
         ;Notify handler if available

         ;Check for buffer content

         lda rbuf_cnt
         bne *+3
         rts         ;Buffer Empty

         ;Buffer has content

         jsr carrier
         bcc cmdmode

dcdmode  jmp raw_rts ;CarrierDetect Mode

cmdmode  jmp raw_rts ;Command Mode


rsget    ;Read a byte from Rx Buffer
         ;
         ;C <- Set = Buffer Empty
         ;A <- Same as A came in
         ;
         ;C -> Clr = Byte returned
         ;A <- Byte from buffer
         .block
         sty ystash

         ;Check for buffer content

         ldy swidbs  ;Rx Buf Start Index
         cpy swidbe  ;Compare  End Index
         beq skipget ;C <- Set on empty

         ;Buffer has content

         lda (swibuf),y
         inc swidbs
         dec rbuf_cnt
         clc         ;C <- Clr on data
skipget

         ldy ystash
         rts
         .bend

rsput    ;Write a byte to Tx Buffer
         ;Initiates RS-232 transmission
         ;
         ;A -> byte to send
         ;A <- byte sent
         .block
         sty ystash

loop     ldy tbuf_cnt
         cpy #255
         beq loop

         ;Write byte to end of Tx Buffer

         ldy swodbe
         sta (swobuf),y
         inc swodbe
         inc tbuf_cnt

         ldy swn_rxtx
         sty sw_cmd

         ldy ystash

         clc
         rts
         .bend

;---------------------------------------
;Auxiliary RS-232 Routines

initstr_ .text "ate0v0x0f0"
         .null "r0&p0b";+baud

         ;Echo     Off  (e0)
         ;Verbose  Off  (v0)
         ;Extended Off  (x0)
         ;RTS/CTS  On   (f0)
         ;LineEnd  CR   (r0)
         ;PETSCII  Off (&p0)
         ;Logging  On  (&o1) ;Optional

joincmd_ .byte $22    ;quote
         .text "wta"  ;atw     reversed

getssid_ .byte $0d    ;CR
         .text "3ita" ;ati3    reversed

dialcmd_ .byte $22    ;quote
         .text "dta"  ;atd     reversed

hangup_  .text "hta"  ;ath     reversed

speed0   .null "300"
speed1   .null "1200"
speed2   .null "2400"

speed3   .null "4800"
speed4   .null "9600"

speed5   .null "14400"
speed6   .null "19200"
speed7   .null "38400"

spdlo    .byte <speed0,<speed1,<speed2
         .byte <speed3,<speed4
         .byte <speed5,<speed6,<speed7

spdhi    .byte >speed0,>speed1,>speed2
         .byte >speed3,>speed4
         .byte >speed5,>speed6,>speed7

ratemap  .byte swb_300  ;brc_3   ;0
         .byte swb_1200 ;brc_12  ;1
         .byte swb_2400 ;brc_24  ;2

         .byte swb_4800 ;brc_48  ;3
         .byte swb_9600 ;brc_96  ;4

         .byte swb14400 ;brc_144 ;5
         .byte swb19200 ;brc_192 ;6
         .byte swb38400 ;brc_384 ;7

sptr     = $61 ;$62           ;$1e ;$1f
ptr      = $63 ;$64           ;$20 ;$21


setrate  ;Set Data Rate
         ;A -> Baud rate code
         ;     range corrected to 38400

         ;C -> Set = Device and driver
         ;C <- Set on Error

         ;C -> Clr = Driver speed only
         ;C <- Set on Error

         ;A <- Error Code when C is Set
         ;     0 = Carrier Detected
         ;     1 = Baud Match Test Fail
         .block
         php

         ;Validate Range.
         cmp #brc_384+1
         bcc *+4
         lda #brc_384 ;Adjust to 38400

         tax

         plp
         bcc setdrvr

         jsr carrier
         bcc *+5
         lda #0 ;Carrier Detected
         ;C <- Set: Not in command mode
         rts

         ;Set device speed.

         lda spdlo,x
         sta ptr+0
         lda spdhi,x
         sta ptr+1

         ;Send start of init string

         ldy #0

         lda initstr_,y
         beq *+8
         jsr rsput
         iny
         bne *-9

         ;Send new baud rate string

         ldy #0

         lda (ptr),y
         beq *+8
         jsr rsput
         iny
         bne *-8

         ;Delay 60 Jiffies.
         ;Allow command to be sent.

         lda #60
         jsr delay

         ;Send final $0d to commit.

         lda #$0d
         jsr rsput

         ;Delay 65 Jiffies.
         ;Allow commit to be sent.
         ;Allow modem to change speed.

         lda #65
         jsr delay

         ;Drain receive buffer of echo
         ;and crap response during shift

         jsr rsget
         bcc *-3

         ;Switch driver rate before the
         ;response code is returned.

setdrvr  ;Set driver speed.
         ;X -> Baud rate code

         lda sw_ctrl

         and #%11110000 ;Clr Baud Rate
         ora ratemap,x  ;Set Baud Rate

         sta sw_ctrl

         ;Perform rate matching test

         jsr carrier
         bcc *+5
         lda #0 ;Carrier Detected
         ;C <- Set: Not in command mode
         rts


         ldx #0

         lda ratetest,x
         jsr rsput
         inx
         cpx #3
         bcc *-9

         lda #30   ;approx. 0.5 secs
         jsr delay

         ldx #0

         jsr rsget
         bcs *+10
         sta testbuf,x
         inx
         cpx #10
         bcc *-11

         cpx #2
         bcc testfail ;too few bytes
         dex

         ;Analyze Test Buffer

         ldy #0        ;Line Ending Flag

         ;Skip and flag line endings
         lda testbuf,x
         cmp #$0d      ;Carriage Return
         beq *+6
         cmp #$0a      ;Line Feed
         bne *+8
         tay
         dex
         bpl *-13
         bmi testfail  ;End of Buffer

         ;Found a non-line-end character

         cpy #0
         beq testfail  ;No line ending

         cmp #"0"
         beq testpass  ;non-verbose OK

         cmp #"k"      ;ASCII   "K"
         beq *+6
         cmp #"K"      ;PETSCII "K"
         bne testfail

         dex
         bmi testfail  ;End of Buffer
         lda testbuf,x

         cmp #"o"      ;ASCII   "O"
         beq testpass
         cmp #"O"      ;PETSCII "O"
         beq testpass

testfail lda #1 ;Baud Rate Mismatch
         sec
         rts

testpass clc
         rts

ratetest .text "at"
         .byte $0d

testbuf  .word 0,0,0,0,0  ;10 MAXIMUM!
         .bend

ssidstat ;Read]Join SSID
         ;C -> Clr = Read current SSID
         ;C -> Set = Join SSID
         ;  RegPtr -> SSID Join Struct

         ;C <- Set on Error
         ;A <- Error Code
         ;  0 = OK (Carrier Detected)
         .block
         bcc readssid

         jsr carrier
         bcc *+5
         lda #0     ;"OK" Response Code
         ;C <- Set:  Not in Command Mode
         rts

         #stxy ptr

         ldx #3

         lda joincmd_,x
         jsr rsput
         dex
         bpl *-7

         ;Output SSID
         ;sptr = ptr->wifi_ssid

         ldy #wifi_ssid
         lda (ptr),y
         sta sptr+0
         iny
         lda (ptr),y
         sta sptr+1

         ldy #0
         lda (sptr),y
         beq *+11
         jsr pet2asc
         jsr rsput
         iny
         bne *-11

         lda #","
         jsr rsput

         ;Output Password
         ;sptr = ptr->wifi_pass

         ldy #wifi_pass
         lda (ptr),y
         sta sptr+0
         iny
         lda (ptr),y
         sta sptr+1

         ldy #0
         lda (sptr),y
         beq *+11
         jsr pet2asc
         jsr rsput
         iny
         bne *-11

         lda #$22 ;quote
         jsr rsput
         lda #$0d ;CR
         jsr rsput

         clc ;Sent join Wifi Command
         rts

readssid jsr carrier
         bcc *+5
         lda #0     ;"OK" Response Code
         ;C <- Set:  Not in Command Mode
         rts

         ldx #4

         lda getssid_,x
         jsr rsput
         dex
         bpl *-7

         clc ;Sent read SSID Command
         rts
         .bend

opensock ;Open]Close TCP/IP Socket
         ;RegPtr -> Socket Struct
         ;C -> Clr = Open Socket
         ;C <- Set = Already Online
         ;C <- Clr = Dial command sent.

         ;C -> Set = Close Socket (H-UP)
         ;C <- Set = Already Offline
         ;C <- Clr = Cmd mode, Hang up.
         .block
         bcs doclose

         jsr carrier
         bcc *+3
         rts ;Error: Already online

         #stxy ptr

         ldx #3

         lda dialcmd_,x
         jsr rsput
         dex
         bpl *-7

         ;Output Host
         ;sptr = ptr->tcp_host

         ldy #tcp_host
         lda (ptr),y
         sta sptr+0
         iny
         lda (ptr),y
         sta sptr+1

         ldy #0
         lda (sptr),y
         beq *+11
         jsr pet2asc
         jsr rsput
         iny
         bne *-11

         lda #":"
         jsr rsput

         ;Output Port
         ;sptr = ptr->tcp_port

         ldy #tcp_port
         lda (ptr),y
         sta sptr+0
         iny
         lda (ptr),y
         sta sptr+1

         ldy #0
         lda (sptr),y
         beq *+8
         jsr rsput
         iny
         bne *-8

         lda #$22 ;quote
         jsr rsput
         lda #$0d ;CR
         jsr rsput

         clc ;Dial command sent.
         rts

doclose  ;Close current connection

         jsr carrier
         bcs *+4
         sec ;Error: Already Offline
         rts

         ;Delay 1 Second

         lda #60 ;NTSC 1 second
         ldx palflag
         beq *+4
         lda #50 ; PAL 1 second
         jsr delay

         ;Output "+++"
         lda #"+"
         jsr rsput
         jsr rsput
         jsr rsput

         ;Delay 1.5 Seconds

         lda #90 ;NTSC 1.5 seconds
         ldx palflag
         beq *+4
         lda #75 ; PAL 1.5 seconds
         jsr delay

         ldx #2
         lda hangup_,x
         jsr rsput
         dex
         bpl *-7

         clc ;Command mode, Hang up.
         rts
         .bend

;---------------------------------------

r2pause  ;Pause NMIs
         .block
         pha

         ;Mask Rx and Tx Interrupts

         lda #swc_dtr.swc_irq
         ;tc0 and tc1 both low... tmrh

         sta sw_cmd

         pla
         rts
         .bend

r2resum  ;Resume NMIs
         ;C <- clr = Command Mode
         ;C <- Set = Carrier Detected
         .block
         pha

         ;If tbuf_cnt = 0
         ; sw_cmd <- swn_rx
         ;If tbuf_cnt > 0
         ; sw_cmd <- swn_rxtx

         lda tbuf_cnt
         beq *+5

         lda swn_rxtx   ;NMI: Rx and Tx
         .byte $2c
         lda swn_rx     ;NMI: Rx only

         sta sw_cmd

         jsr carrier
         ;C <- Set = Carrier Detected

         pla
         rts
         .bend

;---------------------------------------
extern
         #inc_h "memory"
pgfree   #syscall lmem,pgfree_
pgalloc  #syscall lmem,pgalloc_

         #inc_h "service"
quitapp  #syscall lser,quitapp_

         #inc_h "string"
pet2asc  #syscall lstr,pet2asc_

         .byte $ff ;Terminator
