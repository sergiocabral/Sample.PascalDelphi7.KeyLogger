object MyForm: TMyForm
  Left = 929
  Top = 518
  Width = 547
  Height = 376
  Caption = 'Hook Example'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  DesignSize = (
    531
    337)
  PixelsPerInch = 96
  TextHeight = 13
  object btnStartHook: TButton
    Left = 16
    Top = 16
    Width = 121
    Height = 25
    Caption = 'DLL -> StartHook'
    TabOrder = 0
    OnClick = btnStartHookClick
  end
  object btnStopHook: TButton
    Left = 152
    Top = 15
    Width = 121
    Height = 25
    Caption = 'DLL -> StopHook'
    TabOrder = 1
    OnClick = btnStopHookClick
  end
  object txtCapure: TMemo
    Left = 16
    Top = 55
    Width = 497
    Height = 266
    Anchors = [akLeft, akTop, akRight, akBottom]
    ReadOnly = True
    TabOrder = 2
  end
end
