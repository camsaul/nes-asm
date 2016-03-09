;;; -*- tab-width: 2; -*-

;;; RenderText(row, column, stringAddress)
RenderText .macro
  Funcall4 _RenderText, \1, \2, #low(\3), #high(\3)
  .endm

_RenderText:
  LDX arg2
  LDY arg1
  LDA #$20
  STA PPU_MEMORY_ADDR
  LDA #$00                      ; address = $2000
SelectRow:                      ; address += (y * $20)
  CPY #$00
  BEQ SelectColumn
  CLC
  ADC #$20
  DEY
  JMP SelectRow
SelectColumn:                   ; address += x
  CPX #$00
  BEQ FinishSelectColumn
  CLC
  ADC #$01
  DEX
  JMP SelectColumn
FinishSelectColumn:
  STA PPU_MEMORY_ADDR           ; store address
  LDY #$00
RenderTextLoop:
  LDA [arg3], y
  CMP #$FF
  BEQ FinishRenderText
  STA PPU_DATA
  INY
  JMP RenderTextLoop
FinishRenderText:
  RTS


;;; ReadController(portAddressLow, portAddressHigh, destAddressLow, destAddressHigh)
ReadController:
  LDX #$08
ReadControllerLoop:
  LDA (arg1)
  LSR A
  ROL (arg3)
  DEX
  BNE ReadControllerLoop
  RTS


ReadControllers:
  ;; Strobe the controllers
  Put #$01, CONTROLLER_1
  Put #$00, CONTROLLER_1

  ;; ReadController(#CONTROLLER_1, #$controller1)
  Funcall4 ReadController, #$40, #$16, #low(controller1), #high(controller1)

  RTS


ResetPPUAddress:
  LDA #$00
  STA PPU_MEMORY_ADDR
  STA PPU_MEMORY_ADDR
  RTS
