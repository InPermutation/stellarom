; TIA Write addresses
VSYNC = $00
VBLANK = $01
WSYNC = $02
RSYNC = $03
NUSIZ0 = $04
NUSIZ1 = $05
COLUP0 = $06
COLUP1 = $07
COLUPF = $08
COLUBK = $09
CTRLPF = $0A
REFP0 = $0B
REFP1 = $0C
PF0 = $0D
PF1 = $0E
PF2 = $0F
RESP0 = $10
RESP1 = $11
RESM0 = $12
RESM1 = $13
RESBL = $14
AUDC0 = $15
AUDC1 = $16
AUDF0 = $17
AUDF1 = $18
AUDV0 = $19
AUDV1 = $1A
GRP0 = $1B
GRP1 = $1C
ENAM0 = $1D
ENAM1 = $1E
ENABL = $1F
HMP0 = $20
HMP1 = $21
HMM0 = $22
HMM1 = $23
HMBL = $24
VDELP0 = $25
VDELP1 = $26
VDELBL = $27
RESMP0 = $28
RESMP1 = $29
HMOVE = $2A
HMCLR = $2B
CXCLR = $2C

; TIA Read addresses
CXM0P = $0
CXM1P = $1
CXP0FB = $2
CXP1FB = $3
CXM0FB = $4
CXM1FB = $5
CXBLPF = $6
CXPPMM = $7
INPT0 = $8
INPT1 = $9
INPT2 = $A
INPT3 = $B
INPT4 = $C
INPT5 = $D



; RIOT (6532) ports
SWCHA = $280 ; Port A - joysticks, active low (R0 L0 D0 U0 R1 L1 D1 U1)
             ;          paddles, active low   (P0 P1  x  x P2 P3  x  x)
SWACNT = $281 ; DDR for Port A (output/input)
SWCHB = $282 ; Console switches:
; Player 1 pro/amateur, Player 0 pro/amateur,
; x, x, color/b&w, x, select, reset
SWBCNT = $283 ; DDR for Port B (hardwired as input)

INTIM = $284 ; Timer output (R/o)

TIM1T = $294 ; 838 nsec/interval
TIM8T = $295 ; 6.7 usec/interval
TIM64T = $296 ; 53.6 usec/interval
T1024T = $297 ; 858.2 usec/interval

VBLANK_LINES = 40 ; 2548 usec
KERNAL_LINES = 192 ; 12228 usec
OVERSCAN_LINES = 30 ; 1910 usec
; sum:
FRAME_LINES = 262 ; 16686 usec

RAM_BASE = $80
RAM_TOP = $FF

  .org $F000
reset:
  cld ; state of decimal flag is unknown on power-up

  ; initialize stack pointer to $01FF
  ; (which is a mirror of $00FF)
  ldx #$FF
  txs

  cli

StartOfFrame:
    lda #0
    sta VBLANK

    lda #$02
    ; 3 lines of VSYNC
    sta VSYNC

    sta WSYNC
    sta WSYNC
    sta WSYNC

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

    jmp StartOfFrame


irq_brk:
    ; The 6507 has RESb tied high, so this can only be reached by BRK
    rti

; Vector locations
  .org $fffa
  .word reset
  .word reset
  .word reset
