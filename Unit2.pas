unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ShlObj, IniFiles;

type
  TSettings = class(TForm)
    OkBtn: TButton;
    CancelBtn: TButton;
    OpenDialog: TOpenDialog;
    SaveDialog: TSaveDialog;
    GroupBox1: TGroupBox;
    ImportBtn: TButton;
    ExportBtn: TButton;
    GeneralGroupBox: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    EditPath: TEdit;
    ChooseBtn: TButton;
    DownloadPodcastsChk: TCheckBox;
    LanguageCB: TComboBox;
    DeleteOldBtn: TButton;
    Label3: TLabel;
    procedure OkBtnClick(Sender: TObject);
    procedure ChooseBtnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure CancelBtnClick(Sender: TObject);
    procedure LanguageCBChange(Sender: TObject);
    procedure ImportBtnClick(Sender: TObject);
    procedure ExportBtnClick(Sender: TObject);
    procedure DeleteOldBtnClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Settings: TSettings;
  //язык / Language
  ChooseDirectoryTitle, ChooseDirectoryErrorTitle: string;
  LanguageCBChanged: boolean;

implementation

uses Unit1;

{$R *.dfm}

procedure TSettings.OkBtnClick(Sender: TObject);
var
  Ini: TIniFile;
begin
  if DownloadPodcastsChk.Checked then DownloadPodcasts:=true else DownloadPodcasts:=false;
  Ini:=TIniFile.Create(ExtractFilePath(ParamStr(0))+'Setup.ini');
  Ini.WriteString('Main','Path',EditPath.Text);
  if LanguageCBChanged then begin
    Ini.WriteString('Main','LanguageFile',LanguageCB.Items.Strings[LanguageCB.ItemIndex]);
    Ini.WriteInteger('Main','LanguageIndex',LanguageCB.ItemIndex);
    Ini.WriteBool('Main','FirstStart',true);
  end;
  Ini.Free;
  Close;
end;

function BrowseFolderDialog(Title:PChar):string;
var
  TitleName: string;
  lpItemId: pItemIdList;
  BrowseInfo: TBrowseInfo;
  DisplayName: array[0..max_Path] of char;
  TempPath: array[0..max_Path] of char;
