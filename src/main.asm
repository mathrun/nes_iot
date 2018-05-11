; NES-IOT is a nerdy project to controll a modern IoT device with an old school NES
; due to sending commands to the connctd plattform (www.connctd.io)

.INCLUDE "nes.inc"

.GLOBALZP nmis      ; (GLOBAL) variables in (Z)ero(P)age for fast access

.P02

.SEGMENT "ZEROPAGE"

nmis: .RES 1        ; reserve 1 byte for nmis

.SEGMENT "INES_HEADER"  

  .BYT "NES", $1A
  .BYT 1
  .BYT 1
  .BYT %00000001 
  .BYT %00000000

.SEGMENT "VECTORS"
  .ADDR nmi, reset, irq

.SEGMENT "CODE"

.PROC irq
  rti               ; do nothing and (R)e(T)urn from (I)nterrupt
.ENDPROC

.PROC nmi
  inc nmis          ; increment nmis by 1, value is not important, use value change as indicator for V-BLANK
  rti               ; (R)e(T)urn from (I)nterrupt
.ENDPROC

.PROC reset
  
  sei             
  cld           

  ldx #0
  stx PPUMASK   
    
  ldx #$FF       
  txs     

  bit PPUSTATUS    

vwait1:

  bit PPUSTATUS
  bpl vwait1

  ldy #0
  ldx #$00 ;


clear_zp:
  sty $00,x
  inx   
  bne clear_zp
  
vwait2:
  bit PPUSTATUS
  bpl vwait2


; ----------------------------------------------------------
;        PROGRAM START
; ----------------------------------------------------------

start:
  jsr draw_main_menue

  lda #VBLANK_NMI
  sta PPUCTRL

  lda nmis
:
  cmp nmis
  beq :-

  lda #0 
  sta PPUSCROLL
  sta PPUSCROLL

  lda #BG_1000|OBJ_1000
  sta PPUCTRL

  lda #BG_ON|OBJ_ON
  sta PPUMASK

loop:
  jmp loop

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
