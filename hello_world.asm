;;; -*- tab-width: 2; comment-column: 32; -*-

;;; These four lines go at the beginning of almost every code file. 16-byte iNES header

  .inesprg 1                    ; one bank of program code
  .ineschr 1                    ; one bank of picture data
  .inesmap 0                    ; we use mapper 0
  .inesmir 1                    ; Mirror setting always 1

;;; VARIABLES
  .rsset $0000

buttons1 .rs 1                  ; reserve 1 byte of space

;;; BANKING
;;; NESASM arranges everything in 8KB code and 8KB graphics banks. For each bank you have to tell the assembler where in memory it will start

  ;; We use Bank 0 to hold our code and start it at location $C000

  .bank 0                       ; bank 0
  .org $C000                    ; starts at location $C000

  ;; program's code goes here
RESET:
  SEI                           ; disable IRQs
  CLD                           ; disable decimal mode

  ;; PALETTES
  ;; Before putting any graphics on the screen, you first need to set the color palette.
  ;; There are two color palettes, each 16 bytes. One is used for the background and one is used for sprites.
  ;; The byte in the palette corresponds to one of the 64 base colors the NES can display. $0D is a bad color and should not be used (?)
  ;;
  ;; Palettes start at PPU address $3F00 and $3F10. To set this address, PPU address port $2006 is used.
  ;; The port must be written twice, once for the high byte then for the low byte.
  ;;
  ;; This code tells the PPU to set its address to $3F10. Then the PPU data port at $2007 is ready to accept data. The first write will go to the
  ;; address you set ($3F10), then the PPU will automatically increment the address after each read or write.
LoadPalettes:
  LDA $2002                     ; read PPU status to reset the high/low latch to high
  LDA #$3F
  STA $2006                     ; write the high byte of $3F10 address
  LDA #$00
  STA $2006                     ; write the low byte of $3F10 address

  ;; Load the palette data
  LDX #$00
LoadPalettesLoop:
  LDA PaletteData, x            ; load data from address (PaletteData + value in x)
  STA $2007                     ; write to PPU
  INX                           ; (inc X)
  CPX #$20                      ; Compare X to $20 (decimal 32)
  BNE LoadPalettesLoop          ; (when (not= x 32) (recur))

  ;; SPRITES
  ;;
  ;; Anything that moves separately from the background will be made of sprites. A sprite is an 8x8 pixel tile that the PPU renders anywhere on the screen.
  ;; Generally, objects are made from multiple sprites next to each other.
  ;; The PPU has enough internal memory for 64 sprites. The memory is separate from all other video memory and cannot be expanded.
  ;; SPRITE DATA
  ;; Each sprite needs 4 bytes of data for its position and tile information in this order:
  ;;
  ;; 0 | Y Position  | $00 = top of screen, $EF = bottom of screen
  ;; 1 | Tile Number | 0 - 256, tile number for the graphic to be taken from the pattern table.
  ;; 2 | Attributes  | Holds color and display info:
  ;;                   76543210
  ;;                   |||   ||
  ;;                   |||   ++- Color Palette of sprite.  Choose which set of 4 from the 16 colors to use
  ;;                   |||
  ;;                   ||+------ Priority (0: in front of background; 1: behind background)
  ;;                   |+------- Flip sprite horizontally
  ;;                   +-------- Flip sprite vertically
  ;; 3 | X Position  | $00 = left, $F9 = right
  ;;
  ;; These 4 bytes repeat 64 times (one set per sprite) to fill the 256 bytes of sprite memory. To edit sprite 0, change bytes $0200-0203, Sprite 1 is $0204-0207, etc.

  ;; TURING SPRITES ON
  ;; The PPU port $2001 is used again to enable sprites. Setting bit 4 to 1 will make them appear.
  ;; NMI also needs to be turned on, so the Sprite DMA will run and the sprites will be copied every frame. This is done with the PPU port $2000.
  ;; The Pattern Table 0 is also selected to choose sprites from. Background will come from Pattern Table 1 when that is added later.

