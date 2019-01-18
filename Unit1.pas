unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, WinInet, XPMan, ComCtrls, IniFiles, ShellAPI, ExtCtrls,
  Buttons, RegExpr;

type
  TMain = class(TForm)
    RefreshBtn: TButton;
    RSSListMemo: TMemo;
    StatusBar: TStatusBar;
    XPManifest: TXPManifest;
    OpenFolderBtn: TButton;
    Timer: TTimer;
    SettingsBtn: TSpeedButton;
    procedure RefreshBtnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure OpenFolderBtnClick(Sender: TObject);
    procedure TimerTimer(Sender: TObject);
    procedure StatusBarClick(Sender: TObject);
    procedure CheckDownloadedLinks;
    procedure RSSListMemoChange(Sender: TObject);
    procedure SettingsBtnClick(Sender: TObject);
  private
    procedure WMCopyData(var Msg: TWMCopyData); message WM_COPYDATA;
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Main: TMain;
  DownloadPath, LangFile, ModuleWndID: string;
  SyncList: TStringList;
  hTargetWnd: hWnd;
  DownloadPodcasts, RssChanged: boolean;

  //Перевод / Translate
  //Main
  ID_NEW_FEED_QUESTION, ID_CHECK_FEED: string;
  ID_NEW_PODCAST, ID_DOWNLOAD_PODCASTS, ID_PODCASTS_DOWNLOADED, ID_PODCASTS_SKIPPED, ID_PODCASTS_NOT_FOUND: string;
  ID_DOWNLOAD_ERROR: string;
  //About
  ID_ABOUT_TITLE, ID_LAST_UPDATE: string;
  //Remove links
  ID_STAGE_1, ID_STAGE_2, ID_REMOVED_LINKS, ID_FAILED_GET_RSS: string;

  ID_GUIDE: string;

  //StandartModularProgram
  ID_UPLOADED_PODCASTS_TO_DEVICE: string;

implementation

uses Unit2;

{$R *.dfm}

procedure WriteLog(Str: string);
const
  LogWrite = true;
  LogFileName = 'log.txt';
var
  F: TextFile;
begin
  if not LogWrite then
    Exit;
  AssignFile(F, ExtractFilePath(ParamStr(0)) + LogFileName);
  if FileExists(ExtractFilePath(ParamStr(0)) + LogFileName) then
    Append(F)
  else
    Rewrite(F);
  Writeln(F, Str);
  CloseFile(F);
end;

function GetLocaleInformation(Flag: integer): string;
var
  pcLCA: array [0..20] of Char;
begin
  if GetLocaleInfo(LOCALE_SYSTEM_DEFAULT, Flag, pcLCA, 19) <= 0 then
    pcLCA[0]:=#0;
  Result:=pcLCA;
end;

function CheckUrl(const URL: string): boolean;
var
  hSession, hUrl: HINTERNET;
  dwIndex, dwCodeLen, dwFlags: DWORD;
  dwCode: array [1..20] of Char;
begin
  Result:=false;
  hSession:=InternetOpen('Mozilla/4.0 (MSIE 6.0; Windows NT 5.1)', INTERNET_OPEN_TYPE_PRECONFIG, nil, nil, 0);
  if Assigned(hSession) then begin
  
    if Copy(LowerCase(URL), 1, 8) = 'https://' then
      dwFlags:=INTERNET_FLAG_SECURE
    else
      dwFlags:=INTERNET_FLAG_RELOAD;

    hUrl:=InternetOpenURL(hSession, PChar(URL), nil, 0, dwFlags, 0);
    if Assigned(hUrl) then begin
      dwIndex:=0;
      dwCodeLen:=10;
      if HttpQueryInfo(hUrl, HTTP_QUERY_STATUS_CODE, @dwCode, dwCodeLen, dwIndex) then
        Result:=(PChar(@dwCode) = IntToStr(HTTP_STATUS_OK)) or (PChar(@dwCode) = IntToStr(HTTP_STATUS_REDIRECT));
      InternetCloseHandle(hUrl);
    end;

    InternetCloseHandle(hSession);
  end;
end;

function HTTPGet(URL: string): string;
var
  hSession, hUrl: HINTERNET;
  Buffer: array [0..1023] of Byte;
  dwFlags, BufferLen: DWORD;
  StrStream: TStringStream;
