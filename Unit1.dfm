object Form1: TForm1
  Left = 195
  Top = 124
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'PodCast Easy'
  ClientHeight = 166
  ClientWidth = 293
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Button1: TButton
    Left = 7
    Top = 6
    Width = 75
    Height = 25
    Caption = #1054#1073#1085#1086#1074#1080#1090#1100
    TabOrder = 0
    OnClick = Button1Click
  end
  object Memo1: TMemo
    Left = 7
    Top = 53
    Width = 281
    Height = 89
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    ScrollBars = ssBoth
    TabOrder = 1
  end
  object StatusBar1: TStatusBar
    Left = 0
    Top = 147
    Width = 293
    Height = 19
    Panels = <>
    SimplePanel = True
    OnClick = StatusBar1Click
  end
  object CheckBox1: TCheckBox
    Left = 8
    Top = 33
    Width = 128
    Height = 17
    Caption = #1047#1072#1075#1088#1091#1079#1080#1090#1100' '#1087#1086#1076#1082#1072#1089#1090#1099
    Checked = True
    State = cbChecked
    TabOrder = 3
  end
  object Button3: TButton
    Left = 86
    Top = 6
    Width = 75
    Height = 25
    Caption = #1047#1072#1075#1088#1091#1079#1082#1080
    TabOrder = 4
    OnClick = Button3Click
  end
  object ProgressBar1: TProgressBar
    Left = 7
    Top = 60
    Width = 281
    Height = 44
    TabOrder = 5
    Visible = False
  end
  object XPManifest1: TXPManifest
    Left = 16
    Top = 64
  end
  object Timer1: TTimer
    Enabled = False
    Interval = 100
    OnTimer = Timer1Timer
    Left = 48
    Top = 64
  end
end
