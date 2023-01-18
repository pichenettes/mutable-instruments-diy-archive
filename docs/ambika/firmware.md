Flashing the motherboard / voicecards firmware
----------------------------------------------

This section explains how to flash Ambika's firmware with an AVR
programmer - in case you are building it from scratch (the kits come
with pre-programmed chips). This is also helpful if you intend to modify
the code.

### Option 1: build the code and upload it with avrdude

The firmware code is hosted on
[github](http://github.com/pichenettes/ambika), in the `controller` and
`voicecard` directories. The required tools are python 2.5, GNU make,
avrdude, and avr-gcc version 4.3.3 (if you use another version you might
have to check that the voicecard code size is under 31744 bytes and the
motherboard code size under 61440 bytes). Some of the paths to these
tools have to be edited in avrlib/makefile.mk

To build the motherboard code (including MIDI/SD bootloader) and flash
it, connect the programmer to the motherboard and use:

    make bootstrap_controller

To build the voicecard code (including bootloader) and flash it, connect
the programmer to a voicecard and use:

    make bootstrap_voicecard

### Option 2: install pre-built binaries with avrdude

Download the following files:

-   [ambika_controller.hex](../static/firmware/ambika_controller.hex)
-   [ambika_controller_boot.hex](../static/firmware/ambika_controller_boot.hex)
-   [ambika_voicecard.hex](../static/firmware/ambika_voicecard.hex)
-   [ambika_voicecard_boot.hex](../static/firmware/ambika_voicecard_boot.hex)
-   [ambika_voicecard_eeprom_golden.hex](../static/firmware/ambika_voicecard_eeprom_golden.hex)

Connect the programmer to the motherboard. Type the following commands
in a terminal/command line:

````
avrdude -B 100 -V -p m644p -c avrispmkII -P usb -e -u -U efuse:w:0xfd:m
-U hfuse:w:0xd2:m -U lfuse:w:0xff:m -U lock:w:0x2f:m
````

````
avrdude -B 1 -V -p m644p -c avrispmkII -P usb -U
flash:w:ambika_controller.hex:i -U
flash:w:ambika_controller_boot.hex:i -U lock:w:0x2f:m
````

Hook the programmer to the voicecard. Type the following commands in a
terminal/command line:

````
avrdude -B 100 -V -p m328p -c avrispmkII -P usb -e -u -U efuse:w:0xfd:m
-U hfuse:w:0xde:m -U lfuse:w:0xff:m -U lock:w:0x2f:m
````


````
avrdude -B 1 -V -p m328p -c avrispmkII -P usb -U
flash:w:ambika_voicecard.hex:i -U flash:w:ambika_voicecard_boot.hex:i
-U eeprom:w:ambika_voicecard_eeprom_golden.hex:i -U lock:w:0x2f:m
````

Note that in all these commands, you will have to replace:

-   **avrdude** by the path to your local install of avrdude (for
    example `C:\WinAVR\bin\avrdude` on windows).
-   **avrispmkII** by the name of your ISP programmer.
-   **usb** by something else if your ISP programmer is not a USB one.

Copying the "factory data" (presets) to a SD card
-------------------------------------------------

1.  Format a SD card with a FAT or FAT32 filesystem (all the brand new
    voicecards we tested were correctly formatted).
2.  Unzip [this archive](../static/firmware/ambika_golden_card.zip) and
    copy the PROGRAM and MULTI directories to the root directory of the
    SD card.