begin
  Result:='';
  hSession:=InternetOpen('Mozilla/4.0 (MSIE 6.0; Windows NT 5.1)', INTERNET_OPEN_TYPE_PRECONFIG, nil, nil, 0);
  if Assigned(hSession) then begin

    if Copy(LowerCase(URL), 1, 8) = 'https://' then
      dwFlags:=INTERNET_FLAG_SECURE
    else
      dwFlags:=INTERNET_FLAG_RELOAD;

    hUrl:=InternetOpenUrl(hSession, PChar(URL), nil, 0, dwFlags, 0);
    if Assigned(hUrl) then begin
      StrStream:=TStringStream.Create('');
      try
        repeat
          Application.ProcessMessages;
          FillChar(Buffer, SizeOf(Buffer), 0);
          BufferLen:=0;
          if InternetReadFile(hURL, @Buffer, SizeOf(Buffer), BufferLen) then
            StrStream.WriteBuffer(Buffer, BufferLen)
          else
            Break;
        until BufferLen = 0;
        Result:=StrStream.DataString;
      except
        Result:='';
      end;
      StrStream.Free;

      InternetCloseHandle(hUrl);
    end;

    InternetCloseHandle(hSession);
  end;
end;

function GetUrlSize(const URL: string): integer;
var
  hSession, hFile: HINTERNET;
  dwBuffer: array[1..20] of Char;
  dwIndex, dwBufferLen, dwFlags: DWORD;
begin
  Result:=0;
  hSession:=InternetOpen('Mozilla/4.0 (MSIE 6.0; Windows NT 5.1)', INTERNET_OPEN_TYPE_PRECONFIG, nil, nil, 0);
  if Assigned(hSession) then begin

    if Copy(LowerCase(URL), 1, 8) = 'https://' then
      dwFlags:=INTERNET_FLAG_SECURE
    else
      dwFlags:=INTERNET_FLAG_RELOAD;

    hFile:=InternetOpenURL(hSession, PChar(URL), nil, 0, dwFlags, 0);
    if Assigned(hFile) then begin
      dwIndex:=0;
      dwBufferLen:=20;
      if HttpQueryInfo(hFile, HTTP_QUERY_CONTENT_LENGTH, @dwBuffer, dwBufferLen, dwIndex) then
        Result:=StrToInt(StrPas(@dwBuffer));

      InternetCloseHandle(hFile);
    end;

    InternetCloseHandle(hSession);
  end;
end;

function GetFileSize(const FileName: string): int64;
var
  FoundData: TSearchRec;
begin
  FindFirst(FileName, faAnyFile, FoundData);
  Result:=(Int64(FoundData.FindData.nFileSizeHigh) * MAXDWORD) + Int64(FoundData.FindData.nFileSizeLow);
  FindClose(FoundData);
end;

function DownloadFile(const FileURL, Path: string; out DownloadedFileName: string): boolean;
var
  hSession, hFile: HINTERNET;
  Buffer: array[0..1023] of Byte;
  BufferLen: DWORD;
  F: file;
  FileSize, FileExistsCounter: int64;
