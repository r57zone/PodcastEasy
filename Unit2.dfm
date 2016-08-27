object Settings: TSettings
  Left = 192
  Top = 124
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = #1053#1072#1089#1090#1088#1086#1081#1082#1080
  ClientHeight = 316
  ClientWidth = 296
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object OkBtn: TButton
    Left = 8
    Top = 283
    Width = 75
    Height = 25
    Caption = #1054#1082
    TabOrder = 0
    OnClick = OkBtnClick
  end
  object CancelBtn: TButton
    Left = 88
    Top = 283
    Width = 75
    Height = 25
    Caption = #1054#1090#1084#1077#1085#1072
    TabOrder = 1
    OnClick = CancelBtnClick
  end
  object GroupBox1: TGroupBox
    Left = 8
    Top = 216
    Width = 281
    Height = 60
    Caption = 'OPML '
    TabOrder = 2
    object ImportBtn: TButton
      Left = 6
      Top = 24
      Width = 75
      Height = 25
      Caption = #1048#1084#1087#1086#1088#1090
      TabOrder = 0
      OnClick = ImportBtnClick
    end
    object ExportBtn: TButton
      Left = 86
      Top = 24
      Width = 75
      Height = 25
      Caption = #1069#1082#1089#1087#1086#1088#1090
      TabOrder = 1
      OnClick = ExportBtnClick
    end
  end
  object GeneralGroupBox: TGroupBox
    Left = 8
    Top = 8
    Width = 281
    Height = 202
    Caption = #1054#1073#1097#1080#1077' '
    TabOrder = 3
    object Label1: TLabel
      Left = 8
      Top = 24
      Width = 87
      Height = 13
      Caption = #1071#1079#1099#1082#1086#1074#1086#1081' '#1092#1072#1081#1083' :'
    end
    object Label2: TLabel
      Left = 8
      Top = 72
      Width = 153
      Height = 13
      Caption = #1055#1091#1090#1100' '#1076#1083#1103' '#1079#1072#1075#1088#1091#1079#1082#1080' '#1087#1086#1076#1082#1072#1089#1090#1086#1074':'
    end
    object Label3: TLabel
      Left = 8
      Top = 148
      Width = 168
      Height = 13
      Caption = #1057#1087#1080#1089#1086#1082' '#1089#1086#1093#1088#1072#1085#1085#1077#1085#1085#1099#1093' '#1087#1086#1076#1082#1072#1089#1090#1086#1074
    end
    object EditPath: TEdit
      Left = 7
      Top = 88
      Width = 186
      Height = 21
      ReadOnly = True
      TabOrder = 0
    end
    object ChooseBtn: TButton
      Left = 198
      Top = 88
      Width = 75
      Height = 21
      Caption = #1042#1099#1073#1088#1072#1090#1100
      TabOrder = 1
      OnClick = ChooseBtnClick
    end
    object DownloadPodcastsChk: TCheckBox
      Left = 8
      Top = 120
      Width = 128
      Height = 17
      Caption = #1047#1072#1075#1088#1091#1078#1072#1090#1100' '#1087#1086#1076#1082#1072#1089#1090#1099
      Checked = True
      State = cbChecked
      TabOrder = 2
    end
    object LanguageCB: TComboBox
      Left = 8
      Top = 40
      Width = 145
      Height = 21
      Style = csDropDownList
      ItemHeight = 13
      TabOrder = 3
      OnChange = LanguageCBChange
    end
    object DeleteOldBtn: TButton
      Left = 8
      Top = 167
      Width = 97
      Height = 25
      Caption = #1059#1076#1072#1083#1080#1090#1100' '#1089#1090#1072#1088#1099#1077
      TabOrder = 4
      OnClick = DeleteOldBtnClick
    end
  end
  object OpenDialog: TOpenDialog
    Filter = 'OPML '#1092#1072#1081#1083#1099'|*.opml'
    Left = 144
    Top = 8
  end
  object SaveDialog: TSaveDialog
    DefaultExt = 'OPML '#1092#1072#1081#1083#1099'|*.opml'
    Filter = 'OPML '#1092#1072#1081#1083#1099'|*.opml'
    Left = 176
    Top = 8
  end
end
