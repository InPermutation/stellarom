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