begin
  FileSize:=GetUrlSize(FileURL);
  hSession:=InternetOpen('Mozilla/4.0 (MSIE 6.0; Windows NT 5.1)', INTERNET_OPEN_TYPE_PRECONFIG, nil, nil, 0);
  if Assigned(hSession) then begin

    hFile:=InternetOpenURL(hSession, PChar(FileURL), nil, 0, 0, 0);
    if Assigned(hFile) then begin

      try
        DownloadedFileName:=ExtractFileName(StringReplace(FileURL, '/', '\', [rfReplaceAll]));
        if not FileExists(Path + DownloadedFileName) then
          AssignFile(F, Path + DownloadedFileName)
        else begin
          FileExistsCounter:=1;
          while true do begin
            DownloadedFileName:=ExtractFileName(StringReplace(Copy(FileURL, 1, Length(FileURL) - 4), '/', '\', [rfReplaceAll])) + '(' + IntToStr(FileExistsCounter) + ')' + ExtractFileExt(FileURL);
            if not FileExists(Path + DownloadedFileName) then begin
              AssignFile(F, Path + DownloadedFileName);
              Break;
            end;
            inc(FileExistsCounter);
          end;
        end;
        ReWrite(F, 1);
        repeat
          if InternetReadFile(hFile, @Buffer, SizeOf(Buffer), BufferLen) then
            BlockWrite(F, Buffer, BufferLen)
          else
            Break;
          Application.ProcessMessages;
        until BufferLen=0;
        CloseFile(F);
      except
      end;

      InternetCloseHandle(hFile);
    end;

    InternetCloseHandle(hSession);
  end;

  //Проверка на целостность файла / Checking file size
  if FileSize <> GetFileSize(Path + DownloadedFileName) then begin
    //Удаляем неполный файл / Delete the incomplete file
    DeleteFile(Path + DownloadedFileName);
    Result:=false;
  end else Result:=true;
end;

//Стандарт модульных программ / Standart modular program - https://github.com/r57zone/Standard-modular-program
//Отправка сообщений модульным программам / Send messages to modular programs
procedure SendMessageToHandle(TargetWND: HWND; MsgToHandle: string);
var
  CDS: TCopyDataStruct;
begin
  CDS.dwData:=0;
  CDS.cbData:=(Length(MsgToHandle) + 1) * SizeOf(Char);
  CDS.lpData:=PChar(MsgToHandle);
  SendMessage(TargetWND, WM_COPYDATA, Integer(Application.Handle), Integer(@CDS));
end;

function FindWindowExtd(PartTitle: string): HWND;
var
  hWndN: HWND;
  TitleLen: integer;
  CurTitleWnd: array [0..254] of Char;
  TitleWnd: string;
begin
  hWndN:=FindWindow(nil, nil);
  while hWndN <> 0 do begin
    TitleLen:=GetWindowText(hWndN, CurTitleWnd, 255);
    TitleWnd:=AnsiLowerCase(Copy(CurTitleWnd, 1, TitleLen));
    PartTitle:=AnsiLowerCase(PartTitle);
    if Pos(PartTitle, TitleWnd) <> 0 then
      Break;
    hWndN:=GetWindow(hWndN, GW_HWNDNEXT);
  end;
  Result:=hWndN;
end;

procedure TMain.RefreshBtnClick(Sender: TObject);
const
  PodcastExt = 'mp3|aac|ogg|mp4';
var
  RegExp: TRegExpr;
  GetRss, Downloaded, Download: TStringList;
  i, j, ErrorCount, DownloadCount, DownloadIndex: integer;
  Error: boolean;
  DownloadedFileName: string;
begin
  //Пропуск загрузки новых подкастов для новой ленты / Skip download new podcasts for new feed
  if RssChanged then
    case MessageBox(Handle, PChar(StringReplace(ID_NEW_FEED_QUESTION, '\n', #13#10, [rfReplaceAll])), PChar(Caption), MB_YESNO + MB_ICONQUESTION) of
      6: DownloadPodcasts:=false;
      7: DownloadPodcasts:=true;
    end;

  RegExp:=TRegExpr.Create;
  RegExp.ModifierG:=false; //Не жадный режим / None greedy mode
  Error:=false; //Ошибка загрузки файлов / Error downloaded files
  ErrorCount:=0; //Счетчик неполных файлов / Counter incomplete files
  DownloadCount:=0; //Счетчик файлов на загрузку / Counter files to download
  GetRss:=TStringList.Create; //Лента / Rss
  Downloaded:=TStringList.Create; //Список ссылок загруженных подкастов / List of links downloaded podcasts
  Download:=TStringList.Create;
  //Отключение кнопок / Disable buttons
  RefreshBtn.Enabled:=false;
  RssListMemo.ReadOnly:=true;
  SettingsBtn.Enabled:=false;

  if FileExists(ExtractFilePath(ParamStr(0)) + 'Downloaded.txt') then
    Downloaded.LoadFromFile(ExtractFilePath(ParamStr(0)) + 'Downloaded.txt');

  //Проверка лент на новые подкасты / Check feed for new podcasts
  for i:=0 to RssListMemo.Lines.Count - 1 do begin

    if Trim(RssListMemo.Lines.Strings[i]) = '' then
      Continue;

    GetRss.Text:=HTTPGet(RssListMemo.Lines.Strings[i]);

    StatusBar.SimpleText:=' ' + Format(ID_CHECK_FEED, [i + 1, RssListMemo.Lines.Count]);
    if Trim(GetRss.Text) = '' then
      Continue;

    //Atom, устаревший стандарт / old standard
    RegExp.Expression:='(?i)<content.*src="(.*(' + PodcastExt + '))"';

    try
      if RegExp.Exec(GetRss.Text) then
        repeat
          if (Pos(RegExp.Match[1], Download.Text) = 0) and //Проверяем добавлялась ли ссылка в список загрузки / Checking if the link was added to the download list
          (Pos(RegExp.Match[1], Downloaded.Text) = 0) and  //Проверяем была ли загружена ссылка ранее / Checking if the link was previously downloaded
          (CheckUrl(RegExp.Match[1])) then begin
            StatusBar.SimpleText:=' ' + ID_NEW_PODCAST + ' ' + Copy(RssListMemo.Lines.Strings[i], 1, 20) + '...';

            //Добавление ссылки в список для загрузки / Add link to download list
            Download.Add(RegExp.Match[1]);
          end;
        until not RegExp.ExecNext;
    except
    end;

    //RSS 2.0
    RegExp.Expression:='(?i)<enclosure.*url="(.*(' + PodcastExt + '))"';

    try
      if RegExp.Exec(GetRss.Text) then
        repeat
          if (Pos(RegExp.Match[1], Download.Text) = 0) and //Проверяем добавлялась ли ссылка в список загрузки / Checking if the link was added to the download list
          (Pos(RegExp.Match[1], Downloaded.Text) = 0) and  //Проверяем была ли загружена ссылка ранее / Checking if the link was previously downloaded
          (CheckUrl(RegExp.Match[1])) then begin
            StatusBar.SimpleText:=' ' + ID_NEW_PODCAST + ' ' + Copy(RssListMemo.Lines.Strings[i], 1, 20) + '...';

            //Добавление ссылки в список для загрузки / Add link to download list
            Download.Add(RegExp.Match[1]);
          end;
        until not RegExp.ExecNext;
    except
    end;

  end;

  //Загрузка файлов / Download files
  if Download.Count > 0 then begin

    DownloadCount:=Download.Count;
    DownloadIndex:=0;

    for i:=Download.Count - 1 downto 0 do begin
      Inc(DownloadIndex);
      StatusBar.SimpleText:=' ' + Format(ID_DOWNLOAD_PODCASTS, [DownloadIndex, DownloadCount]);

      if DownloadPodcasts then //Разрешение на загрузку / Permission to download
        if DownloadFile(Download.Strings[i], DownloadPath, DownloadedFileName) = false then begin //В случае ошибки / If error
          Download.Delete(i); //Удаляем из списка на сохранение файл, который не загрузился целиком / Remove from list to save the file, which is not fully downloaded
          Error:=true;
          inc(ErrorCount);
        end else
          if ModuleWndID <> '' then begin //Стандарт модульных программ / Standart modular program - https://github.com/r57zone/Standard-modular-program
            if Assigned(SyncList) = false then begin
              SyncList:=TStringList.Create;
              SyncList.Add('FILES TO SYNC');
            end;
            SyncList.Add(DownloadPath + DownloadedFileName);
          end;
      Application.ProcessMessages;
    end;

    if Error = false then begin

      if DownloadPodcasts then
        StatusBar.SimpleText:=' ' + ID_PODCASTS_DOWNLOADED  //Все подкасты загружены // All Podcasts downloaded
      else
        StatusBar.SimpleText:=' ' + ID_PODCASTS_SKIPPED;  //Все подкасты пропущены // All Podcasts skipped

    end else
      StatusBar.SimpleText:=' ' + Format(ID_DOWNLOAD_ERROR, [Download.Count, DownloadCount]); //Ошибка загрузки / Download error

    //Сохранение ссылок на загруженные подкасты, чтобы не загружать их снова / Save links to downloaded podcasts to not download them again
    Downloaded.Add(Download.Text);

    //Удаляем пустые строки / Remove the blank lines
    for i:=Downloaded.Count - 1 downto 0 do
      if Length(Trim(Downloaded.Strings[i])) = 0 then Downloaded.Delete(i);
    //Сохранение списка загруженных подкастов / Save list of podcasts downloaded links  
    Downloaded.SaveToFile(ExtractFilePath(ParamStr(0)) + 'Downloaded.txt');

  end else StatusBar.SimpleText:=' ' + ID_PODCASTS_NOT_FOUND; //Новых подкастов не найдено / Not found new podcasts

  //Включение кнопок / Enable buttons
  RefreshBtn.Enabled:=true;
  RssListMemo.ReadOnly:=false;
  SettingsBtn.Enabled:=true;

  //Стандарт модульных программ / Standard modular program
  if Assigned(SyncList) then
    Timer.Enabled:=true;

  Download.Free;
  GetRss.Free;
  Downloaded.Free;
  RegExp.Free;
end;

procedure TMain.FormCreate(Sender: TObject);
var
  Ini: TIniFile;
begin
  //RefreshBtn.ControlState:=[csFocusing];
  DownloadPodcasts:=true;

  Ini:=TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'Setup.ini');
  DownloadPath:=Ini.ReadString('Main', 'Path', '');
  if Trim(DownloadPath) = '' then
    DownloadPath:=GetEnvironmentVariable('USERPROFILE') + '\Desktop\';
  ModuleWndID:=Ini.ReadString('Main', 'ModuleWndID', '');
  Ini.Free;

  Application.Title:=Caption;

  if FileExists(ExtractFilePath(ParamStr(0)) + 'RSS.txt') then
    RssListMemo.Lines.LoadFromFile(ExtractFilePath(ParamStr(0)) + 'RSS.txt');
  RssChanged:=false;

  //Перевод / Translate
  if FileExists(ExtractFilePath(ParamStr(0)) + 'Languages\' + GetLocaleInformation(LOCALE_SENGLANGUAGE) + '.ini') then
    LangFile:=GetLocaleInformation(LOCALE_SENGLANGUAGE) + '.ini'
  else
    LangFile:='English.ini';

  Ini:=TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'Languages\' + LangFile);

  RefreshBtn.Caption:=Ini.ReadString('Main', 'ID_REFRESH', '');
  OpenFolderBtn.Caption:=Ini.ReadString('Main', 'ID_DOWNLOADS', '');

  ID_NEW_FEED_QUESTION:=Ini.ReadString('Main', 'ID_NEW_FEED_QUESTION', '');
  ID_CHECK_FEED:=Ini.ReadString('Main', 'ID_CHECK_FEED', '');
  ID_NEW_PODCAST:=Ini.ReadString('Main', 'ID_NEW_PODCAST', '');
  ID_DOWNLOAD_PODCASTS:=Ini.ReadString('Main', 'ID_DOWNLOAD_PODCASTS', '');
  ID_PODCASTS_DOWNLOADED:=Ini.ReadString('Main', 'ID_PODCASTS_DOWNLOADED', '');
  ID_PODCASTS_SKIPPED:=Ini.ReadString('Main', 'ID_PODCASTS_SKIPPED', '');
  ID_PODCASTS_NOT_FOUND:=Ini.ReadString('Main', 'ID_PODCASTS_NOT_FOUND', '');
  ID_DOWNLOAD_ERROR:=Ini.ReadString('Main', 'ID_DOWNLOAD_ERROR', '');

  ID_ABOUT_TITLE:=Ini.ReadString('Main', 'ID_ABOUT_TITLE', '');
  ID_LAST_UPDATE:=Ini.ReadString('Main', 'ID_LAST_UPDATE', '');

  ID_STAGE_1:=Ini.ReadString('Main', 'ID_STAGE_1', '');
  ID_STAGE_2:=Ini.ReadString('Main', 'ID_STAGE_2', '');
  ID_REMOVED_LINKS:=Ini.ReadString('Main', 'ID_REMOVED_LINKS', '');
  ID_FAILED_GET_RSS:=StringReplace(Ini.ReadString('Main', 'ID_FAILED_GET_RSS', ''), '\n', #13#10, [rfReplaceAll]);

  ID_UPLOADED_PODCASTS_TO_DEVICE:=Ini.ReadString('Main', 'ID_UPLOADED_PODCASTS_TO_DEVICE', '');
  Ini.Free;
end;

procedure TMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if RssChanged then
    RssListMemo.Lines.SaveToFile(ExtractFilePath(ParamStr(0)) + 'RSS.txt');
  if Assigned(SyncList) then
    SyncList.Free;
end;

procedure TMain.OpenFolderBtnClick(Sender: TObject);
begin
  ShellExecute(Handle, nil, PChar(DownloadPath), nil, nil, SW_SHOWNORMAL);
end;

procedure TMain.WMCopyData(var Msg: TWMCopyData);
var
  i: integer;
begin
  if (Assigned(SyncList)) and (PChar(TWMCopyData(msg).CopyDataStruct.lpData) = 'YES') and
  (SyncList.Count > 0) and (hTargetWnd <> 0) then
    SendMessageToHandle(hTargetWnd, SyncList.Text);

  if PChar(TWMCopyData(Msg).CopyDataStruct.lpData) = 'GOOD' then begin
    SyncList.Delete(0);
    for i:=0 to SyncList.Count - 1 do
      if FileExists(SyncList.Strings[i]) then
        DeleteFile(SyncList.Strings[i]);
    FreeAndNil(SyncList);
    StatusBar.SimpleText:=' ' + ID_UPLOADED_PODCASTS_TO_DEVICE;
  end;
  //SendMessageToHandle(Msg.From, 'YES');
  Msg.Result:=Integer(True);
end;

procedure TMain.TimerTimer(Sender: TObject);
begin
  //Стадарт модульных программ / Standard modular program
  hTargetWnd:=FindWindowExtd(ModuleWndID);
  if hTargetWnd <> 0 then begin
    SendMessageToHandle(hTargetWnd, 'WORK');
    Timer.Enabled:=false;
  end;
end;

procedure TMain.StatusBarClick(Sender: TObject);
begin
  Application.MessageBox(PChar(Caption + ' 0.9.5' + #13#10 +
  ID_LAST_UPDATE + ' 07.01.2018' + #13#10 +
  'https://r57zone.github.io' + #13#10 +
  'r57zone@gmail.com'), PChar(ID_ABOUT_TITLE), MB_ICONINFORMATION);
end;

procedure TMain.CheckDownloadedLinks;
var
  i, j: integer;
  Downloaded, Links: TStringList; Source: string;
  Error: boolean;
begin
  Settings.ProgressBar.Visible:=true;
  RssListMemo.Visible:=false;
  RefreshBtn.Enabled:=false;
  Error:=false;
  Downloaded:=TStringList.Create;
  Links:=TStringList.Create;
  Downloaded.LoadFromFile('Downloaded.txt');
  Settings.StatusLbl.Caption:=' ' + ID_STAGE_1;
  Settings.ProgressBar.Max:=RSSListMemo.Lines.Count - 1;
  //Создание общего списка / Creating a common list
  for i:=RssListMemo.Lines.Count - 1 downto 0 do begin
    if Trim(RssListMemo.Lines.Strings[i]) = '' then Continue;
    if CheckUrl(RssListMemo.Lines.Strings[i]) = false then begin
      Error:=true;
      break;
    end;
    Source:=Source + #13#10 + HTTPGet(RssListMemo.Lines.Strings[i]);
    Application.ProcessMessages;
    Settings.ProgressBar.Position:=RssListMemo.Lines.Count - 1 - i;
  end;
  Settings.ProgressBar.Position:=0;
  if Error = false then begin
    Settings.StatusLbl.Caption:=' ' + ID_STAGE_2;
    Settings.ProgressBar.Max:=Downloaded.Count - 1;
    //Создание нового списка загруженных подкастов /Create a new list of downloaded podcasts
    for j:=Downloaded.Count - 1 downto 0 do begin
      if Pos(Downloaded.Strings[j], Source) > 0 then Links.Add(Downloaded.Strings[j]);
      Application.ProcessMessages;
      Settings.ProgressBar.Position:=Downloaded.Count - 1 - j;
    end;
    //Сортировка / Sort
    Links.Sort;
    Links.SaveToFile('Downloaded.txt');

    Application.MessageBox(PChar(ID_REMOVED_LINKS + ' ' + IntToStr(Downloaded.Count - Links.Count)), PChar(Caption), MB_ICONINFORMATION);
  end else
    Application.MessageBox(PChar(Format(ID_FAILED_GET_RSS, [RSSListMemo.Lines.Strings[i]])), PChar(Caption), MB_ICONWARNING);
  Settings.StatusLbl.Caption:='';
  Downloaded.Free;
  Links.Free;
  Settings.ProgressBar.Position:=0;
  Settings.ProgressBar.Visible:=false;
  RssListMemo.Visible:=true;
  RefreshBtn.Enabled:=true;
end;

procedure TMain.RSSListMemoChange(Sender: TObject);
begin
  RssChanged:=true;
end;

procedure TMain.SettingsBtnClick(Sender: TObject);
begin
  Settings.ShowModal;
end;

end.
