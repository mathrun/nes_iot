# NES IoT
Control modern IoT devices with an old school NES

#Sources

## main.asm

Main file written in assembler (for 6502 architectures).

* [6502 instruction set](http://e-tradition.net/bytes/6502/6502_instruction_set.html)

## nes.inc

# Tools

## CHR editor for MacOs

* [NES CHR editor](https://github.com/tsalvo/nes-chr-editor) (buggy but does it's job)

## NES Emulator

### FCEUX
 
The [fceux](http://www.fceux.com/web/home.html) is a great tool to emulate and debug the NES. There exists version for different 
 operating system but only the Windows Version is capable of a great debugging suite. 
 
**install Mac OS version** 

``brew install fceux``

**using fceux**
``fceux <nes-image>``

**using windows version**
The windows version works fine with the help of wine

#How to Build

``make run``

## Dependencies

### cc65
``brew install cc65``


## The Makefile


**CLEANABLE_FOLDERS**
These folders will be created due to the build process. Once they are created, they will be deleted before each new build. 

**ASSEMBLER**
The source code is written in assembler (for the 6502 architecture). This variable defines the compiler that transferred
everything to machine code. Default value is ``ca65``, a compiler that comes with the cc65 - library. 
 
**LINKER** 
Once each source code has been compiled, everything has to be linked together. Default vaule is ``ld65`` (included in cc65 library)

**EMU**
The emulator that runs the generated NES image file. This could be any emulator, the default one is ``fceux``.

**ASSFLAGS**
Optional Assembler flags, currently not used


