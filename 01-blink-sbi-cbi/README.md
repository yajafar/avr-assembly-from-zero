# 01 - Blink with `sbi` and `cbi`

The hardware equivalent of "Hello, World." — except instead of printing to a terminal, you make a tiny light flash on and off.

Every programmer eventually ends up staring at a blinking LED wondering if they wired something wrong. It is a rite of passage.

The goal is to blink the Arduino Nano's built-in LED using AVR assembly and direct register control. No Arduino libraries. No `digitalWrite()`. Just the ATmega328P registers and two instructions.

## Hardware

- Arduino Nano/UNO/Pro Mini
- Built-in LED on D13 / PB5

No external components needed. The LED is already on the board.

## Why `sbi` and `cbi`?

These two instructions are the most direct way to flip a single bit in an I/O register:

- `sbi` — **S**et **B**it in **I**/O register
- `cbi` — **C**lear **B**it in **I**/O register

One instruction. One bit changed. Everything else in the register stays the same.

They do have a catch — they only reach I/O registers at addresses `0x00` through `0x1F`. For `DDRB` (`0x04`) and `PORTB` (`0x05`) that is no problem. Lesson 02 covers what to do when it is.

## Instructions Used

| Instruction | Meaning |
|---|---|
| `sbi REG, bit` | Set a single bit in an I/O register |
| `cbi REG, bit` | Clear a single bit in an I/O register |
| `rcall label` | Call a subroutine |
| `rjmp label` | Jump to a label (relative) |
| `ldi Rd, K` | Load an immediate value into a register |
| `dec Rd` | Decrement a register by 1 |
| `brne label` | Branch if the last result was not zero |
| `ret` | Return from subroutine |

## Registers Used

Refer to the Datasheet of the ATmega328P chip.
![datasheet-pg280](../images/datasheet-ref-reg-summary-pg280.png)

```asm
.equ DDRB,  0x04
.equ PORTB, 0x05
.equ PB5,   5
```

`DDRB` is the Port B **D**ata **D**irection **R**egister. Each bit controls whether a pin is an input or output:

- `0` = input
- `1` = output

`PORTB` controls the output state of Port B pins. For a pin configured as output:

- `0` = LOW
- `1` = HIGH

The built-in LED is on `PB5`, which is Arduino digital pin `D13`.

According to the datasheet, setting a bit in DDRx to 1 makes it an output. Setting the corresponding bit in PORTx then drives it HIGH or LOW.

![pin-config-datasheet](../images/datasheet-ref-pin-config-pg60.png)

## Code Walk-through

**Set PB5 as output:**

```asm
sbi DDRB, PB5       ; Set bit 5 of DDRB — PB5 is now an output
```

**Turn LED on:**

```asm
sbi PORTB, PB5      ; Set bit 5 of PORTB — PB5 goes HIGH, LED on
```

**Turn LED off:**

```asm
cbi PORTB, PB5      ; Clear bit 5 of PORTB — PB5 goes LOW, LED off
```

**Delay loop:**

The delay is three nested countdown loops using `r18`, `r19`, and `r20`. The CPU just sits there decrementing counters until they hit zero — burning clock cycles on purpose.

Is this a good timer? Absolutely not. Is it good enough to make an LED blink visibly? Yes.

```asm
delay:
    ldi r18, 255
big_loop:
    ldi r19, 255
middle_loop:
    ldi r20, 50
small_loop:
    dec r20
    brne small_loop
    dec r19
    brne middle_loop
    dec r18
    brne big_loop
    ret
```

Later lessons will replace this with hardware timers that are actually accurate.

## Build

```bash
make
```

## Upload

```bash
make upload
```

If your board is on a different port:

```bash
make upload PORT=/dev/ttyACM0
```

Old bootloader Nanos:

```bash
make upload BAUD=57600
```

## Disassemble

```bash
make disasm
```

Shows the actual machine instructions the assembler generated. Compare what you wrote with what came out — especially around the delay loop. Each `sbi` and `cbi` compiles down to a single instruction. That is the whole point of lesson 01.

## Demonstration

<img src="../images/01-blink-off.jpeg" alt="off" width="200"> <img src="../images/01-blink-on.jpeg" alt="on" width="200">

## What I Learned

- How to set a pin as output using `DDRB`
- How to control an output pin using `PORTB`
- How `sbi` and `cbi` flip a single bit without touching the rest of the register
- How labels and loops work in AVR assembly
- How a software delay loop wastes cycles on purpose
- How to build and upload AVR assembly from Linux
- That `sbi`/`cbi` have an address range limit (lesson 02 covers the fix)