LoadSprites:
  LDX #$00                      ; start at 0
LoadSpritesLoop:
  LDA SpriteData, x             ; load data from address sprites[x]
  STA $0200, x                  ; store into RAM address ($0200 + x)
  INX
  CPX #$10                      ; compare x to $10 (decimal 16)
  BNE LoadSpritesLoop

  ;; PPU Control ($2000)
  ;;  PPUCTRL ($2000)
  ;;  76543210
  ;;  | ||||||
  ;;  | ||||++- Base nametable address
  ;;  | ||||    (0 = $2000; 1 = $2400; 2 = $2800; 3 = $2C00)
  ;;  | |||+--- VRAM address increment per CPU read/write of PPUDATA
  ;;  | |||     (0: increment by 1, going across; 1: increment by 32, going down)
  ;;  | ||+---- Sprite pattern table address for 8x8 sprites (0: $0000; 1: $1000)
  ;;  | |+----- Background pattern table address (0: $0000; 1: $1000)
  ;;  | +------ Sprite size (0: 8x8; 1: 8x16)
  ;;  |
  ;;  +-------- Generate an NMI at the start of the
  ;;            vertical blanking interval vblank (0: off; 1: on)

  LDA #%10000000                 ; enable NMI, sprites from pattern table 0
  STA $2000

    ;; Set up the PPU
  ;; PPUMASK ($2001)
  ;;
  ;; 76543210
  ;; ||||||||
  ;; |||||||+- Grayscale (0: normal color; 1: AND all palette entries
  ;; |||||||   with 0x30, effectively producing a monochrome display;
  ;; |||||||   note that colour emphasis STILL works when this is on!)
  ;; ||||||+-- Disable background clipping in leftmost 8 pixels of screen
  ;; |||||+--- Disable sprite clipping in leftmost 8 pixels of screen
  ;; ||||+---- Enable background rendering
  ;; |||+----- Enable sprite rendering
  ;; ||+------ Intensify reds (and darken other colors)
  ;; |+------- Intensify greens (and darken other colors)
  ;; +-------- Intensify blues (and darken other colors)
  LDA #%00010000                ; enable sprites
  STA $2001

Forever:
  JMP Forever



  ;; x = memory location of sprite, offset from $0200
  ;; y = number of tiles in sprite
DecrementSpritePosition:
  LDY #$04
DecrementSpriteLoop:
  DEC $0200, x                  ; $0200[x]--
  TXA                           ; x += 4
  CLC
  ADC #$04
  TAX
  DEY                           ; y--
  BNE DecrementSpriteLoop       ; while (y != 0)
FinishDecrementSpriteLoop:
  RTS


IncrementSpritePosition:
  LDY #$04
IncrementSpriteLoop:
  INC $0200, x                  ; $0200[x]++
  TXA                           ; x += 4
  CLC
  ADC #$04
  TAX
  DEY                           ; y--
  BNE IncrementSpriteLoop       ; while (y != 0)
FinishIncrementSpriteLoop:
  RTS


  ;; Subroutine to load state of controller 1 into buttons1
  ;; after this routine the bits in buttons1 will be:
  ;;  7   6       5      4   3     2     1      0
  ;;  A   B  select  start  up  down  left  right
ReadController1:
  ;; The controllers are accessed through memory locations $4016 and $4017. First you have to write $01 and then $00 to $4016.
  ;; This tells the controllers to latch the current button positions. Then you read from $4016 for first player or $4017 for second player.
  ;; The buttons are sent one at a time, in bit 0.
  ;; Button status for each controller is returned in the following order: A, B, Select, Start, Up, Down, Left, Right
LatchControllers:
  LDA #$01
  STA $4016
  LDA #$00
  STA $4016

  LDX #$08
ReadControllerLoop:
  LDA $4016
  LSR A                         ; bit0 -> Carry
  ROL buttons1                  ; bit0 <- Carry
  DEX
  BNE ReadControllerLoop
  RTS


