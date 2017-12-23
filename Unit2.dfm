object Settings: TSettings
  Left = 192
  Top = 124
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = #1053#1072#1089#1090#1088#1086#1081#1082#1080
  ClientHeight = 301
  ClientWidth = 376
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object OkBtn: TButton
    Left = 8
    Top = 267
    Width = 75
    Height = 25
    Caption = #1054#1082
    TabOrder = 3
    OnClick = OkBtnClick
  end
  object CancelBtn: TButton
    Left = 88
    Top = 267
    Width = 75
    Height = 25
    Caption = #1054#1090#1084#1077#1085#1072
    TabOrder = 4
    OnClick = CancelBtnClick
  end
  object OPMLGB: TGroupBox
    Left = 280
    Top = 8
    Width = 89
    Height = 145
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
      Left = 6
      Top = 56
      Width = 75
      Height = 25
      Caption = #1069#1082#1089#1087#1086#1088#1090
      TabOrder = 1
      OnClick = ExportBtnClick
    end
  end
  object CommonGB: TGroupBox
    Left = 8
    Top = 8
    Width = 265
    Height = 145
    Caption = #1054#1073#1097#1080#1077' '
    TabOrder = 0
    object LngLbl: TLabel
      Left = 8
      Top = 24
      Width = 34
      Height = 13
      Caption = #1071#1079#1099#1082' :'
    end
    object DownloadsPathLbl: TLabel
      Left = 8
      Top = 72
      Width = 153
      Height = 13
      Caption = #1055#1091#1090#1100' '#1076#1083#1103' '#1079#1072#1075#1088#1091#1079#1082#1080' '#1087#1086#1076#1082#1072#1089#1090#1086#1074':'
    end
    object EditPath: TEdit
      Left = 7
      Top = 88
      Width = 170
      Height = 21
      ReadOnly = True
      TabOrder = 1
    end
    object ChooseBtn: TButton
      Left = 182
      Top = 88
      Width = 75
      Height = 21
      Caption = #1042#1099#1073#1088#1072#1090#1100
      TabOrder = 2
      OnClick = ChooseBtnClick
    end
    object DownloadPodcastsCB: TCheckBox
      Left = 8
      Top = 120
      Width = 128
      Height = 17
      Caption = #1047#1072#1075#1088#1091#1078#1072#1090#1100' '#1087#1086#1076#1082#1072#1089#1090#1099
      Checked = True
      State = cbChecked
      TabOrder = 3
    end
    object LangCB: TComboBox
      Left = 8
      Top = 40
      Width = 145
      Height = 21
      Style = csDropDownList
      ItemHeight = 13
      TabOrder = 0
    end
  end
  object DownloadedPodcastsGB: TGroupBox
    Left = 8
    Top = 160
    Width = 361
    Height = 100
    Caption = #1047#1072#1075#1088#1091#1078#1077#1085#1085#1099#1077' '#1087#1086#1076#1082#1072#1089#1090#1099' '
    TabOrder = 1
    object DownloadedPodcastsDescLbl: TLabel
      Left = 8
      Top = 24
      Width = 342
      Height = 13
      Caption = #1056#1072#1079' '#1074' 3-4 '#1084#1077#1089#1103#1094#1072' '#1078#1077#1083#1072#1090#1077#1083#1100#1085#1086' '#1086#1095#1080#1097#1072#1090#1100' '#1073#1072#1079#1091' '#1089#1089#1099#1083#1086#1082', '#1095#1090#1086#1073#1099' '#1087#1086#1080#1089#1082'...'
    end
    object StatusLbl: TLabel
      Left = 192
      Top = 69
      Width = 161
      Height = 13
    end
    object RemLinksBtn: TButton
      Left = 8
      Top = 63
      Width = 75
      Height = 26
      Caption = #1054#1095#1080#1089#1090#1080#1090#1100
      TabOrder = 0
      OnClick = RemLinksBtnClick
    end
    object ProgressBar: TProgressBar
      Left = 88
      Top = 63
      Width = 97
      Height = 26
      TabOrder = 1
      Visible = False
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
