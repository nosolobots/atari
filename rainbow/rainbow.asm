;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Draw a colorful rainbow on the NTSC screen
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    processor 6502

    include "../include/VCS.H"
    include "../include/macro.h"

    seg code
    org $F000

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Init system
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
start:
    sei             ; disable interrupts
    cld             ; disable BCD
    ldx #$FF        ; X = FFh
    txs             ; SP = X = FFh

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Clear TIA & RAM ($00 - $FF)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ldx #0          ; X = 0
    txa             ; A = X = 0
clear_loop:
    dex             ; X--
    sta $0,X        ; ($0 + X) = A = 0
    bne clear_loop 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Start a new frame
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
new_frame:
    lda #2          ; A = 2
    sta VBLANK      ; turn on VBLANK
    sta VSYNC       ; turn on VSYNC

;; generate the 3 scanlines of the Vertical Sync
    sta WSYNC       ; wait for the the horizontal blank (sync   )
    sta WSYNC
    sta WSYNC
    
    lda #0
    sta VSYNC       ; turn off VSYNC 

;; generate the 37 scanlines of the Vertical Blank
    lda #2
    ldx #37
loop_vblank:    
    sta WSYNC
    dex
    bne loop_vblank

    lda $0
    sta VBLANK      ; turn off VBLANK

;; generate the 192 visible scanlines
    ldx #192
scanline:
    stx COLUBK
    sta WSYNC
    dex
    bne scanline 

;; generate the 30 scanlines of the Overscan
    lda #2
    sta VBLANK

    ldx #30
loop_overscan:    
    sta WSYNC
    dex
    bne loop_overscan

    lda #0
    sta VBLANK      ; turn off VBLANK

;; loop to draw the next frame
    jmp new_frame

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Fill 4KB
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    org $FFFC
    .word start     ; reset vector
    .word start     ; interrupt vector


