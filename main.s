    .include 'tia.s'
    .include 'riot.s'

; 262 scanlines per frame, including:
VBLANK_LINES = 40 ; 2548 usec
KERNAL_LINES = 192 ; 12228 usec
OVERSCAN_LINES = 30 ; 1910 usec

RAM_BASE = $80
RAM_TOP = $FF
ROM_BASE = $1000
ROM_TOP = $1FFF

; Statically allocated RAM variable locations
    .dsect
    .org RAM_BASE
YPosFromBot: byt
VisiblePlayerLine: byt
PlayerColor: byt
PlayerBuffer: byt
PlayfieldCounter: blk 3
ClearBk: byt
    .dend

PFCOL = $86
FLASHCOL = $1E ; $00 would disable the flash behavior, use $01 for black

  .org ROM_BASE
reset:
    ; update status register
    sei ; disable interrupts. IRQb is tied high anyway.
    cld ; state of decimal flag is unknown on power-up

    ; clear A & Y registers
    lda #0
    tay

    ; initialize stack pointer to $01FF
    ; (which is a mirror of $00FF)
    ldx #$FF
    txs
; Postconditions: A = 0, X = $FF, Y = 0

; Clear the zero page (64b TIA latches x2, 128b RAM)
; Preconditions: A = 0, X = $FF
clear_zpage:
    sta 0,X
    dex
    bne clear_zpage
; Postconditions: A = 0, X = 0
    lda #$BE ; Bright green
    sta PlayerColor

    lda #80
    sta YPosFromBot ; set initial Y position

    lda #2
    sta ENAM1
    lda #33
    sta COLUP1

    ; Quad width sprite & missiles for P1/M1
    lda #$20
    sta NUSIZ1

    lda #$F0
    sta HMM1

    lda #PFCOL
    sta COLUPF

main:
    lda #0
    sta VBLANK

    lda #$02
    ; 3 lines of VSYNC
    sta VSYNC

    .rept 3
    sta WSYNC
    .endr

    lda #43
    sta TIM64T

    lda #0
    sta VSYNC

    lda #%00010000 ; Down
    bit SWCHA
    bne SkipMoveDown
    inc YPosFromBot
SkipMoveDown:
    lda #%00100000 ; Up
    bit SWCHA
    bne SkipMoveUp
    dec YPosFromBot
SkipMoveUp:
    ldx #0
    lda #%01000000 ; Left
    bit SWCHA
    bne SkipMoveLeft
    ldx #$10 ; HM_ $10 = move left 1px/frame

    lda #%00001000 ; a 1 in D3 of REFP0 says make it mirror
    sta REFP0
SkipMoveLeft:
    lda #%10000000 ; Right
    bit SWCHA
    bne SkipMoveRight
    ldx #$F0 ; HM_ $F0 = move right 1px/frame
    lda #%00000000 ; moving right -> don't mirror
    sta REFP0

SkipMoveRight:
    stx HMP0
    lda INPT4
    bmi ButtonNotPressed
    inc PlayerColor
ButtonNotPressed:
    lda PlayerColor
    sta COLUP0

    clc
    lda PlayfieldCounter
    sta PF2
    adc #1
    sta PlayfieldCounter
    lda PlayfieldCounter+1
    sta PF1
    adc #0
    sta PlayfieldCounter+1
    lda PlayfieldCounter+2
    sta PF0
    adc #0
    sta PlayfieldCounter+2

    lda #0
    sta ClearBk
    lda #%10000000
    bit CXM1P
    beq NoCollision
    lda #FLASHCOL
    sta ClearBk
NoCollision:
    sta CXCLR


WaitForVblankEnd:
    lda INTIM
    bne WaitForVblankEnd
    ldy #KERNAL_LINES - 1

    sta WSYNC
    sta VBLANK

    sta WSYNC
    sta HMOVE

ScanLoop:
    sta WSYNC

    lda PlayerBuffer
    sta GRP0
    lda ClearBk
    beq NoFlash
    sta COLUBK
    jmp HadFlash
NoFlash:
    sty COLUBK
HadFlash:

CheckActivatePlayer:
    cpy YPosFromBot
    bne SkipActivatePlayer
    lda #8
    sta VisiblePlayerLine
SkipActivatePlayer:
    lda #0
    sta PlayerBuffer

    ldx VisiblePlayerLine
    beq FinishPlayer
IsPlayerOn:
    lda BigHeadGraphic-1,X
    sta PlayerBuffer
    dec VisiblePlayerLine
FinishPlayer:
    dey
    bne ScanLoop

    lda #0
    sta PlayerBuffer

    lda #2
    sta WSYNC
    sta VBLANK

    ldx #OVERSCAN_LINES
OverScanWait:
    sta WSYNC
    dex
    bne OverScanWait

    jmp main


BigHeadGraphic:
    .byte %00111100
    .byte %01111110
    .byte %11000001
    .byte %10111111
    .byte %11111111
    .byte %11101011
    .byte %01111110
    .byte %00111100

irq_brk:
    ; The 6507 has RESb tied high, so this can only be reached by BRK
    rti

; Vector locations
  .org (ROM_TOP - 5)
  .word reset   ; NMI - should not be possible
  .word reset
  .word irq_brk ; IRQ/BRK
