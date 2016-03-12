;;; -*- tab-width: 2; -*-

  ;; OnController(controller, button, subrLow, subrHigh)
OnController:
  LDA arg1
  AND arg2
  BEQ FinishOnController
  JMP [arg3]
FinishOnController:
  RTS

HandlePlayer1Up:
  RTS

  ;; CreateScoreText(score, dest)
CreateScoreText .macro
  Funcall3 _CreateScoreText, \1, #low(\2), #high(\2)
  .endm
_CreateScoreText:
  LDX arg1
  ;; hundreds
  LDA controller1
  AND #CONTROLLER_LEFT
  BEQ OnPlayer1LeftDown
  JMP OnPlayer1LeftUp
OnPlayer1LeftDown:
  LDA #$02
  JMP Player1LeftDone
OnPlayer1LeftUp:
  LDA #$01
Player1LeftDone:
  STA [arg2], y

  ;; tens
  INY
  LDA #$0
  STA [arg2], y

  ;; ones
  INY
  LDA #$03
  STA [arg2], y

  ;; terminating $FF
  INY
  LDA #$FF
  STA [arg2], y

  RTS

NMI:
  ;; Rendering
  Put #$20, player1Score
  Put #$30, player2Score

  CreateScoreText player1Score, player1ScoreText
  CreateScoreText player2Score, player2ScoreText
  RenderText #$05, #$04, player1ScoreText
  RenderText #$05, #$1A, player2ScoreText

  ;; Game Engine
  JSR ReadControllers

  ;; Game logic goes here!

  JMP ResetPPUAddress
  RTI
