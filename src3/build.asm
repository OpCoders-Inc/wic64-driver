
debug = 1

.include "wic64.h"
.include "./os/h/modules.h"

;*=$1000
*=$e100

.include "inc.asm"

.include "main.asm"

.include "debug.asm"

.include "vars.asm"

.include "jlink.asm"
.include "junlink.asm"
.include "jsethand.asm"
.include "jpollget.asm"
.include "jssidstat.asm"
.include "jdataget.asm"
.include "jdataput.asm"
.include "jsetrate.asm"
.include "jopensock.asm"

.include "wic64.asm"

.include "data.asm"

.include "sys.asm"

.byte $ff
