object Settings: TSettings
  Left = 192
  Top = 124
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = #1053#1072#1089#1090#1088#1086#1081#1082#1080
  ClientHeight = 162
  ClientWidth = 294
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  OnCreate = FormCreate
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 8
    Top = 8
    Width = 81
    Height = 13
    Caption = #1071#1079#1099#1082#1086#1074#1086#1081' '#1092#1072#1081#1083
  end
  object Label2: TLabel
    Left = 8
    Top = 56
    Width = 163
    Height = 13
    Caption = #1055#1091#1090#1100' '#1076#1083#1103' '#1089#1086#1093#1088#1072#1085#1077#1085#1080#1103' '#1087#1086#1076#1082#1072#1089#1090#1086#1074
  end
  object EditPath: TEdit
    Left = 8
    Top = 72
    Width = 202
    Height = 21
    ReadOnly = True
    TabOrder = 1
  end
  object ChooseBtn: TButton
    Left = 214
    Top = 72
    Width = 75
    Height = 21
    Caption = #1042#1099#1073#1088#1072#1090#1100
    TabOrder = 2
    OnClick = ChooseBtnClick
  end
  object DownloadPodcastsChk: TCheckBox
    Left = 8
    Top = 102
    Width = 128
    Height = 17
    Caption = #1047#1072#1075#1088#1091#1078#1072#1090#1100' '#1087#1086#1076#1082#1072#1089#1090#1099
    Checked = True
    State = cbChecked
    TabOrder = 3
  end
  object LanguageCB: TComboBox
    Left = 8
    Top = 24
    Width = 145
    Height = 21
    Style = csDropDownList
    ItemHeight = 13
    TabOrder = 0
    OnChange = LanguageCBChange
  end
  object OkBtn: TButton
    Left = 8
    Top = 131
    Width = 75
    Height = 25
    Caption = #1054#1082
    TabOrder = 4
    OnClick = OkBtnClick
  end
  object CancelBtn: TButton
    Left = 88
    Top = 131
    Width = 75
    Height = 25
    Caption = #1054#1090#1084#1077#1085#1072
    TabOrder = 5
    OnClick = CancelBtnClick
  end
end