FlipSprite:
  LDX $0201
  LDY $0205
  STY $0201
  STX $0205
  LDX $0209
  LDY $020D
  STY $0209
  STX $020D
  RTS


NMI:
  ;; SPRITE DMA
  ;; The fastest and easiest way to transfer your sprites to memory is using DMA (Direct Memory Access). This just means a block of RAM is copied from CPU memory
  ;; to the PPU sprite memory. The on-board RAM space from $0200-02FF is usually used for this purpose. To start the transfer, two bytes need to be written to the PPU ports
  ;; Like all graphics updates, this needs to be done at the beginning of the VBlank period, so it will go in the NMI section of the code:
  LDA #$00
  STA $2003                     ; set the low byte (00) of the RAM address
  LDA #$02
  STA $4014                     ; set the high byte (02) of the RAM address, start the transfer


HandleButtons:
  JSR ReadController1

HandlePlayer1Up:
  LDA buttons1
  AND #%1000
  BEQ HandlePlayer1Down
OnPlayer1Up:
  LDX #$00
  JSR DecrementSpritePosition

HandlePlayer1Down:
  LDA buttons1
  AND #%0100
  BEQ HandlePlayer1Left
OnPlayer1Down:
  LDX #$00
  JSR IncrementSpritePosition

HandlePlayer1Left:
  LDA buttons1
  AND #%0010
  BEQ HandlePlayer1Right
OnPlayer1Left:
  ;; Move to the left
  LDX #$03
  JSR DecrementSpritePosition

  ;; Check and see if sprite is already flipped, if not, flip it
  LDA $0202
  AND #%01000000
  BNE HandlePlayer1Right

  ;; Flip the sprite
  LDA #%01000000
  STA $0202
  STA $0206
  STA $020A
  STA $020E
  JSR FlipSprite


HandlePlayer1Right:
  LDA buttons1
  AND #%0001
  BEQ FinishHandleButtons
OnPlayer1Right:
  LDX #$03
  JSR IncrementSpritePosition

  LDA $0202
  AND #%01000000
  BEQ FinishHandleButtons

  LDA #$0
  STA $0202
  STA $0206
  STA $020A
  STA $020E
  JSR FlipSprite

FinishHandleButtons:
  RTI                           ; Return from interrupt


;;; BANK 1 & 3 AND INTERRUPT VECTORS
  .bank 1                       ; change to bank 1
  .org $E000                    ; start at $E000

PaletteData:
  .db $0F,$31,$32,$33,$0F,$35,$36,$37,$0F,$39,$3A,$3B,$0F,$3D,$3E,$0F  ;background palette data
  .db $0F,$1C,$15,$14,$0F,$02,$38,$3C,$0F,$1C,$15,$14,$0F,$02,$38,$3C  ;sprite palette data

SpriteData:
  ;;  vert tile attr horiz
  .db $80, $32, $00, $80        ; sprite 0
  .db $80, $33, $00, $88        ; sprite 1
  .db $88, $34, $00, $80        ; sprite 2
  .db $88, $35, $00, $88        ; sprite 3

InterruptVectors:
  ;; There are 3 times when the NES processor will interrupt your code and jump to a new location. These vectors, held in PRG ROM tell the processor
  ;; where to go when that happens.
  .org $FFFA
  ;; NMI Vector: happens once per frame when enabled. The PPU tells the processor it is starting the VBlank time and is available for graphics updates
  .dw NMI                        ; location of NMI Interrupt
  ;; RESET Vector: happens every time the NES starts up, or the reset button is pressed.
  .dw RESET                     ; code to run at reset, we give address of Start lable that we will eventually put in bank 0
  ;; IRQ Vector: Triggered from some mapper chips or audio interrupts
  .dw 0                         ; location of external IRQ interrupt.

;;; BANK 2 AND OUR PICTURE DATA
  ;; Bank 2 will be starting at $0000 and in it we will include our picture data for backgrounds and sprites

  .bank 2                       ; Change to bank 2
  .org $0000                    ; start at $0000
  .incbin "mario.chr"           ; INClude BINary. 8KB graphics file from SMB1
