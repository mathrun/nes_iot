################################################################################
# VARIABLES                                                                    #
################################################################################

CLEANABLE_FOLDERS = ./bin ./obj ./dist
ASSEMBLER = ca65
LINKER = ld65
EMU = wine ../fceux-win/fceux.exe
ASSFLAGS =

################################################################################
# RULES                                                                        #
################################################################################

.PHONY: folders all run clean

all: clean folders dist/nes_iot.nes

folders:
	-mkdir $(CLEANABLE_FOLDERS)

run: all
	$(EMU) dist/nes_iot.nes

dist/nes_iot.nes: bin/nes_iot.prg bin/nes_iot.chr
	cat $^ > $@

bin/nes_iot.prg: ./NES_ROM_LAYOUT.link obj/main.o
	$(LINKER) -o bin/nes_iot.prg -C $^
 
bin/nes_iot.chr:
	cp res/nes_iot.chr bin/nes_iot.chr

obj/main.o: src/main.asm src/nes.inc
	cd src && $(ASSEMBLER) $(ASSFLAGS) main.asm -o ../obj/main.o && cd ..

clean:
	-rm -r $(CLEANABLE_FOLDERS)
