MCU = atmega328p
PORT ?= /dev/ttyUSB0
BAUD ?= 115200
TARGET ?= blink

all: $(TARGET).hex

$(TARGET).elf: $(TARGET).S
	avr-gcc -mmcu=$(MCU) -Os $< -o $@

$(TARGET).hex: $(TARGET).elf
	avr-objcopy -O ihex -R .eeprom $< $@
	avr-size --mcu=$(MCU) --format=avr $<

upload: $(TARGET).hex
	avrdude -v -p$(MCU) -carduino -P$(PORT) -b$(BAUD) -D -Uflash:w:$(TARGET).hex:i

disasm: $(TARGET).elf
	avr-objdump -d $(TARGET).elf

clean:
	rm -f *.elf *.hex
