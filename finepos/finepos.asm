;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; -- horizpos.asm --
;; Moves the player bitmap horizontaly
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    processor 6502

    include "../include/VCS.H"
    include "../include/macro.h"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; RAM Variables Declaration
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    seg.u .Variables
    org $80
SpriteHeight    equ 9
MaxXPos         equ 150
MinXPos         equ 0
MaxYPos         equ 170
BGColor         equ $80
YPos            byte
XPos            byte

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ROM START
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    seg .Code
    org $F000       ; ROM cartridge initial address
.start

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Init system
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    CLEAN_START
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Init Var&Reg
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ldx #BGColor
    stx COLUBK      ; set Background_Color

    ldx #50         ; 
    stx XPos        ; XPos = MinXPos
    ldy #30        ; 
    sty YPos        ; YPos = 100

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Init Frame
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.new_frame
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 3 Vertical Sync
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    VERTICAL_SYNC

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Horizontal positioning (X+68 TIA clocks)/3 CPU cycles
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    lda XPos        
    sta WSYNC		; wait for beginning scanline 
    sta HMCLR		; reset old horizontal position
.hloop              	; loop (5 CPU cycles = divide by (3*5))
    sbc #15
    bcs .hloop

; use remainder for fine adjustment -7 to +8
    eor #7          ; (23-A)%16
    asl
    asl
    asl
    asl
    
    sta HMP0        ; set fine position
    sta RESP0       ; reset coarse position

    sta WSYNC
    sta HMOVE       ; aplly fine offset

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 37 Vertical Blank (-3)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    lda #2
    sta VBLANK     ; turn VBLANK off
    
    ldx #34         
.vblank
    sta WSYNC
    dex
    bne .vblank 

    lda #0
    sta VBLANK     ; turn VBLANK off

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Visible scanlines
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ldx #192            ; X = total scanlines

.LVScan
    txa                 ; A = X = current scanline
    sec                 ; set carry flag
    sbc YPos            ; A -= YPos
    cmp #SpriteHeight   ; (A - SpriteHeight) ?
    bcc .inSprite       ; if carry clear => borrow carry => (A<SpriteHeight) jmp 
    lda #0              ; if not, A = 0

.inSprite
    tay                 ; Y = A
    lda SpriteGrp,Y     ; A = (SpriteGrp + Y)
    sta WSYNC           ; wait sync
    sta GRP0            ; set graphic for player0
    lda SpriteCol,Y     ; A = (SpriteCol + Y)
    sta COLUP0          ; set color    

    dex                 ; X--
    bne .LVScan         ; next scanline

; Clear sprites before overscan
    stx GRP0
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; OVERSCAN (30)
    lda #2
    sta VBLANK
    ldx #30
loop_vblank30:
    sta WSYNC
    dex
    bne loop_vblank30
    lda #0
    sta VBLANK

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Update positions before new frame
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    inc XPos            ; (XPos)++
    ldx XPos            ; X = XPos
    sec
    cpx #MaxXPos        ; (X - MaxXPos)?
    bcc .xNotEOL        ; jump if X < MaxXPos
    ldx #MinXPos        ; reset XPos
    stx XPos
.xNotEOL
    
    ldy YPos            ; Y = YPos
    dey                 ; Y--
    bne .yUpdate        ; (Y>0)?
    ldy #MaxYPos        ; if not, Y = YPos
.yUpdate
    sty YPos

    jmp .new_frame  ; 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Sprite Colors
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    org $FFEA
SpriteCol:
    byte #$80
    byte #$40
    byte #$40
    byte #$42
    byte #$42
    byte #$44
    byte #$46
    byte #$C4
    byte #$C4

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Sprite Graphics
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SpriteGrp:
    byte #%00000000
    byte #%10111101
    byte #%10111101
    byte #%11111111
    byte #%00111100
    byte #%01011010
    byte #%00111100
    byte #%01000010
    byte #%10000001

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ROM END
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    org $FFFC
    word .start
    word .start