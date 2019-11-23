;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; -- horizmov.asm --
;; Reads input to move the player's bitmap horizontaly
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    processor 6502

    include "../include/VCS.H"
    include "../include/macro.h"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; RAM Variables Declaration
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    seg.u Variables
  
    org $80

SpriteHeight    equ 10
XMargin         equ 5
XInitial        equ 60
YInitial        equ 10
BGColor         equ 0
ShipXPos        .byte
ShipYPos        .byte

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ROM START
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    seg .Code
    
    org $F000       ; ROM cartridge initial address

start:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Init system
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    CLEAN_START
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Init Var&Reg
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ldx #XInitial   ; x,y position
    stx ShipXPos
    ldx #YInitial
    stx ShipYPos
    ldx #BGColor
    stx COLUBK

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Init Frame
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
new_frame:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 3 Vertical Sync
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    VERTICAL_SYNC

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Horizontal positioning (X+68 TIA clocks)/3 CPU cycles
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    lda ShipXPos
    adc #XMargin    ; add X-margin pixels

    sta WSYNC		; wait for beginning scanline 
    sta HMCLR		; reset old horizontal position
    sec             ; set carry flag before subtract
hzloop:            	; loop (5 CPU cycles = divide by (3*5))
    sbc #15
    bcs hzloop      ; branch if not carry clear (borrow)

; A contains (remainder-15)
; convert it for fine adjustment [-7 to +8]
    eor #7          ; (23-A)%16
    REPEAT 4        ; HMOVE only uses 4 MSB
        asl
    REPEND
    
    sta HMP0        ; set fine position
    sta RESP0       ; reset coarse position

    sta WSYNC
    sta HMOVE       ; aplly fine offset to all objects

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 37 Vertical Blank (-3 due to horizontal positioning)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    lda #2
    sta VBLANK     ; turn on VBLANK
    
    ldx #34         
VBlank34:
    sta WSYNC
    dex
    bne VBlank34 

    lda #0
    sta VBLANK     ; turn off VBLANK

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Visible scanlines
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ldx #192            ; X = total scanlines

LVScan:
    txa                 ; A = X = current scanline
    sec                 ; set carry flag
    sbc ShipYPos        ; A -= YPos
    cmp #SpriteHeight   ; (A - SpriteHeight) ?
    bcc inSprite        ; if carry clear => borrow carry => (A<SpriteHeight) jmp 
    lda #0              ; if not, A = 0

inSprite:
    tay                 ; Y = A
    lda SpriteGrp,Y     ; A = (SpriteGrp + Y)
    sta WSYNC           ; wait sync
    sta GRP0            ; set graphic for player0
    lda SpriteCol,Y     ; A = (SpriteCol + Y)
    sta COLUP0          ; set color    

    dex                 ; X--
    bne LVScan          ; next scanline

    stx GRP0            ; Clear sprites before overscan

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; OVERSCAN (30)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    lda #2
    sta VBLANK
    ldx #30
VBlank30:
    sta WSYNC
    dex
    bne VBlank30
    lda #0
    sta VBLANK

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Update Ship position before new frame
;; SWCHA (pressed=0)
;; b7 - P0 Right
;; b6 - P0 Left
;; b5 - P0 Down
;; b4 - P0 Up
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ldx ShipXPos    
    bit SWCHA           ; b6 -> Flag overflow (V)
    bvs .skipLeft
    dex
.skipLeft:
    bit SWCHA           ; b7 -> Flag Sign
    bmi .skipRight
    inx
.skipRight:
    stx ShipXPos        ; set new X position
    lda ShipXPos
    and #$7F            ; limit X range [0-127]
    sta ShipXPos        ; reset X position

    jmp new_frame

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Sprite Colors
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    org $FFE8

SpriteCol:
    byte #$00
    byte #$3B
    byte #$02
    byte #$04
    byte #$06
    byte #$0E
    byte #$0E
    byte #$96
    byte #$98
    byte #$0E

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Sprite Graphics
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SpriteGrp:
    byte #%00000000
    byte #%00101000
    byte #%01111100
    byte #%11111110
    byte #%11111110
    byte #%10111010
    byte #%00111000
    byte #%00010000
    byte #%00010000
    byte #%00010000

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ROM END
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    org $FFFC
    word start
    word start