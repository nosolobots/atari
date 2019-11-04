    processor 6502
    seg code
    org $F000       ; define the code origin at $F000
                    ; code in an Atari ROM cartridge must be loaded at this address
start:
    sei             ; disable interrupts (even though we don't have interrupts in the Atari)
    cld             ; disable the BCD (Binary-Coded Decimal) decimal mode
    ldx #$FF        ; loads the X register with $FF
    txs             ; transfer X register to SP (inits SP with the value $FF)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Clear the Zero Page region ($00 to $FF)
; Meaning the entire TIA register space and also RAM
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    lda #0          ; A = 0
    ldx #$FF        ; X = $FF

loop:
    sta $0,X        ; stores A register at address $0 + X
    dex             ; X--
    bne loop        ; loop until X==0 (Z-flag set)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Fill ROM size to exactly 4KB ($F000 - $FFFF)
; The last 4 bytes must have the initial address of the ROM cartridge
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
    org $FFFC
    .word start     ; reset vector at $FFFC
    .word start     ; interrupt vector at $FFFE (unused in the Atari)

