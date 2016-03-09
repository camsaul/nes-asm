;;; -*- tab-width: 2; -*-

Put .macro
  LDA \1
  STA \2
  .endm

Funcall1 .macro
  Put \2, arg1
  JSR \1
  .endm

Funcall2 .macro
  Put \3, arg2
  Funcall1 \1, \2
  .endm

Funcall3 .macro
  Put \4, arg3
  Funcall2 \1, \2, \3
  .endm

Funcall4 .macro
  Put \5, arg4
  Funcall3 \1, \2, \3, \4
  .endm

CONTROLLER_A      = %10000000
CONTROLLER_B      = %01000000
CONTROLLER_SELECT = %00100000
CONTROLLER_START  = %00010000
CONTROLLER_UP     = %00001000
CONTROLLER_DOWN   = %00000100
CONTROLLER_LEFT   = %00000010
CONTROLLER_RIGHT  = %00000001

SPRITE_0_Y        = $0200
SPRITE_0_TILE     = $0201
SPRITE_0_ATTR     = $0202
SPRITE_0_X        = $0203

PPU_CONTROL_1     = $2000
PPU_CONTROL_2     = $2001
PPU_STATUS        = $2002
PPU_SCROLL_OFFSET = $2005
PPU_MEMORY_ADDR   = $2006
PPU_DATA          = $2007

CONTROLLER_1      = $4016
CONTROLLER_2      = $4017
