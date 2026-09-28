# 03 - Button Input with Pull-up Logic

Lessons 01 and 02 only talked *to* the hardware. This one listens.

A push button on D3 controls the built-in LED. Hold the button and the LED turns on. Release it and the LED turns off.

It sounds trivial. It is not. This is the first lesson where the program makes a decision based on the outside world, and the first one where a missing line of code produces a bug that looks like a hardware problem.

## Hardware

- Arduino Nano/UNO/Pro Mini
- Built-in LED on D13 / PB5
- One push button
- Breadboard and two jumper wires

Wiring:

```text
D3 (PD3) ───┤ button ├─── GND
```

No resistor. The ATmega328P has one built in, and we turn it on in code.

> **4-leg tactile buttons:** the two legs on each long side are already connected internally. If the LED is always on, rotate the button 90° or wire diagonally across it.

## Why a Pull-up?

An input pin that is connected to nothing is **floating**. It picks up noise from your hand, the wires, and the room. Reading it gives random `0`s and `1`s.

A pull-up resistor gently pulls the pin to 5V (HIGH) when nothing else is driving it. The button connects the pin straight to GND, which overpowers the resistor and pulls it LOW.

| Button | Pin connected to | Pin reads |
|---|---|---|
| Not pressed | 5V (through pull-up) | `1` (HIGH) |
| Pressed | GND | `0` (LOW) |

This is called **active-low**: pressed means `0`. It feels backwards at first. It is the most common way buttons are wired on microcontrollers because it only needs one wire and the internal resistor.

The ATmega328P's internal pull-up is roughly 20–50 kΩ (datasheet, "Pin Pull-up" in the electrical characteristics).

## Instructions Used

| Instruction | Meaning |
|---|---|
| `sbi REG, bit` | Set a single bit in an I/O register |
| `cbi REG, bit` | Clear a single bit in an I/O register |
| `sbis REG, bit` | **S**kip next instruction if **B**it in **I**/O register is **S**et |
| `sbic REG, bit` | **S**kip next instruction if **B**it in **I**/O register is **C**leared (not used here, but it is the mirror of `sbis`) |
| `rjmp label` | Jump to a label (relative) |

`sbis` is new. It does not jump to a label. It checks one bit and, if that bit is `1`, skips over the **next single instruction**. That is the only branching tool this lesson needs.

Like `sbi` and `cbi`, `sbis` and `sbic` only work on I/O registers `0x00`–`0x1F`. `PIND` is at `0x09`, so we are fine.

## Registers Used

Refer to the Datasheet of the ATmega328P chip.
![datasheet-pg280](../images/datasheet-ref-reg-summary-pg280.png)

```asm
.equ PIND,  0x09
.equ DDRD,  0x0A
.equ PORTD, 0x0B
.equ PD3,   3

.equ DDRB,  0x04
.equ PORTB, 0x05
.equ PB5,   5
```

Every port has three registers. Until now we only needed two of them.

| Register | Job | For an input pin |
|---|---|---|
| `DDRx` | Direction | `0` = input |
| `PORTx` | Output value | `1` = enable pull-up |
| `PINx` | **Read** the actual pin level | This is where the button state lives |

The surprising one is `PORTx`. On an output pin it sets HIGH or LOW. On an input pin it switches the internal pull-up on or off. Same bit, different meaning, depending on `DDRx`.

The datasheet table shows every combination. The row we want is `DDxn = 0`, `PORTxn = 1`: input with pull-up.

![pin-config-datasheet](../images/datasheet-ref-pin-config-pg60.png)

## Code Walk-through

**Setup:**

```asm
sbi DDRB, PB5       ; PB5 as output (LED)
cbi DDRD, PD3       ; PD3 as input
sbi PORTD, PD3      ; enable internal pull-up on PD3
```

Every pin is an input after reset, so `cbi DDRD, PD3` is technically redundant. It is there because code that says what it means is easier to debug than code that relies on defaults.

**The decision:**

```asm
loop:
    sbis PIND, PD3      ; skip next instruction if PD3 is HIGH
    rjmp button_pressed ; only runs if PD3 is LOW
```

Read it as two cases:

- **Not pressed:** PD3 is `1`. `sbis` skips the `rjmp`. Execution continues at `button_not_pressed`.
- **Pressed:** PD3 is `0`. `sbis` does not skip. The `rjmp` runs and jumps to `button_pressed`.

