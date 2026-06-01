# 02 - Blink with Read-Modify-Write

Same LED, same blink. Different instructions.

Lesson 01 used `sbi` and `cbi` to flip individual bits directly. This lesson does the same thing using the **read-modify-write** pattern: `in`, `ori`, `andi`, `out`.

The result is identical. The approach is more general — and it is the pattern you will use for the rest of your AVR programming life.

## Hardware

- Arduino Nano/UNO/Pro Mini
- Built-in LED on D13 / PB5

No external components needed.

## Why Read-Modify-Write?

`sbi` and `cbi` are convenient, but they have a hard limit.

They only work on I/O registers at addresses `0x00` through `0x1F` in the I/O address space. `DDRB` is at `0x04` and `PORTB` is at `0x05`, so lesson 01 worked fine.

But most of the ATmega328P's peripheral registers — timers, UART, SPI, ADC — live at higher addresses. `sbi` and `cbi` cannot reach them.

The read-modify-write pattern works on any register, anywhere:

1. **Read** the current register value into a working register
2. **Modify** only the bits you care about, leaving all others alone
3. **Write** the modified value back to the register

This is the general-purpose technique. Learn it once, use it everywhere.

## Instructions Used

| Instruction | Meaning |
|---|---|
| `in r16, REG` | Load the value of I/O register `REG` into `r16` |
| `ori r16, mask` | Set bits: OR `r16` with `mask` (bit mask, not bit number) |
| `andi r16, mask` | Clear bits: AND `r16` with `mask` |
| `out REG, r16` | Write `r16` back to I/O register `REG` |

## Bit Masks vs Bit Numbers

This is the most common source of confusion when switching from `sbi`/`cbi` to read-modify-write.

`sbi` takes a **bit number**:

```asm
sbi PORTB, PB5      ; PB5 = 5, the bit number
```

`ori` and `andi` take a **bit mask** — a byte with a 1 in the right position:

```asm
ori r16, (1 << PB5) ; shifts 1 left by 5 places → 0b00100000 → 0x20
```

To **set** bit 5, you OR with `0x20`.

To **clear** bit 5, you AND with the complement — every bit set except bit 5:

```asm
andi r16, ~(1 << PB5) ; complement of 0x20 → 0b11011111 → 0xDF
```

The `~` operator flips all bits. The assembler evaluates this at compile time.

## Registers Used

Refer to the Datasheet of the ATmega328P chip.
![datasheet-pg280](../images/datasheet-ref-reg-summary-pg280.png)

```asm
.equ DDRB,  0x04
.equ PORTB, 0x05
.equ PB5,   5
```

Same registers as lesson 01. `DDRB` controls pin direction. `PORTB` controls output state.

According to the datasheet, setting a bit in DDRx to 1 makes it an output. Setting the corresponding bit in PORTx drives it HIGH or LOW.

![pin-config-datasheet](../images/datasheet-ref-pin-config-pg60.png)

## Code Walk-through

**Set PB5 as output:**

```asm
in  r16, DDRB           ; read current DDRB
ori r16, (1 << PB5)     ; set bit 5, preserve all other bits
out DDRB, r16           ; write back
```

We read first because other bits in `DDRB` may already be configured. Overwriting the whole register would break them. Read-modify-write preserves the rest.

**Turn LED on:**

```asm
in  r16, PORTB
ori r16, (1 << PB5)     ; set bit 5 HIGH
out PORTB, r16
```

**Turn LED off:**

```asm
in  r16, PORTB
andi r16, ~(1 << PB5)   ; clear bit 5 LOW
out PORTB, r16
```

**Delay and loop:**

Identical to lesson 01. Triple nested counter loop using `r18`, `r19`, `r20`. Not an accurate timer — just enough to make the blink visible.

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

Compare the output to lesson 01's disassembly. Where lesson 01 used a single `sbi` or `cbi` instruction, this lesson produces three instructions per bit operation:

```
in   r16, 0x05
ori  r16, 0x20
out  0x05, r16
```

Same result. Three times as many instructions. This is the trade-off: `sbi`/`cbi` are compact and fast for the registers they can reach; read-modify-write is universal.

## Demonstration

<img src="../images/01-blink-off.jpeg" alt="off" width="200"> <img src="../images/01-blink-on.jpeg" alt="on" width="200">

## What I Learned

- Why `sbi`/`cbi` have a register address limit and when they stop working
- How the read-modify-write pattern works: `in` → modify → `out`
- The difference between a bit number and a bit mask
- How `ori` sets bits without touching others
- How `andi` clears bits without touching others
- How `~` and `<<` build masks at compile time
- That more instructions does not always mean more capability — sometimes it just means more generality
