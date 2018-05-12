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

                    ;


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

  lda #0                ; disable scrolling
  sta PPUSCROLL         ; disable vertical
  sta PPUSCROLL         ; disable horizontal

  lda #BG_1000|OBJ_1000 ; set Pattern table and set address for sprites (OBJ_1000 is declared in nes.inc)
  sta PPUCTRL           ; send to PPUCTRL

  lda #BG_ON|OBJ_ON     ; turn on drawing for background and sprites (screen was turned of)
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

; init color palette

  lda #$3F        ; address for background palette
  sta PPUADDR
  lda #$00        
  sta PPUADDR



  ldx #8      ; init loop index on register X=8
:
  
  lda #$0F
  sta PPUDATA

  sta PPUDATA
  sta PPUDATA

  lda #$30
  sta PPUDATA
  
  dex         ; decrement loop index (register x) by 1
  bne :-      ; if loop index  > 0, jump to :

  lda #>firstLineText
  sta $01

  lda #<firstLineText
  sta $00

  lda #$20
  sta $03
  lda #$82
  sta $02

  jsr print_menue
 
  rts
.ENDPROC

.PROC print_menue 
dstLo = $02
dstHi = $03 
src = $00 

  lda dstHi
  sta PPUADDR
  lda dstLo
  sta PPUADDR

  ldy #0
loop:
  lda (src),y
  beq done
  
  iny
  bne :+

  inc src+1

: 
  cmp #10
  beq newline

  sta PPUDATA 

  bne loop

newline: 

  lda #32 

  clc 

  adc dstLo
  sta dstLo 

  lda #0 

  adc dstHi
  sta dstHi 
  sta PPUADDR
  lda dstLo
  sta PPUADDR
  
  jmp loop 
done:
  rts 
.ENDPROC

.SEGMENT "DATA"

firstLineText:
  .BYT "first",$20,"line",0
