;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; -- horizpos.asm --
;; Moves the player bitmap horizontaly
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    processor 6502

    include "vcs.h"
    include "macro.h"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; RAM Variables Declaration
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    seg.u .Variables
    org $80
SpriteHeight    equ 9
MaxXPos         equ 200
MinXPos         equ 10
MaxYPos         equ 170
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
    sei             ; disable interrupts
    cld             ; disable BCD
    ldx #$FF        ; X = $FF
    txs             ; SP = $FF

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Clear TIA&RAM
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    lda #0          ; A = 0
    tax             ; X = A
.clear
    dex             ; X--
    sta $0,X        ; ($0 + X) = A
    bne .clear      ; if !Z jmp .clear

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Init Var&Reg
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ldx #$80        ; X = $80
    stx COLUBK      ; Background_Color = $80

    ldx #100        ; X = 100
    stx XPos        ; XPos = 100
    stx YPos        ; YPos = 100

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Init Frame
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.new_frame

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 3 Vertical Sync
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    lda #2          ; A = 2
    sta VSYNC       ; activate Vertical Sync
    REPEAT 3        
        sta WSYNC   ; wait 3 sync's
    REPEND
    lda #0      
    sta VSYNC       ; deactivate Vertical Sync

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Horizontal coarse positioning (X+68 TIA clocks)/3 CPU cycles
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    lda XPos        
    adc #68
    sec
    sta WSYNC 
.hloop              ; loop (5 CPU cycles = divide by (3*5))
    sbc #15
    bcs .hloop
    sta RESP0       ; activate horizontal pos

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 37 Vertical Blank (-1 because previous WSYNC)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    lda #2      
    sta VBLANK      ; activate Vertical Blank
    ldx #36         ; do 37(-1) scanlines
.vblank
    sta WSYNC
    dex
    bne .vblank 
    stx VBLANK      ; deactivate Vertical Blank
    
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
    lda SpriteCol,Y     ; A = (SpriteCol + Y)
    sta COLUP0          ; set color
    lda SpriteGrp,Y     ; A = (SpriteGrp + Y)
    sta WSYNC           ; wait sync
    sta GRP0            ; set graphic for player0

    dex                 ; X--
    bne .LVScan         ; next scanline

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; OVERSCAN (30)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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
    byte #0
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