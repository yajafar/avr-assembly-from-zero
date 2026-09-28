# 00 - Windows Setup

This section explains the Windows toolchain used to build and upload AVR assembly programs for the ATmega328P which is used in the Arduino Nano / Uno / PRO Mini.

I'm using the Arduino Nano, yes mine is a clone but it doesn't matter much for our use case.

<img src="../images/arduino-nano.jpeg" alt="Nano" width="200">

The basic workflow is:

```text
.S assembly source
        ↓
.elf executable file
        ↓
.hex uploadable file
        ↓
Arduino Nano flash memory
```

Every step is one command you type yourself. No build scripts, no IDE. That way you always know what is happening.

## Tools used

This project uses:

- `avr-gcc` - assembles and links AVR programs
- `avr-objcopy` - converts ELF files into HEX files
- `avr-objdump` - shows disassembly
- `avrdude` - uploads the HEX file to the Arduino Nano

All commands work the same in **Command Prompt** and **PowerShell**. Use whichever you like.

## Install the toolchain

You need two downloads. Both are plain zip files. Nothing to install, just unzip.

**1. AVR 8-bit Toolchain (avr-gcc, avr-objcopy, avr-objdump)**

Go to Microchip's GCC compilers page:

https://www.microchip.com/en-us/tools-resources/develop/microchip-studio/gcc-compilers

Download **AVR 8-Bit Toolchain (Windows)** and unzip it to a short path, for example:

```text
C:\avr\avr8-gnu-toolchain
```

Inside you will find a `bin` folder containing `avr-gcc.exe`. That `bin` folder is what goes on your PATH.

**2. avrdude**

Go to the avrdude releases page:

https://github.com/avrdudes/avrdude/releases

Download the file ending in `windows-x64.zip` (for example `avrdude-v8.3-windows-x64.zip`) and unzip it to:

```text
C:\avr\avrdude
```

`avrdude.exe` and `avrdude.conf` sit directly in that folder. Keep them together.

## Add the tools to PATH

PATH is the list of folders Windows searches when you type a command.

1. Press Start and search for **Edit environment variables for your account**
2. Select **Path** and click **Edit**
3. Click **New** and add the toolchain `bin` folder, e.g. `C:\avr\avr8-gnu-toolchain\bin`
4. Click **New** again and add `C:\avr\avrdude`
5. Click **OK** on every window
6. Close any open terminals and open a **new** one

The last step matters. Terminals that were already open still have the old PATH.

## Check it works

```text
avr-gcc --version
avrdude -?
```

`avr-gcc` should print its version. `avrdude` should print its usage help and version.

If you see `'avr-gcc' is not recognized as an internal or external command`, the PATH entry is wrong or you did not open a new terminal. Check that the folder you added really contains `avr-gcc.exe`.

## USB driver

Genuine Arduino boards usually install their driver automatically.

Most Nano clones (mine included) use a **CH340** USB chip instead. If Windows does not recognise the board, install the CH340 driver from the chip maker, WCH:

https://www.wch-ic.com/downloads/CH341SER_EXE.html

Then unplug and replug the board.

## Finding the COM port

Plug in the Arduino Nano and open **Device Manager**.

Expand **Ports (COM & LPT)**. You should see something like:

```text
USB-SERIAL CH340 (COM3)
```

The number at the end is your port. Mine is `COM3`, yours may be different.

Not sure which one is the Arduino? Unplug it and watch which entry disappears.

## Build, upload, disassemble

These are the commands used in every lesson. Shown here for `blink.S`.

Build:

```text
avr-gcc -mmcu=atmega328p -Os blink.S -o blink.elf
avr-objcopy -O ihex -R .eeprom blink.elf blink.hex
```

Upload (replace `COM3` with your port):

```text
avrdude -p atmega328p -c arduino -P COM3 -b 115200 -D -U flash:w:blink.hex:i
```

Disassemble:

```text
avr-objdump -d blink.elf
```

Run them from inside the lesson folder, for example:

```text
cd C:\path\to\avr-assembly-from-zero\01-blink-sbi-cbi
```

## What each part means

**avr-gcc**

| Part | Meaning |
|---|---|
| `-mmcu=atmega328p` | Build for the ATmega328P chip |
| `-Os` | Optimize for size |
| `blink.S` | The assembly source file |
| `-o blink.elf` | Name of the output file |

**avr-objcopy**

| Part | Meaning |
|---|---|
| `-O ihex` | Output format: Intel HEX, which avrdude uploads |
| `-R .eeprom` | Leave out EEPROM data, we only want flash |
| `blink.elf blink.hex` | Input file, output file |

**avrdude**

| Part | Meaning |
|---|---|
| `-p atmega328p` | The chip on the board |
| `-c arduino` | Upload through the Arduino bootloader |
| `-P COM3` | The port the board is on |
| `-b 115200` | Baud rate the bootloader talks at |
| `-D` | Don't erase the whole chip first (the bootloader handles it) |
| `-U flash:w:blink.hex:i` | Write (`w`) `blink.hex` into `flash`, file is Intel HEX (`i`) |

## Arduino Nano baud rate

Most newer Arduino Nano bootloaders use `115200`.

Some older Nano bootloaders use `57600`.

Mine uses 115200 baud, but yours might be different. If upload fails, try:

```text
avrdude -p atmega328p -c arduino -P COM3 -b 57600 -D -U flash:w:blink.hex:i
```

In the Arduino IDE this is the **ATmega328P (Old Bootloader)** option.

## Common upload errors

**`can't open device "COM3"`**

- Wrong COM port. Check Device Manager again.
- Something else has the port open, usually the Arduino IDE Serial Monitor. Close it.

**`not in sync` / `programmer is not responding`**

- Wrong baud rate. Try `-b 57600`.
- Wrong board or loose USB cable. Some cheap cables are charge-only and carry no data.

## Using a different source file

The file name appears in all three commands. If your file is `buttonblink.S`, replace `blink` with `buttonblink` everywhere:

```text
avr-gcc -mmcu=atmega328p -Os buttonblink.S -o buttonblink.elf
avr-objcopy -O ihex -R .eeprom buttonblink.elf buttonblink.hex
avrdude -p atmega328p -c arduino -P COM3 -b 115200 -D -U flash:w:buttonblink.hex:i
```

Tip: press the **Up arrow** in the terminal to bring back the last command instead of retyping it.

## Notes

This setup is intentionally simple.

The goal is not to build a complete AVR toolchain guide. The goal is to get a working Windows workflow for writing AVR assembly, building it, uploading it, and inspecting the disassembly.
