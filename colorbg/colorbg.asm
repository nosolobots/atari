    processor 6502

    include "../include/VCS.H"
    include "../include/macro.h"

    seg code
    org $F000       ; origin of the ROM cartridge

start:
    CLEAN_START     ; Macro to safetly clear the memory

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Set background luminosity color to yellow
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    lda #$1E        ; A = $1E (NTSC yellow)
    sta COLUBK      ; store A to BackgroundColor address ($09) 

    jmp start       ; repeat from start

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Fill ROM to exactly 4KB
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    org $FFFC
    .word start     ; reset vector at $FFFC
    .word start     ; interrupt vector at $FFFE (unused in VCS)
    