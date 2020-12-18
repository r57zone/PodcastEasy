unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ShlObj, IniFiles, ComCtrls;

type
  TSettings = class(TForm)
    OkBtn: TButton;
    CancelBtn: TButton;
    OpenDialog: TOpenDialog;
    SaveDialog: TSaveDialog;
    OPMLGB: TGroupBox;
    ImportBtn: TButton;
    ExportBtn: TButton;
    CommonGB: TGroupBox;
    DownloadsPathLbl: TLabel;
    EditPath: TEdit;
    ChooseBtn: TButton;
    DownloadPodcastsCB: TCheckBox;
    RemLinksBtn: TButton;
    ProgressBar: TProgressBar;
    DownloadedPodcastsDescLbl: TLabel;
    DownloadedPodcastsGB: TGroupBox;
    StatusLbl: TLabel;
    AboutBtn: TButton;
    procedure OkBtnClick(Sender: TObject);
    procedure ChooseBtnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure CancelBtnClick(Sender: TObject);
    procedure ImportBtnClick(Sender: TObject);
    procedure ExportBtnClick(Sender: TObject);
    procedure RemLinksBtnClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure EditPathKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure AboutBtnClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Settings: TSettings;
  //язык / Language
  ID_CHOOSE_DIR, ID_CHOOSE_DIR_ERROR, ID_OPML_FILE_SAVED, ID_ADDED_OPML_FEED: string;

implementation

uses Unit1;

{$R *.dfm}

procedure TSettings.OkBtnClick(Sender: TObject);
var
  Ini: TIniFile;
begin
  if DownloadPodcastsCB.Checked then
    DownloadPodcasts:=true
  else
    DownloadPodcasts:=false;
  Ini:=TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'Setup.ini');
  Ini.WriteString('Main', 'Path', EditPath.Text);
  Ini.Free;
  Close;
end;

function BrowseFolderDialog(Title:PChar):string;
var
  TitleName: string;
  lpItemId: pItemIdList;
  BrowseInfo: TBrowseInfo;
  DisplayName: array[0..MAX_PATH] of Char;
  TempPath: array[0..MAX_PATH] of Char;
