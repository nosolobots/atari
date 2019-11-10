;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; -- playfield.asm --
;; Renders a yellow rectangular playfield over a blue background
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    processor 6502

    include "../include/VCS.H"
    include "../include/macro.h"

    seg code
    org $F000

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Init System
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
start:
    sei             ; disable interrupts (not used)
    cld             ; diseble BCD
    ldx #$FF
    txs             ; set SP=$FF

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Clear TIA & RAM ($00 - $FF)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ldx #0          ; X=0
    txa             ; A=0
clear_loop:
    dex             ; X-- (first iteration X=$FF)
    sta $0,X        ; ($0 + X) = 0
    bne clear_loop  ; jump if not Z

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Set constant TIA values
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    lda #$84        ; X=64 (NTSC Blue)
    sta COLUBK      ; set Background color
    lda #$1C        ; X=97 (NTSC Green)
    sta COLUPF      ; set Playfield color
    lda #1          ; X=1
    sta CTRLPF      ; Reflect Playfield (D0=1)          

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Draw new frame
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
new_frame:
    lda #2          
    sta VBLANK      ; turn on VBLANK
    sta VSYNC       ; turn on VSYNC

;; Generate 3 lines of VSYNC
    sta WSYNC
    sta WSYNC
    sta WSYNC
    lda #0
    sta VSYNC       ; turn off VSYNC

;; Generate 37 lines of VBLANK
    ldx #37
loop_vblank:
    sta WSYNC
    dex
    bne loop_vblank
    sta VBLANK      ; turn off VBLANK

;; Generate 7 scanlines (no playfield)
    lda #0
    sta PF0
    sta PF1
    sta PF2
    ldx #7
loop_bg_top:
    sta WSYNC
    dex
    bne loop_bg_top

;; Generate top 7 playfield (-###################)
    lda #$E0      
    sta PF0         ; PF0 = XXX0 0000 > -###
    lda #$FF
    sta PF1         ; PF1 = XXXX XXXX > ########
    sta PF2         ; PF2 = XXXX XXXX > ########
    ldx #7
loop_pf_top:
    sta WSYNC
    dex
    bne loop_pf_top

;; Generate top 164 playfield (same PF0) (-#------------------)
    lda #$20
    sta PF0         ; PF0 = 00X0 0000 > -#--
    lda #0
    sta PF1         ; PF1 = XXX0 0000 > --------
    sta PF2         ; PF2 = 0000 0000 > --------
    ldx #164
loop_pf_middle:
    sta WSYNC
    dex
    bne loop_pf_middle

;; Generate bottom 7 playfield (-###################)
    lda #$E0      
    sta PF0         ; PF0 = XXX0 0000 > -###
    lda #$FF
    sta PF1         ; PF1 = XXXX XXXX > ########
    sta PF2         ; PF2 = XXXX XXXX > ########
    ldx #7
loop_pf_bottom:
    sta WSYNC
    dex
    bne loop_pf_bottom

;; Generate 7 scanlines (no playfield)
    lda #0
    sta PF0
    sta PF1
    sta PF2
    ldx #7
loop_bg_bottom:
    sta WSYNC
    dex
    bne loop_bg_bottom

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
;; Fill 4KB Cartridge ROM
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    org $FFFC
    .word start     ; reset vector
    .word start     ; interrupt vector (not used)