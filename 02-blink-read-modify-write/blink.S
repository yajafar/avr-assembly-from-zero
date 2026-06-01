; 02 - Blink Built-in LED using Read-Modify-Write
;
; Board: Arduino Nano
; MCU:   ATmega328P
; LED:   D13 / PB5
;
; Goal:
; Configure PB5 as output and blink it using the read-modify-write
; pattern (in/ori/out and in/andi/out) instead of sbi/cbi.

.global main

.equ DDRB,  0x04        ; Port B data direction register
.equ PORTB, 0x05        ; Port B output register
.equ PB5,   5           ; Arduino Nano built-in LED / D13

main:
    in  r16, DDRB           ; Read current DDRB value
    ori r16, (1 << PB5)     ; Set bit 5, leave other bits unchanged
    out DDRB, r16           ; Write back — PB5 is now an output

loop:
    in  r16, PORTB          ; Read current PORTB value
    ori r16, (1 << PB5)     ; Set bit 5 — LED on
    out PORTB, r16          ; Write back
    rcall delay

    in  r16, PORTB          ; Read current PORTB value
    andi r16, ~(1 << PB5)   ; Clear bit 5 — LED off
    out PORTB, r16          ; Write back
    rcall delay

    rjmp loop


delay:
    ldi r18, 255            ; Big loop counter

big_loop:
    ldi r19, 255            ; Middle loop counter

middle_loop:
    ldi r20, 50             ; Small loop counter

small_loop:
    dec r20
    brne small_loop

    dec r19
    brne middle_loop

    dec r18
    brne big_loop

    ret
