object Form1: TForm1
  Left = 541
  Top = 471
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'Key-Logger V1.0 par Nono40'
  ClientHeight = 29
  ClientWidth = 261
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  WindowState = wsMinimized
  PixelsPerInch = 96
  TextHeight = 13
  object Timer1: TTimer
    Interval = 100
    OnTimer = Timer1Timer
  end
end
