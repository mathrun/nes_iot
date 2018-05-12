################################################################################
# VARIABLEN                                                                    #
################################################################################

# Dateien, die durch ein 'clean' gel�scht werden sollen
CLEANABLE_OBJS = ./dist/nes_iot.nes ./tools/chr2asciiart ./tools/asciiart2chr \
  ./bin/nes_iot.prg ./bin/pattern_table_1.chr ./bin/pattern_table_2.chr ./bin/nes_iot.chr \
  ./obj/main.o

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

.PHONY: all run clean tools deploy

# Standard-Target wird automatisch bei einem 'make' ausgef�hrt
all: tools dist/nes_iot.nes

# startet das erstellte ROM im Emulator
run: all
	$(EMU) dist/nes_iot.nes
  
#deploy: all
#	$(DEPLOYER) dist/nes_iot.nes

# erstellt ausf�hrbare Hilfs-Programme
tools: tools/chr2asciiart tools/asciiart2chr

# erstellt ausf�hrbares Hilfs-Programm 'chr2asciiart'
tools/chr2asciiart: tools/chr2asciiart.c
	$(CC) $(CFLAGS) $< -o $@

# erstellt ausf�hrbares Hilfs-Programm 'asciiart2chr'
tools/asciiart2chr: tools/asciiart2chr.c
	$(CC) $(CFLAGS) $< -o $@

# erzeugt das eigentliche ROM
dist/nes_iot.nes: bin/nes_iot.prg bin/nes_iot.chr
	cat $^ > $@
 
# erstellt den .text-Bereich des ROMs
bin/nes_iot.prg: ./NES_ROM_LAYOUT.link obj/main.o
	$(LINKER) -o bin/nes_iot.prg -C $^
 
# kompiliert die Quelldatei
obj/main.o: src/main.asm src/nes.inc
	cd src && $(ASSEMBLER) $(ASSFLAGS) main.asm -o ../obj/main.o && cd ..

# f�gt beide Pattern Tables zusammen
bin/nes_iot.chr: bin/pattern_table_1.chr bin/pattern_table_2.chr
	cat $^ > $@
  
# wandelt die ASCII-Tabelle in ein CHR-ROM um
bin/pattern_table_1.chr: res/pattern_table_1.txt
	tools/asciiart2chr $< $@

# wandelt die ASCII-Tabelle in ein CHR-ROM um
bin/pattern_table_2.chr: res/pattern_table_2.txt
	tools/asciiart2chr $< $@

# l�scht alle (durch dieses Makefile) erzeugten Dateien
clean:
	-rm $(CLEANABLE_OBJS)
