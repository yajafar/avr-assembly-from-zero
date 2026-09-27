; 03 - Button Input with Internal Pull-up
;
; Board:  Arduino Nano
; MCU:    ATmega328P
; LED:    D13 / PB5 (built-in)
; Button: D3 / PD3, wired between the pin and GND
;
; Goal:
; Configure PD3 as an input with the internal pull-up enabled.
; Turn the LED on while the button is held, off when it is released.

.global main

.equ PIND,  0x09        ; Port D input pins register (read pin state here)
.equ DDRD,  0x0A        ; Port D data direction register
.equ PORTD, 0x0B        ; Port D output register (enables pull-up on inputs)
.equ PD3,   3           ; Arduino D3 / button

.equ DDRB,  0x04        ; Port B data direction register
.equ PORTB, 0x05        ; Port B output register
.equ PB5,   5           ; Arduino Nano built-in LED / D13

main:
    sbi DDRB, PB5       ; PB5 as output (LED)
    cbi DDRD, PD3       ; PD3 as input (default after reset, but be explicit)
    sbi PORTD, PD3      ; PD3 input + PORTD bit set = internal pull-up enabled

loop:
    sbis PIND, PD3      ; Skip next instruction if PD3 is HIGH (not pressed)
    rjmp button_pressed ; PD3 is LOW -> button is pressed

button_not_pressed:
    cbi PORTB, PB5      ; LED off
    rjmp loop           ; Without this, execution falls into button_pressed

button_pressed:
    sbi PORTB, PB5      ; LED on
    rjmp loop
