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
VisibleMissileLine: byt
    .dend

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
    sta COLUP0

    lda #80
    sta YPosFromBot ; set initial Y position

    ; Quad width sprite & missiles
    lda #$20
    sta NUSIZ0


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

WaitForVblankEnd:
    lda INTIM
    bne WaitForVblankEnd
    ldy #191

    sta WSYNC
    sta VBLANK
    lda #$F0
    sta HMM0

    sta WSYNC
    sta HMOVE

    dec YPosFromBot
    bne ScanLoop
    lda #192
    sta YPosFromBot


ScanLoop:
    sta WSYNC

    cpy YPosFromBot
    bne SkipActivateMissile
    lda #8
    sta VisibleMissileLine
SkipActivateMissile:
    lda #0
    sta ENAM0

    lda VisibleMissileLine
    beq FinishMissile
IsMissileOn:
    lda #2
    sta ENAM0
    dec VisibleMissileLine
FinishMissile:
    sty COLUBK
    dey
    bne ScanLoop

    lda #2
    sta WSYNC
    sta VBLANK

    ldx #30
OverScanWait:
    sta WSYNC
    dex
    bne OverScanWait

    jmp main


irq_brk:
    ; The 6507 has RESb tied high, so this can only be reached by BRK
    rti

; Vector locations
  .org (ROM_TOP - 5)
  .word reset   ; NMI - should not be possible
  .word reset
  .word irq_brk ; IRQ/BRK
