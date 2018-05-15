; NES-IOT is a nerdy project to control a modern IoT device with an old school NES
; due to sending commands to and receiving events from the connctd plattform (www.connctd.io)

.INCLUDE "nes.inc"  ; for having names for the NES Addresses and Commands

.GLOBALZP nmis      ; (GLOBAL) variables in (Z)ero(P)age for fast access

.P02                ; setting freaking mode I do not understand

.SEGMENT "ZEROPAGE" ; declare what should be in ZeroPage (256 Bytes available)

nmis: .RES 1        ; reserve 1 byte for nmis

.SEGMENT "INES_HEADER"  ; iNES header

  .BYT "NES", $1A       ; NES init string
  .BYT 1                ; 1 PRG
  .BYT 1                ; 1 CHR
  .BYT %00000001        ; just copied that. Is about mirroring, trainer enabled, etc...
  .BYT %00000000        ; No Mapper and no Mapper configuration

.SEGMENT "VECTORS"
  .ADDR nmi, reset, irq

.SEGMENT "CODE"

.PROC irq           ; software interrupt
  rti               ; do nothing and (R)e(T)urn from (I)nterrupt
.ENDPROC

.PROC nmi           ; (N)on (M)askable (I)nterrupt -> PPU is in V-BLANK
  inc nmis          ; increment nmis by 1, value is not important, use value change as indicator for V-BLANK
  rti               ; (R)e(T)urn from (I)nterrupt
.ENDPROC

.PROC reset         ; Start or Reset of NES

  sei               ; ignore future interrupts by setting I-Flag in P-Register to 0
  cld               ; turn of BCD mode -> binary mode only

  ldx #0            ; just load a zero to register x
  stx PPUCTRL       ; turn of NMI until init is complete
  stx PPUMASK       ; set PPUMASK to zero -> turn of Screen

                    ; prepare stack init
                    ; set stack pointer to last position
  ldx #$FF          ; load $FF to register X
  txs               ; transfer register X content ($FF) to stack pointer

  bit PPUSTATUS     ; reading 7th bit of PPU status will set 7th bit to 1 (just to be safe)

vwait1:             ; loop for waiting for first VBLANK of PPU

  bit PPUSTATUS     ; read PPU state
  bpl vwait1        ; (B)ranch on (PL)us -> jump to vwait1 when n-flag of P-Register is 0

  ; OK, PPU was at least 1 time in VBLANK

  ldy #0            ; prepare zero page clear
  ldx #$00          ; prepare zero page clear


clear_zp:           ; clear the ZeroPage
  sty $00,x         ; copy content of register x to register y
  inx               ; increment register x
  bne clear_zp      ; (B)ranch on (N)ot (E)quals -> register x is lower than $FF -> jump to clear_zp
  
vwait2:             ; wait for second VBLANK
  bit PPUSTATUS
  bpl vwait2


; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;                     PROGRAM START
; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

start:
  jsr draw_main_menue   ; Draw the main menue

  lda #VBLANK_NMI       ; NMI was turned of for init, turn on again -> load command to register a
  sta PPUCTRL           ; store content of register a to PPUCTRL

  lda nmis              ; load nmis (will be incremented by each NMI)
:
  cmp nmis              ; (C)o(MP)are with accumulator (register A)
  beq :-                ; jump to : when no VBLANK

                        ; good, PPU is in VBLANK

  lda #0
  sta PPUSCROLL         ; disable vertical scrolling
  sta PPUSCROLL         ; disable horizontal scrolling

  lda #BG_1000|OBJ_1000 ; set pattern table and set address for sprites (OBJ_1000 is declared in nes.inc)
  sta PPUCTRL           ; send to PPUCTRL

  lda #BG_ON|OBJ_ON     ; turn on drawing for background and sprites (screen was turned off in reset:)
  sta PPUMASK

loop:                   ; main loop
  jmp loop              ; nothing to do right now -> content of program will be placed here

