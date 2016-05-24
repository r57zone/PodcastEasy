unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ShlObj, IniFiles;

type
  TSettings = class(TForm)
    Label1: TLabel;
    EditPath: TEdit;
    ChooseBtn: TButton;
    DownloadPodcastsChk: TCheckBox;
    Label2: TLabel;
    LanguageCB: TComboBox;
    OkBtn: TButton;
    CancelBtn: TButton;
    procedure OkBtnClick(Sender: TObject);
    procedure ChooseBtnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure CancelBtnClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure LanguageCBChange(Sender: TObject);
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
  if TempPath<>'' then
    EditPath.Text:=TempPath
  else ShowMessage(ChooseDirectoryErrorTitle);
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
  Label1.Caption:=Ini.ReadString('Setup','LanguageFile','');
  Label2.Caption:=Ini.ReadString('Setup','PathForDownloadPodcasts','');
  ChooseBtn.Caption:=Ini.ReadString('Setup','Choose','');
  DownloadPodcastsChk.Caption:=Ini.ReadString('Setup','CheckBoxDownloadPodcasts','');
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

procedure TSettings.FormShow(Sender: TObject);
begin
  Left:=Main.Left;
  Top:=Main.Top;
end;

procedure TSettings.LanguageCBChange(Sender: TObject);
begin
  LanguageCBChanged:=true;
end;

end.