begin
  FillChar(BrowseInfo,SizeOf(tBrowseInfo),#0);
  BrowseInfo.hWndOwner:=GetDesktopWindow;
  BrowseInfo.pSzDisplayName:=@DisplayName;
  TitleName:=Title;
  BrowseInfo.lpsztitle:=PChar(TitleName);
  BrowseInfo.ulflags:=bIf_ReturnOnlyFSDirs;
  lpItemId:=shBrowseForFolder(BrowseInfo);
  if lpItemId<>nil then begin
    shGetPathFromIdList(lpItemId, TempPath);
    Result:=TempPath;
    GlobalFreePtr(lpItemId);
  end;
end;

procedure TSettings.ChooseBtnClick(Sender: TObject);
var
  TempPath: string;
begin
  TempPath:=BrowseFolderDialog(PChar(ChooseDirectoryTitle));
  if TempPath<>'' then begin
    if TempPath[Length(TempPath)]<>'\' then TempPath:=TempPath+'\';
    EditPath.Text:=TempPath;
  end else ShowMessage(ChooseDirectoryErrorTitle);
end;

procedure TSettings.FormCreate(Sender: TObject);
var
  Ini: TIniFile;
  SearchRec: TSearchRec;
begin
  if FindFirst(ExtractFilePath(ParamStr(0))+'Languages\*.ini', faAnyFile, SearchRec)=0  then
  repeat
    LanguageCB.Items.Add(SearchRec.Name);
  until FindNext(SearchRec)<>0;
  FindClose(SearchRec);
  EditPath.Text:=PathDownload;
  LanguageCBChanged:=false;
  Ini:=TIniFile.Create(ExtractFilePath(ParamStr(0))+'Setup.ini');
  LanguageCB.ItemIndex:=Ini.ReadInteger('Main','LanguageIndex',0);
  Ini.Free;
  //язык / Language
  Ini:=TIniFile.Create(ExtractFilePath(ParamStr(0))+'Languages\'+LanguageFile);
  Caption:=Ini.ReadString('Setup','SettingsCaption','');
  GeneralGroupBox.Caption:=Ini.ReadString('Setup','GroupBoxGeneral','')+' ';
  Label1.Caption:=Ini.ReadString('Setup','LanguageFile','');
  Label2.Caption:=Ini.ReadString('Setup','PathForDownloadPodcasts','');
  Label3.Caption:=Ini.ReadString('Setup','ListSavedPodcasts','');
  DeleteOldBtn.Caption:=Ini.ReadString('Setup','ButtonDeleteOld','');
  ChooseBtn.Caption:=Ini.ReadString('Setup','Choose','');
  DownloadPodcastsChk.Caption:=Ini.ReadString('Setup','CheckBoxDownloadPodcasts','');
  ImportBtn.Caption:=Ini.ReadString('Setup','ButtonImport','');
  ExportBtn.Caption:=Ini.ReadString('Setup','ButtonExport','');
  OkBtn.Caption:=Ini.ReadString('Setup','Ok','');
  CancelBtn.Caption:=Ini.ReadString('Setup','Cancel','');
  ChooseDirectoryTitle:=Ini.ReadString('Setup','ChooseDirectory','');
  ChooseDirectoryErrorTitle:=Ini.ReadString('Setup','ChooseDirectoryError','');
  Ini.Free;
end;

procedure TSettings.CancelBtnClick(Sender: TObject);
begin
  Close;
end;

procedure TSettings.LanguageCBChange(Sender: TObject);
begin
  LanguageCBChanged:=true;
end;

procedure TSettings.ImportBtnClick(Sender: TObject);
var
  OPML:TStringList; i, countAdded:integer; rssLink:string;
begin
  if OpenDialog.Execute then begin
  countAdded:=0;
  OPML:=TStringList.Create;
  OPML.LoadFromFile(OpenDialog.FileName);
  for i:=0 to OPML.Count-1 do
    if Pos('xmlUrl="',OPML.Strings[i])>0 then begin
      rssLink:=OPML.Strings[i];
      delete(rssLink,1,Pos('xmlUrl="',rssLink)+7);
      delete(rssLink,Pos('"',rssLink),Length(rssLink));
      if (Copy(AnsiLowerCase(rssLink),1,7)='http://') or (Copy(AnsiLowerCase(rssLink),1,8)='https://') then
        if Pos(rssLink,Main.MemoRssList.Text)=0 then begin
          Main.MemoRssList.Lines.Add(rssLink);
          inc(countAdded);
        end;
    end;
  OPML.Free;
  if countAdded=0 then
    ShowMessage('Ќовостных лент не добавлено')
  else
    ShowMessage('ƒобавлено новостных лент : '+IntToStr(countAdded));
  end;
end;

function ExtractHost(Url: string): string;
begin
  delete(Url,1,Pos('://',Url)+2);
  Result:=Copy(Url,1,Pos('/',Url)-1);
end;

procedure TSettings.ExportBtnClick(Sender: TObject);
var
  OPML:TStringList; i:integer;
begin
  if SaveDialog.Execute then begin
    OPML:=TStringList.Create;
    OPML.Add('<?xml version="1.0" encoding="UTF-8"?>');
    OPML.Add('<opml version="1.0">');
    OPML.Add(#9+'<head>');
    OPML.Add(#9+#9+'<title>RSS ленты</title>');
    OPML.Add(#9+#9+'<ownerName>Podcast Easy</ownerName>');
    OPML.Add(#9+#9+'<ownerEmail>PodcastEasy@r57zone</ownerEmail>');
    OPML.Add(#9+'</head>');
    OPML.Add(#9+'<body>');
    for i:=0 to Main.MemoRssList.Lines.Count-1 do
      OPML.Add(#9+#9+'<outline text="'+ExtractHost(Main.MemoRssList.Lines.Strings[i])+' RSS" xmlUrl="'+Main.MemoRssList.Lines.Strings[i]+'"/>');
    OPML.Add(#9+'</body>');
    OPML.Add('</opml>');
    OPML.Text:=AnsiToUTF8(OPML.Text);
    OPML.SaveToFile(SaveDialog.FileName);
    OPML.Free;
    ShowMessage('‘айл OPML сохранен');
  end;
end;

procedure TSettings.DeleteOldBtnClick(Sender: TObject);
begin
Visible:=false;
Main.CheckLinksDownloaded;
Visible:=true;
end;

end.
