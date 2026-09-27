# AVR Assembly From Zero

A beginner-friendly AVR assembly series for the ATmega328P which is used in the Arduino Nano/Uno/Pro Mini, built from real hardware experiments, Windows command-line tools, disassembly, and the mistakes beginners actually make.

## Why this project exists
Most Arduino tutorials hide the hardware behind libraries.

That is great when you just want something to work, but not so great when you want to understand what the microcontroller is actually doing.

I started this project because I could not find a clear beginner-friendly path into AVR assembly. I had help from ChatGPT along the way, but there were still plenty of things it could not fully explain, so I had to dig through datasheets, forums, mistakes, and a lot of confused debugging.

This repo is my attempt to learn AVR assembly from the ground up, document the process honestly, and make that path easier for the next person.

No magic.  
No copy-paste-only examples.  
No AI slop.  
No pretending the first version always works.

Just registers, flags, pins, mistakes, fixes, datasheets, and LEDs that sometimes refuse to cooperate until you earn their respect.

## Hardware used

This project currently uses:

- Arduino board using the ATmega328P microcontroller (I'm using the Arduino Nano, you can also use the Arduino Uno)
- Breadboard and jumper wires
- Windows PC
  
<img src="images/hardware.jpeg" alt="Nano" width="200">

## Tools used

The workflow is based on Windows command-line tools, run from Command Prompt or PowerShell:

- `avr-gcc`
- `avr-objcopy`
- `avr-objdump`
- `avrdude`
- VS Code, optional

See [00 - Windows Setup](00-setup-windows/README.md) for how to install them.

The goal is to understand the real embedded workflow:

```text
Assembly source → ELF file → HEX file → Upload → Test on hardware → Inspect disassembly
```

## What this project covers

Current and planned topics include:

- AVR assembly basics
- Arduino Nano / ATmega328P register-level programming
- GPIO control
- `DDRx`, `PORTx`, and `PINx` registers
- Bit setting and clearing with `sbi` and `cbi`
- Read-modify-write patterns with `in`, `out`, `ori`, and `andi`
- Modifying bytes with bit masks
- Button input using pull-up logic
- Conditional branching
- Building and uploading by hand, one command per step
- Disassembly with `avr-objdump`
- Common beginner mistakes and why they happen

Future topics may include:

- Button debouncing
- Toggle logic
- Timers
- Timer interrupts
- UART serial output
- ADC input
- PWM
- More advanced bare-metal AVR projects

## Project structure

```text
avr-assembly-from-zero/
├── README.md
├── LICENSE
├── 00-setup-windows/
├── 01-blink-sbi-cbi/
├── 02-blink-read-modify-write/
├── 03-button-input-pullup/
├── docs/
└── images/
```

The structure may change as the project grows, but the goal is to keep each lesson focused and easy to follow.

## Current lessons

### 01 - Blink with `sbi` and `cbi`

The classic first project everyone knows: blinking the built-in LED.

But instead of using Arduino functions, this uses direct register control:

```asm
sbi DDRB, PB5
sbi PORTB, PB5
cbi PORTB, PB5
```

This introduces:

- Port direction registers
- Output registers
- Bit-level control
- Simple delay loops
- Infinite loops in assembly

### 02 - Blink with read-modify-write

This version rewrites the blink logic using:

```asm
in
ori
out
andi
```

This is slightly bigger and less efficient than `sbi`/`cbi`, but it teaches an important asm pattern:

```text
read register → modify bits → write register back
```

This pattern becomes important when working with more complex registers later.

### 03 - Button input with pull-up logic

This project uses a button connected between Arduino D3 / ATmega328P PD3 and GND. No external resistor is needed because the chip's internal pull-up is enabled in code.

The button uses pull-up logic:

```text
Not pressed = HIGH
Pressed     = LOW
```

The program reads `PIND`, checks the button state, and controls the LED on PB5.

This introduces:

- Input pins
- Pull-up resistors
- Active-low logic
- `sbis`
- Branching based on hardware input
- Fall-through mistakes in assembly

## Example: button-controlled LED

```asm
loop:
    sbis PIND, PD3
    rjmp button_pressed

button_not_pressed:
    cbi PORTB, PB5
    rjmp loop

button_pressed:
    sbi PORTB, PB5
    rjmp loop
```

This means:

```text
If PD3 is high, the button is not pressed, so turn the LED off.
If PD3 is low, the button is pressed, so turn the LED on.
```

Simple idea, but it teaches a lot.

Especially that labels do not stop code from falling through.

Ask me how I know.

## Building and uploading

There are no build scripts. Every lesson is built and uploaded with the same few commands, typed by hand, so you can see each step of the workflow.

From inside a lesson folder (shown here for `blink.S`):

```text
avr-gcc -mmcu=atmega328p -Os blink.S -o blink.elf
avr-objcopy -O ihex -R .eeprom blink.elf blink.hex
avrdude -p atmega328p -c arduino -P COM3 -b 115200 -D -U flash:w:blink.hex:i
```

1. `avr-gcc` turns the assembly source into an ELF file
2. `avr-objcopy` turns the ELF file into a HEX file
3. `avrdude` uploads the HEX file to the board

Replace `COM3` with your board's port (Device Manager → Ports (COM & LPT)).

If your board uses the old Nano bootloader, use `-b 57600` instead of `-b 115200`.

[00 - Windows Setup](00-setup-windows/README.md) explains every flag.

## Why disassembly matters

One of the most important tools in this project is:

```text
avr-objdump -d blink.elf
```

This shows what the assembler actually produced after it assembled our code.

That matters because assembly is close to machine code, but it is still not the same thing. The disassembly helps connect:

```text
what I wrote
```

to:

```text
what the microcontroller actually runs
```

For learning low-level programming, that connection is everything.

## Reference documents

These are the main references I use while working through the project:

- [ATmega328P datasheet](https://ww1.microchip.com/downloads/en/DeviceDoc/Atmel-7810-Automotive-Microcontrollers-ATmega328P_Datasheet.pdf)
- [Arduino Nano pinout](docs/Pinout-Nano.pdf)

## Common mistakes documented here

This project intentionally includes explanations of mistakes such as:

- Writing to `DDRD` when trying to read a button
- Forgetting that `DDRx` controls direction, while `PINx` reads input
- Using a bit mask where a bit number is expected
- Falling through from one label into another
- Using `jmp` when `rjmp` is enough
- Forgetting that active-low buttons read `0` when pressed
- Assuming assembly labels behave like blocks in high-level languages

These mistakes are not embarrassing. They are the actual learning process with actual mistakes I made so you don't fall into them like I did.

## Goal

The goal of this repository is not just to collect code.

The goal is to build a clear, practical, beginner-friendly path into AVR assembly and bare-metal microcontroller programming.

If this project helps someone understand AVR assembly a little faster, with a little less confusion, then it has done its job.

## License

This project is licensed under the MIT License.

You are free to use, modify, and share it, but please keep the original license and attribution.