**The two outcomes:**

```asm
button_not_pressed:
    cbi PORTB, PB5      ; LED off
    rjmp loop

button_pressed:
    sbi PORTB, PB5      ; LED on
    rjmp loop
```

Both paths end with `rjmp loop`. That line matters more than it looks. See the mistakes section below.

There is no delay in this program. The loop runs more than two million times per second, checking the button every few clock cycles.

## Mistakes I Made (So You Don't Have To)

All three of these assemble without a single warning. The assembler cannot know what you meant.

### 1. Checking `DDRD` instead of `PIND`

```asm
sbis DDRD, PD3      ; WRONG
```

`DDRD` bit 3 is the *direction* of the pin. We set it to `0` (input). It is always `0`, so `sbis` never skips, and the program always jumps to `button_pressed`.

**Symptom:** LED is always on. Button does nothing.

### 2. Checking `PORTD` instead of `PIND`

```asm
sbis PORTD, PD3     ; WRONG
```

`PORTD` bit 3 is what *we* wrote to enable the pull-up. It is always `1`, so `sbis` always skips.

**Symptom:** LED is always off. Button does nothing.

`PORTx` is what you write. `PINx` is what the pin actually is. To read a button, always read `PINx`.

### 3. Falling through a label

```asm
button_not_pressed:
    cbi PORTB, PB5      ; LED off
                        ; <-- missing rjmp loop
button_pressed:
    sbi PORTB, PB5      ; LED on
    rjmp loop
```

Labels are not blocks. They are just names for addresses. Nothing stops the CPU at `button_pressed:`. It runs straight from `cbi` into `sbi`.

**Symptom:** LED is on whether the button is pressed or not. When not pressed it is actually switching off and on millions of times per second, so it may look very slightly dimmer. It looks exactly like a wiring fault. It is not.

### Bonus: Forgetting it is active-low

```asm
sbic PIND, PD3      ; skip if CLEAR
rjmp button_pressed
```

This is valid code. It is just backwards for a pull-up button: the LED turns on when the button is *released*. If your LED logic is inverted, check whether you used `sbis` or `sbic`.

## Build

Run these from inside this lesson's folder:

```text
avr-gcc -mmcu=atmega328p -Os button.S -o button.elf
avr-objcopy -O ihex -R .eeprom button.elf button.hex
```

## Upload

Replace `COM3` with your board's port:

```text
avrdude -p atmega328p -c arduino -P COM3 -b 115200 -D -U flash:w:button.hex:i
```

Old bootloader Nanos: use `-b 57600` instead of `-b 115200`.

Not sure what your port is, or what each flag means? See [00 - Windows Setup](../00-setup-windows/README.md).

## Disassemble

```text
avr-objdump -d button.elf
```

The main loop comes out like this:

```
00000086 <loop>:
  86:	4b 9b       	sbis	0x09, 3
  88:	02 c0       	rjmp	.+4      	; 0x8e <button_pressed>

0000008a <button_not_pressed>:
  8a:	2d 98       	cbi	0x05, 5
  8c:	fc cf       	rjmp	.-8      	; 0x86 <loop>

0000008e <button_pressed>:
  8e:	2d 9a       	sbi	0x05, 5
  90:	fa cf       	rjmp	.-12     	; 0x86 <loop>
```

Things worth noticing:

- Every instruction is 2 bytes. `sbis` skips exactly one 2-byte instruction, the `rjmp`.
- `rjmp .+4` and `rjmp .-8` are offsets, not addresses. `rjmp` jumps relative to where it is, which is why it fits in one word.
- `button_not_pressed` is not an instruction. It is just the address `0x8a`. That is mistake #3 in plain sight.

## Demonstration

<!-- TODO: add photos of button pressed / released -->

## What I Learned

- The difference between `DDRx`, `PORTx`, and `PINx`, and that input comes from `PINx`
- That `PORTx` enables the pull-up when the pin is an input
- Why floating inputs are a problem and how a pull-up fixes it
- Active-low logic: pressed reads `0`
- How `sbis` / `sbic` branch by skipping one instruction
- That labels do not stop execution, and a missing `rjmp` falls straight through
- That wrong-register bugs assemble cleanly and look like hardware faults