.ENDPROC 

.PROC clear_screen
  lda #$20
  ldx #$00

  sta PPUADDR
  stx PPUADDR

  ldx #240

:
  lda #64
  sta PPUDATA
  sta PPUDATA
  sta PPUDATA
  sta PPUDATA

  dex
  bne :-
  ldx #64
  lda #0

:
  sta PPUDATA
  dex
  bne :-

  rts
.ENDPROC

.PROC draw_main_menue

  jsr clear_screen    ; clear the screen

; init color palette ($3F00-$3F1F) with colors

  lda #$3F          ; set high-byte of PPUADDR to color palette
  sta PPUADDR
  lda #$00          ; set low-byte of PPUADDR to color palette
  sta PPUADDR

  ldx #8            ; init a loop of 8, palette has 32 colors, every 4th color will be white, the rest will be black (32/4 = 8)
:

  lda #$0F          ; load $0F (BLACK see color palette for NES)
  sta PPUDATA       ; set first color BLACK
  lda #$03
  sta PPUDATA       ; set second color BLACK (not needed)
  lda #$17
  sta PPUDATA       ; set thrid color BLACK (not needed)
  lda #$30          ; load color $30 (white)
  sta PPUDATA       ; set 4th color to WHITE

  dex               ; decrement loop index (register x) by 1
  bne :-            ; if loop index  > 0, jump to :

; all right, color palette is set

  lda #>firstLineText           ; Load High-Byte of line and store to address $01
  sta $01

  lda #<firstLineText           ; Load Low-Byte of line and store to address $00
  sta $00



  lda #$21                      ; prepare drawing position $2082
  sta $03                       ; store High-Byte to $03
  lda #$68
  sta $02                       ; store Low-Byte to $02

  jsr print_menue               ; jump to print_menue

  rts
.ENDPROC

.PROC print_menue

dstLo = $02                     ; load Low-Byte of drawing position
dstHi = $03                     ; load High-Byte of drawing position
src = $00                       ; load Low-Byte of text source

  lda dstHi
  sta PPUADDR                   ; set High-Byte to PPUADDR
  lda dstLo
  sta PPUADDR                   ; set Low-Byte to PPUADDR

    lda #0
    sta PPUDATA

  ldy #0

loop:                           ; loop will draw tile for each character to PPUDATA
  lda (src),y                   ; load (character on position y
  beq done                      ; if no character, drawing is complete

  iny                           ; increment register y
  bne :+                        ; jump to : when next inc y was not 0

  inc src+1                     ; increment source address by 1 (in case it's larger than 255) and store result in accumlator (register a)

:
  cmp #50                      ; compare 10 with register a (accumulator) -> is it a new line charactor?
  beq newline                   ; new line -> jump to newline
;  cmp #32                      ; compare 10 with register a (accumulator) -> is it a new line charactor?
;  beq newline                   ; new line -> jump to newline
  sta PPUDATA                   ; store charactor -> tile address = character number

  bne loop                      ; and back again to loop:

newline:



  lda #32                       ; load 32 to accumulator -> width of a screen row

  clc                           ; (CL)ear (C)arry bit

  adc dstLo                     ; add value of dstLo to current accumlator value (32)
  sta dstLo                     ; set new low-Byte value

  lda #0                        ; set accumulator to 0

  adc dstHi                     ; add 0 to current High-Byte
  sta dstHi                     ; set new High-Byte
  sta PPUADDR                   ; set HighByte of PPUADDR
  lda dstLo
  sta PPUADDR                   ; set Low-Byte of PPUADDR

  jmp loop                      ; well done, new line inserted -> jump to loop:
done:
  rts                           ; (R)e(T)urn from (S)ubroutine
.ENDPROC

.SEGMENT "DATA"

firstLineText:
  .BYT 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,50,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,50,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,0

themap:
  .INCBIN "test.map"