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

main:
    lda #0
    sta VBLANK

    lda #$02
    ; 3 lines of VSYNC
    sta VSYNC

    .rept 3
    sta WSYNC
    .endr

    lda #0
    sta VSYNC

    ; 37 lines of VBLANK
    .rept (VBLANK_LINES - 3)
    sta WSYNC
    .endr

    lda $00
    sta VSYNC

    ldx #0
    .rept (KERNAL_LINES)
    inx
    stx COLUBK
    sta WSYNC
    .endr

    lda #%01000010
    sta VBLANK ; end of screen - enter blanking

    .rept (OVERSCAN_LINES)
    sta WSYNC
    .endr

    jmp main


irq_brk:
    ; The 6507 has RESb tied high, so this can only be reached by BRK
    rti

; Vector locations
  .org (ROM_TOP - 5)
  .word reset   ; NMI - should not be possible
  .word reset
  .word irq_brk ; IRQ/BRK
