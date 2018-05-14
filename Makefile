################################################################################
# VARIABLEN                                                                    #
################################################################################

# Dateien, die durch ein 'clean' gel�scht werden sollen
CLEANABLE_OBJS = ./dist/nes_iot.nes ./bin/nes_iot.prg  ./bin/nes_iot.chr ./obj/main.o

ASSEMBLER = ca65 # Damit wird unser Assemblercode in eine Objektdatei kompiliert
LINKER = ld65 # Dieser 'linkt' unsere Objektdateien in ein ROM
EMU = fceux # Legt den Emulator fest, mit dem wir unser ROM testen
#DEPLOYER = # Legt das Programm fest, um das ROM auf eine Karte zu �bertragen
CC = gcc # C-Compiler
CFLAGS = -Wall -ansi -pedantic -g -O0 # C-Compiler-Argumente
ASSFLAGS = # Argumente f�r den Assembler

################################################################################
# RULES                                                                        #
################################################################################

# 'Phony targets' sind Aktionen und keine Dateien und m�ssen daher immer
# ausgef�hrt werden

.PHONY: folders all run clean


all: clean folders dist/nes_iot.nes

folders:
	mkdir bin
	mkdir obj
	mkdir dist

run: all
	$(EMU) dist/nes_iot.nes

dist/nes_iot.nes: bin/nes_iot.prg bin/nes_iot.chr
	cat $^ > $@

bin/nes_iot.prg: ./NES_ROM_LAYOUT.link obj/main.o
	$(LINKER) -o bin/nes_iot.prg -C $^
 
bin/nes_iot.chr:
	cp res/nes_iot.chr bin/nes_iot.chr

# kompiliert die Quelldatei
obj/main.o: src/main.asm src/nes.inc
	cd src && $(ASSEMBLER) $(ASSFLAGS) main.asm -o ../obj/main.o && cd ..

clean:
	-rm $(CLEANABLE_OBJS)
	-rm -r bin
	-rm -r obj
	-rm -r dist