begin
  FillChar(BrowseInfo, SizeOf(TBrowseInfo), #0);
  BrowseInfo.hWndOwner:=GetDesktopWindow;
  BrowseInfo.pSzDisplayName:=@DisplayName;
  TitleName:=Title;
  BrowseInfo.lpsztitle:=PChar(TitleName);
  BrowseInfo.ulflags:=bIf_ReturnOnlyFSDirs;
  lpItemId:=shBrowseForFolder(BrowseInfo);
  if lpItemId <> nil then begin
    shGetPathFromIdList(lpItemId, TempPath);
    Result:=TempPath;
    GlobalFreePtr(lpItemId);
  end;
end;

procedure TSettings.ChooseBtnClick(Sender: TObject);
var
  TempPath: string;
begin
  TempPath:=BrowseFolderDialog(PChar(ID_CHOOSE_DIR));
  if TempPath <> '' then begin
    if TempPath[Length(TempPath)] <> '\' then
      TempPath:=TempPath + '\';
    EditPath.Text:=TempPath;
  end else
    Application.MessageBox(PChar(ID_CHOOSE_DIR_ERROR), PChar(Caption), MB_ICONWARNING);
end;

procedure TSettings.FormCreate(Sender: TObject);
var
  Ini: TIniFile;
begin
  EditPath.Text:=DownloadPath;

  //ѕеревод / Translate
  Ini:=TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'Languages\' + LangFile);
  Caption:=Ini.ReadString('Settings','ID_SETTINGS_TITLE','');
  CommonGB.Caption:=Ini.ReadString('Settings', 'ID_COMMON', '') + ' ';
  DownloadsPathLbl.Caption:=Ini.ReadString('Settings', 'ID_DOWNLOADS_PATH', '');
  ChooseBtn.Caption:=Ini.ReadString('Settings', 'ID_CHOOSE', '');
  DownloadPodcastsCB.Caption:=Ini.ReadString('Settings', 'ID_DOWNLOAD_PODCASTS', '');
  ImportBtn.Caption:=Ini.ReadString('Settings', 'ID_IMPORT', '');
  ExportBtn.Caption:=Ini.ReadString('Settings', 'ID_EXPORT', '');
  ID_OPML_FILE_SAVED:=Ini.ReadString('Settings', 'ID_OPML_FILE_SAVED', '');
  OkBtn.Caption:=Ini.ReadString('Settings', 'ID_OK', '');
  CancelBtn.Caption:=Ini.ReadString('Settings', 'ID_CANCEL', '');
  ID_CHOOSE_DIR:=Ini.ReadString('Settings', 'ID_CHOOSE_DIR', '');
  ID_CHOOSE_DIR_ERROR:=Ini.ReadString('Settings', 'ID_CHOOSE_DIR_ERROR', '');
  ID_ADDED_OPML_FEED:=Ini.ReadString('Settings', 'ID_ADDED_OPML_FEED', '');
  DownloadedPodcastsGB.Caption:=Ini.ReadString('Settings', 'ID_DOWNLOADED_PODCASTS', '') + ' ';
  RemLinksBtn.Caption:=Ini.ReadString('Settings', 'ID_REMOVE_OLD_LINKS', '');
  DownloadedPodcastsDescLbl.Caption:=StringReplace(Ini.ReadString('Settings', 'ID_DOWNLOADED_PODCASTS_DESCRIPTION', ''), '\n', #13#10, [rfReplaceAll]);
  Ini.Free;
end;

procedure TSettings.CancelBtnClick(Sender: TObject);
begin
  Close;
end;

procedure TSettings.ImportBtnClick(Sender: TObject);
var
  OPML:TStringList; i, countAdded:integer; rssLink:string;
begin
  if OpenDialog.Execute then begin
    countAdded:=0;
    OPML:=TStringList.Create;
    OPML.LoadFromFile(OpenDialog.FileName);
    for i:=0 to OPML.Count - 1 do
      if Pos('xmlUrl="',OPML.Strings[i]) > 0 then begin
        rssLink:=OPML.Strings[i];
        delete(rssLink, 1, Pos('xmlUrl="', rssLink) + 7);
        delete(rssLink, Pos('"', rssLink), Length(rssLink));
        if (Copy(LowerCase(rssLink), 1, 7)='http://') or (Copy(LowerCase(rssLink), 1, 8)='https://') then
          if Pos(rssLink, Main.RSSListMemo.Text) = 0 then begin
            Main.RSSListMemo.Lines.Add(rssLink);
            Inc(countAdded);
          end;
      end;
    OPML.Free;
    Application.MessageBox(PChar(ID_ADDED_OPML_FEED + ' ' +  IntToStr(countAdded)), PChar(Caption), MB_ICONINFORMATION);
  end;
end;

function ExtractHost(Url: string): string;
begin
  delete(Url, 1, Pos('://', Url) + 2);
  Result:=Copy(Url, 1, Pos('/', Url) - 1);
end;

procedure TSettings.ExportBtnClick(Sender: TObject);
var
  OPML: TStringList;
  i: integer;
begin
  if SaveDialog.Execute then begin
    OPML:=TStringList.Create;
    OPML.Add('<?xml version="1.0" encoding="UTF-8"?>');
    OPML.Add('<opml version="1.0">');
    OPML.Add(#9 + '<head>');
    OPML.Add(#9 + #9 + '<title>RSS feeds</title>');
    OPML.Add(#9 + #9 + '<ownerName>Podcast Easy</ownerName>');
    OPML.Add(#9 + #9 + '<ownerEmail>PodcastEasy@r57zone</ownerEmail>');
    OPML.Add(#9 + '</head>');
    OPML.Add(#9 + '<body>');
    for i:=0 to Main.RSSListMemo.Lines.Count - 1 do
      OPML.Add(#9 + #9 + '<outline text="' + ExtractHost(Main.RSSListMemo.Lines.Strings[i]) + ' RSS" xmlUrl="' + Main.RSSListMemo.Lines.Strings[i] + '"/>');
    OPML.Add(#9 + '</body>');
    OPML.Add('</opml>');
    OPML.Text:=AnsiToUTF8(OPML.Text);
    OPML.SaveToFile(SaveDialog.FileName);
    OPML.Free;
    Application.MessageBox(PChar(ID_OPML_FILE_SAVED), PChar(Caption), MB_ICONINFORMATION);
  end;
end;

procedure TSettings.RemLinksBtnClick(Sender: TObject);
begin
  Main.CheckDownloadedLinks;
end;

procedure TSettings.FormShow(Sender: TObject);
begin
  DownloadPodcastsCB.Checked:=DownloadPodcasts;
end;

procedure TSettings.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  //”бираем баг скрыти€ контролов
  if Key = VK_MENU then
    Key:=0;
end;

procedure TSettings.EditPathKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  //”бираем баг скрыти€ контролов
  if Key = VK_MENU then
    Key:=0;
end;

procedure TSettings.AboutBtnClick(Sender: TObject);
begin
  Application.MessageBox(PChar(Caption + ' 1.0' + #13#10 +
  ID_LAST_UPDATE + ' 18.12.2020' + #13#10 +
  'https://r57zone.github.io' + #13#10 +
  'r57zone@gmail.com'), PChar(ID_ABOUT_TITLE), MB_ICONINFORMATION);
end;

end.
