;;; -*- tab-width: 2; -*-

RESET:
  SEI                           ; disable IRQ interrups
  CLD                           ; disable decimal mode

  Put #$00, player1Score
  Put #$00, player2Score

;;   LDA #$00
;;   STA $2000
;;   BIT $2002
;; VBlankWait:
;;   BIT $2002
;;   BPL VBlankWait
;; VBlankWait2:
;;   BIT $2002
;;   BPL VBlankWait2

SetupPPU:
  Put #%10010000, PPU_CONTROL_1 ; enable NMI, background table address = $1000
  Put #%00011010, PPU_CONTROL_2 ; enable backgrounds & sprites

  Put #$00, PPU_SCROLL_OFFSET   ; tell PPU there is no background scrolling
  Put #$00, PPU_SCROLL_OFFSET

LoadPalettes:
  Put #$3F, PPU_MEMORY_ADDR     ; Set PPU to the start of the palette ($3F00). Write this address to the PPU one byte at a time
  Put #$00, PPU_MEMORY_ADDR

  LDX #$00
LoadPalettesLoop:
  LDA paletteData, x
  STA PPU_DATA                  ; write to PPU port PPU_DATA. to store palette in bytes starting at $3F00. Each write to PPU_DATA
  INX                           ; automatically increments destination, so next write is to $3F11, etc.
  CPX #$20
  BNE LoadPalettesLoop

;;   ;; Write Attribute Table bytes (64 bytes) starting at $23C0
;; WriteAttributeTable:
;;   LDA #$23
;;   STA PPU_MEMORY_ADDR
;;   LDA #$C0
;;   STA PPU_MEMORY_ADDR

;;   LDX #$00
;;   LDA #%10100101
;; WriteAttributeTableLoop:
;;   STA PPU_DATA
;;   INX
;;   CPX #$40
  ;;   BNE WriteAttributeTableLoop

ClearBackground:
  Put #$20, PPU_MEMORY_ADDR
  Put #$00, PPU_MEMORY_ADDR

  LDX #$00
  LDY #$00
  LDA #$24
ClearBackgroundLoop:
  STA PPU_DATA
  INX
  CPX #$32
  BNE ClearBackgroundLoop
  LDX #$00
  INY
  CPY #$30
  BNE ClearBackgroundLoop

RenderScoreTitles:
  RenderText #$03, #$01, player1ScoreTitle
  RenderText #$03, #$17, player2ScoreTitle

RenderSprites:
  Put #$80, SPRITE_0_Y
  Put #$32, SPRITE_0_TILE
  Put #$00, SPRITE_0_ATTR
  Put #$80, SPRITE_0_X

  JSR ResetPPUAddress

Forever:
  JMP Forever
