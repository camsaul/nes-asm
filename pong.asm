;;; ; -*- tab-width: 2; -*-

  .include "macros.asm"

;;; iNES HEADER

  .inesprg 1
  .ineschr 1
  .inesmap 0
  .inesmir 1

;;; VARIABLES

  .include "variables.asm"

;;; CODE

  .bank 0
  .org $C000

  .include "subroutines.asm"

  .include "reset.asm"
  .include "nmi.asm"

  .bank 1
  .org $E000

;;; DATA

paletteData:
  .db $0F,$31,$32,$33,$0F,$35,$36,$37, $0F,$39,$3A,$3B,$0F,$3D,$3E,$0F  ; background palette data
  .db $0F,$1C,$15,$14,$0F,$02,$38,$3C, $0F,$1C,$15,$14,$0F,$02,$38,$3C  ; sprite palette data

player1ScoreTitle:
  .db $19, $15, $0A, $22, $0E, $1B, $24, $01, $FF
player2ScoreTitle:
  .db $19, $15, $0A, $22, $0E, $1B, $24, $02, $FF

;;; INTERRUPT VECTORS

  .org $FFFA
  .dw NMI
  .dw RESET
  .dw 0                         ; Location of IRQ interrupt

;;; CHR DATA

  .bank 2
  .org $0000
  .incbin "mario.chr"
