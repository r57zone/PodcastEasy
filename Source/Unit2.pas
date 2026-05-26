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
    SelectFolderBtn: TButton;
    DownloadPodcastsCB: TCheckBox;
    RemLinksBtn: TButton;
    ProgressBar: TProgressBar;
    DownloadedPodcastsDescLbl: TLabel;
    DownloadedPodcastsGB: TGroupBox;
    AboutBtn: TButton;
    ProxyGB: TGroupBox;
    AddressLbl: TLabel;
    AddressEdt: TEdit;
    PortLbl: TLabel;
    PortEdt: TEdit;
    ProxyClrBtn: TButton;
    StatusLbl: TLabel;
    procedure OkBtnClick(Sender: TObject);
    procedure SelectFolderBtnClick(Sender: TObject);
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
    procedure ProxyClrBtnClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Settings: TSettings;
  //язык / Language
  IDS_SELECT_FOLDER, IDS_SELECT_FOLDER_ERROR, IDS_OPML_FILE_SAVED, IDS_ADDED_OPML_FEED: string;

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
  DownloadPath:=EditPath.Text;
  Ini:=TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'Setup.ini');
  Ini.WriteString('Main', 'Path', EditPath.Text);
  Ini.WriteString('Proxy', 'Address', Trim(AddressEdt.Text));
  Ini.WriteString('Proxy', 'Port', Trim(PortEdt.Text));

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

procedure TSettings.SelectFolderBtnClick(Sender: TObject);
var
  TempPath: string;
begin
  TempPath:=BrowseFolderDialog(PChar(IDS_SELECT_FOLDER));
  if TempPath <> '' then begin
    if TempPath[Length(TempPath)] <> '\' then
      TempPath:=TempPath + '\';
    EditPath.Text:=TempPath;
  end else
    Application.MessageBox(PChar(IDS_SELECT_FOLDER_ERROR), PChar(Caption), MB_ICONWARNING);
end;

procedure TSettings.FormCreate(Sender: TObject);
var
  Ini: TIniFile;
begin
  EditPath.Text:=DownloadPath;
  AddressEdt.Text:=ProxyAddress;
  PortEdt.Text:=ProxyPort;

  //ѕеревод / Translate
  Ini:=TIniFile.Create(AppFilePath + 'Languages\' + LangFileName);
  Caption:=Ini.ReadString('Settings','SETTINGS_TITLE','Settings');
  CommonGB.Caption:=Ini.ReadString('Settings', 'COMMON', 'Common') + ' ';
  DownloadsPathLbl.Caption:=Ini.ReadString('Settings', 'DOWNLOADS_PATH', 'Path for download podcasts:');
  SelectFolderBtn.Caption:=Ini.ReadString('Settings', 'SELECT', 'Select');
  DownloadPodcastsCB.Caption:=Ini.ReadString('Settings', 'DOWNLOAD_PODCASTS', 'Download podcasts');
  ImportBtn.Caption:=Ini.ReadString('Settings', 'IMPORT', 'Import');
  ExportBtn.Caption:=Ini.ReadString('Settings', 'EXPORT', 'Export');
  ProxyGB.Caption:=Ini.ReadString('Settings', 'PROXY', 'HTTP Proxy');
  AddressLbl.Caption:=Ini.ReadString('Settings', 'ADDRESS', 'ADDRESS');
  PortLbl.Caption:=Ini.ReadString('Settings', 'PORT', 'Port');
  IDS_OPML_FILE_SAVED:=Ini.ReadString('Settings', 'OPML_FILE_SAVED', 'OPML file was successfully saved');
  OkBtn.Caption:=Ini.ReadString('Settings', 'OK', 'OK');
  CancelBtn.Caption:=Ini.ReadString('Settings', 'CANCEL', 'Cancel');
  IDS_SELECT_FOLDER:=Ini.ReadString('Settings', 'SELECT_FOLDER', 'Select folder');
  IDS_SELECT_FOLDER_ERROR:=Ini.ReadString('Settings', 'SELECT_FOLDER_ERROR', 'Folder not selected');
  IDS_ADDED_OPML_FEED:=Ini.ReadString('Settings', 'ADDED_OPML_FEED', 'Added RSS feeds: ');
  DownloadedPodcastsGB.Caption:=Ini.ReadString('Settings', 'DOWNLOADED_PODCASTS', 'Downloaded podcasts') + ' ';
  RemLinksBtn.Caption:=Ini.ReadString('Settings', 'CLEAR', 'Clear');
  DownloadedPodcastsDescLbl.Caption:=StringReplace(Ini.ReadString('Settings', 'DOWNLOADED_PODCASTS_DESCRIPTION', 'Once every 3-4 months, is desirable to clean\ndatabase links to find new podcasts are not\nslowed down.'), '\n', #13#10, [rfReplaceAll]);
  Ini.Free;

  SetWindowLong(PortEdt.Handle, GWL_STYLE, GetWindowLong(PortEdt.Handle, GWL_STYLE) or ES_NUMBER);
end;

procedure TSettings.CancelBtnClick(Sender: TObject);
begin
  Close;
end;

procedure TSettings.ImportBtnClick(Sender: TObject);
var
  OPML: TStringList; i, RSSAddedCount: integer; RSSLink: string;
begin
  if OpenDialog.Execute then begin
    RSSAddedCount:=0;
    OPML:=TStringList.Create;
    OPML.LoadFromFile(OpenDialog.FileName);
    for i:=0 to OPML.Count - 1 do
      if Pos('xmlUrl="',OPML.Strings[i]) > 0 then begin
        RSSLink:=OPML.Strings[i];
        delete(RSSLink, 1, Pos('xmlUrl="', RSSLink) + 7);
        delete(RSSLink, Pos('"', RSSLink), Length(RSSLink));
        if (Copy(LowerCase(RSSLink), 1, 7)='http://') or (Copy(LowerCase(RSSLink), 1, 8)='https://') then
          if Pos(RSSLink, Main.RSSListMemo.Text) = 0 then begin
            Main.RSSListMemo.Lines.Add(RSSLink);
            Inc(RSSAddedCount);
          end;
      end;
    OPML.Free;
    Application.MessageBox(PChar(IDS_ADDED_OPML_FEED + ' ' +  IntToStr(RSSAddedCount)), PChar(Caption), MB_ICONINFORMATION);
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
    Application.MessageBox(PChar(IDS_OPML_FILE_SAVED), PChar(Caption), MB_ICONINFORMATION);
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
  Application.MessageBox(PChar(Main.Caption + ' 1.2' + #13#10 +
  IDS_LAST_UPDATE + ' 26.05.26' + #13#10 +
  'https://r57zone.github.io' + #13#10 +
  'r57zone@gmail.com'), PChar(IDS_ABOUT_TITLE), MB_ICONINFORMATION);
end;

procedure TSettings.ProxyClrBtnClick(Sender: TObject);
begin
  AddressEdt.Text:='';
  PortEdt.Text:='';
end;

end.
