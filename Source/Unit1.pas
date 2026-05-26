unit Unit1;

// Podcast Easy by r57zone
// https://github.com/r57zone/PodcastEasy

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, WinInet, XPMan, ComCtrls, IniFiles, ShellAPI, ExtCtrls,
  Buttons, RegExpr, UrlMon, ShlObj;

type
  TMain = class(TForm)
    RefreshBtn: TButton;
    RSSListMemo: TMemo;
    StatusBar: TStatusBar;
    XPManifest: TXPManifest;
    OpenFolderBtn: TButton;
    SettingsBtn: TBitBtn;
    CancelBtn: TButton;
    procedure RefreshBtnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure OpenFolderBtnClick(Sender: TObject);
    procedure CheckDownloadedLinks;
    procedure RSSListMemoChange(Sender: TObject);
    procedure RSSListMemoKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure SettingsBtnClick(Sender: TObject);
    procedure CancelBtnClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Main: TMain;
  AppFilePath, DownloadPath, LangFileName: string;
  ProxyAddress, ProxyPort: string;
  StopDownload, DownloadPodcasts, RSSChanged: boolean;

  //Перевод / Translate
  //Main
  IDS_NEW_FEED_QUESTION, IDS_CHECK_FEED: string;
  IDS_NEW_PODCAST, IDS_DOWNLOAD_PODCASTS, IDS_PODCASTS_DOWNLOADED, IDS_PODCASTS_SKIPPED, IDS_PODCASTS_NOT_FOUND: string;
  IDS_DOWNLOAD_ERROR: string;
  //About
  IDS_ABOUT_TITLE, IDS_LAST_UPDATE: string;
  //Remove links
  IDS_STAGE_1, IDS_STAGE_2, IDS_REMOVED_LINKS, IDS_FAILED_GET_RSS: string;

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

function GetUserDefaultUILanguage: LANGID; stdcall; external 'kernel32.dll';

function GetLocaleInformation(Flag: integer): string; // If there are multiple languages in the system (with sorting) / Если в системе несколько языков (с сортировкой)
var
  pcLCA: array [0..63] of Char;
begin
  if GetLocaleInfo((DWORD(SORT_DEFAULT) shl 16) or Word(GetUserDefaultUILanguage), Flag, pcLCA, Length(pcLCA)) <= 0 then
    pcLCA[0]:=#0;
  Result:=pcLCA;
end;

function HTTPCheck(const URL: string): boolean;
var
  hSession, hUrl: HINTERNET;
  dwIndex, dwCodeLen, dwFlags: DWORD;
  dwCode: array [1..20] of Char;
begin
  Result:=false;
  hSession:=InternetOpen('Mozilla/5.0 (Windows NT 10.0; Trident/7.0; rv:11.0) like Gecko)', INTERNET_OPEN_TYPE_PRECONFIG, nil, nil, 0);
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
  Buffer: array [1..8192] of Byte;
  dwFlags, BufferLen: DWORD;
  StrStream: TStringStream;
begin
  Result:='';
  hSession:=InternetOpen('Mozilla/5.0 (Windows NT 10.0; Trident/7.0; rv:11.0) like Gecko)', INTERNET_OPEN_TYPE_PRECONFIG, nil, nil, 0);
  if Assigned(hSession) then begin

  dwFlags:=INTERNET_FLAG_RELOAD or INTERNET_FLAG_NO_CACHE_WRITE;
  if Copy(LowerCase(URL), 1, 8) = 'https://' then
    dwFlags:=dwFlags or INTERNET_FLAG_SECURE;

    hUrl:=InternetOpenUrl(hSession, PChar(URL), nil, 0, dwFlags, 0);
    if Assigned(hUrl) then begin
      StrStream:=TStringStream.Create('');
      try
        try
          repeat
            FillChar(Buffer, SizeOf(Buffer), 0);
            BufferLen:=0;
            if InternetReadFile(hURL, @Buffer, SizeOf(Buffer), BufferLen) then
              StrStream.WriteBuffer(Buffer, BufferLen)
            else
              Break;
            Application.ProcessMessages;
          until BufferLen = 0;
          Result:=StrStream.DataString;
        except
          Result:='';
        end;
      finally
        StrStream.Free;
      end;

      InternetCloseHandle(hUrl);
    end;

    InternetCloseHandle(hSession);
  end;
end;

function HTTPGetSize(const URL: string): int64;
var
  hSession, hFile: HINTERNET;
  dwBuffer: array[1..20] of Char;
  dwIndex, dwBufferLen, dwFlags: DWORD;
begin
  Result:=0;
  hSession:=InternetOpen('Mozilla/5.0 (Windows NT 10.0; Trident/7.0; rv:11.0) like Gecko)', INTERNET_OPEN_TYPE_PRECONFIG, nil, nil, 0);
  if Assigned(hSession) then begin

    dwFlags:=INTERNET_FLAG_RELOAD or INTERNET_FLAG_NO_CACHE_WRITE;
    if Copy(LowerCase(URL), 1, 8) = 'https://' then
      dwFlags:=dwFlags or INTERNET_FLAG_SECURE;

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
  //Result:=(Int64(FoundData.FindData.nFileSizeHigh) * MAXDWORD) + Int64(FoundData.FindData.nFileSizeLow);
  Result:=(int64(FoundData.FindData.nFileSizeHigh) shl 32) or int64(FoundData.FindData.nFileSizeLow);
  FindClose(FoundData);
end;

function HTTPDownloadFile(const URL, Path: string; out DownloadedFileName: string; DownloadIndex, DownloadCount: integer): boolean;
var
  hSession, hFile: HINTERNET;
  Buffer: array[1..8192] of Byte;
  BufferLen: DWORD;
  F: file;
  FileSize, FileExistsCounter: int64;
  CopySize: int64;
  DownloadPercent, LastDownloadPercent: integer;
begin
  FileSize:=HTTPGetSize(URL); // Получаем размер файла / Get file size

  hSession:=InternetOpen('Mozilla/5.0 (Windows NT 10.0; Trident/7.0; rv:11.0) like Gecko)', INTERNET_OPEN_TYPE_PRECONFIG, nil, nil, 0);
  if Assigned(hSession) then begin

    hFile:=InternetOpenURL(hSession, PChar(URL), nil, 0, 0, 0);
    if Assigned(hFile) then begin

      try
        DownloadedFileName:=ExtractFileName(StringReplace(URL, '/', '\', [rfReplaceAll]));
        if not FileExists(Path + DownloadedFileName) then
          AssignFile(F, Path + DownloadedFileName)
        else begin
          FileExistsCounter:=1;
          while true do begin
            DownloadedFileName:=ExtractFileName(StringReplace(Copy(URL, 1, Length(URL) - 4), '/', '\', [rfReplaceAll])) + '(' + IntToStr(FileExistsCounter) + ')' + ExtractFileExt(URL);
            if not FileExists(Path + DownloadedFileName) then begin
              AssignFile(F, Path + DownloadedFileName);
              Break;
            end;
            Inc(FileExistsCounter);
          end;
        end;
        ReWrite(F, 1);
        DownloadPercent:=0;
        LastDownloadPercent:=-1;
        repeat
          if InternetReadFile(hFile, @Buffer, SizeOf(Buffer), BufferLen) then begin
            BlockWrite(F, Buffer, BufferLen);
            CopySize:=CopySize + SizeOf(Buffer);
            DownloadPercent:=Round( CopySize / (FileSize / 100) );
            if LastDownloadPercent <> DownloadPercent then begin
              Main.StatusBar.SimpleText:=' ' + Format(IDS_DOWNLOAD_PODCASTS, [DownloadIndex, DownloadCount, DownloadPercent]);
              LastDownloadPercent:=DownloadPercent;
            end;
            if StopDownload then // По запросу останавливаем загрузку / Stop download on request
              break;
          end else
            Break;
          Application.ProcessMessages;
        until BufferLen = 0;
        CloseFile(F);
      except
      end;

      InternetCloseHandle(hFile);
    end;

    InternetCloseHandle(hSession);
  end;

  // Проверка на целостность файла / Checking file size
  if (FileSize <= 0) or (FileSize = GetFileSize(Path + DownloadedFileName)) then
    Result:=true
  else begin
    // Удаляем неполный файл / Delete the incomplete file
    DeleteFile(Path + DownloadedFileName);
    Result:=false;
  end
end;

procedure TMain.RefreshBtnClick(Sender: TObject);
const
  PodcastExt = 'mp3|aac|ogg|mp4';
var
  RegExp: TRegExpr;
  GetRSS, Downloaded, Download: TStringList;
  i, j, ErrorCount, DownloadCount, DownloadIndex: integer;
  Error: boolean;
  DownloadedFileName: string;
begin
  // Пропуск загрузки новых подкастов для новой ленты / Skip download new podcasts for new feed
  if RSSChanged then
    case MessageBox(Handle, PChar(StringReplace(IDS_NEW_FEED_QUESTION, '\n', #13#10, [rfReplaceAll])), PChar(Caption), MB_YESNO + MB_ICONQUESTION) of
      6: DownloadPodcasts:=false;
      7: DownloadPodcasts:=true;
    end;

  RegExp:=TRegExpr.Create;
  RegExp.ModifierG:=false; // Не жадный режим / None greedy mode
  Error:=false; // Ошибка загрузки файлов / Error downloaded files
  ErrorCount:=0; // Счетчик неполных файлов / Counter incomplete files
  DownloadCount:=0; // Счетчик файлов на загрузку / Counter files to download
  GetRSS:=TStringList.Create; // Лента / RSS
  Downloaded:=TStringList.Create; // Список ссылок загруженных подкастов / List of links downloaded podcasts
  Download:=TStringList.Create;
  StopDownload:=false; // Дать возможность завершить загрузку / Allow abort download
  // Отключение кнопок / Disable buttons
  RefreshBtn.Enabled:=false;
  RSSListMemo.ReadOnly:=true;
  SettingsBtn.Enabled:=false;
  Application.ProcessMessages; // Мгновенное отключение кнопок / Instant disable buttons

  if FileExists(ExtractFilePath(ParamStr(0)) + 'Downloaded.txt') then
    Downloaded.LoadFromFile(ExtractFilePath(ParamStr(0)) + 'Downloaded.txt');

  // Проверка лент на новые подкасты / Check feed for new podcasts
  for i:=0 to RSSListMemo.Lines.Count - 1 do begin

    if Trim(RSSListMemo.Lines.Strings[i]) = '' then
      Continue;

    GetRSS.Text:=HTTPGet(RSSListMemo.Lines.Strings[i]);

    StatusBar.SimpleText:=' ' + Format(IDS_CHECK_FEED, [i + 1, RSSListMemo.Lines.Count]);
    if Trim(GetRSS.Text) = '' then
      Continue;

    // Atom, устаревший стандарт / old standard
    RegExp.Expression:='(?i)<content.*src="(.*(' + PodcastExt + '))"';

    try
      if RegExp.Exec(GetRSS.Text) then
        repeat
          if (Pos(RegExp.Match[1], Download.Text) = 0) and // Проверяем добавлялась ли ссылка в список загрузки / Checking if the link was added to the download list
          (Pos(RegExp.Match[1], Downloaded.Text) = 0) and  // Проверяем была ли загружена ссылка ранее / Checking if the link was previously downloaded
          (HTTPCheck(RegExp.Match[1])) then begin
            StatusBar.SimpleText:=' ' + IDS_NEW_PODCAST + ' ' + Copy(RSSListMemo.Lines.Strings[i], 1, 20) + '...';

            // Добавление ссылки в список для загрузки / Add link to download list
            Download.Add(RegExp.Match[1]);
          end;
        until not RegExp.ExecNext;
    except
    end;

    // RSS 2.0
    RegExp.Expression:='(?i)<enclosure.*url="(.*(' + PodcastExt + '))"';

    try
      if RegExp.Exec(GetRSS.Text) then
        repeat
          if (Pos(RegExp.Match[1], Download.Text) = 0) and // Проверяем добавлялась ли ссылка в список загрузки / Checking if the link was added to the download list
          (Pos(RegExp.Match[1], Downloaded.Text) = 0) and  // Проверяем была ли загружена ссылка ранее / Checking if the link was previously downloaded
          (HTTPCheck(RegExp.Match[1])) then begin
            StatusBar.SimpleText:=' ' + IDS_NEW_PODCAST + ' ' + Copy(RSSListMemo.Lines.Strings[i], 1, 20) + '...';

            // Добавление ссылки в список для загрузки / Add link to download list
            Download.Add(RegExp.Match[1]);
          end;
        until not RegExp.ExecNext;
    except
    end;

  end;

  //RefreshBtn.Visible:=false;
  CancelBtn.Visible:=true;
  Main.Refresh;

  // Загрузка файлов / Download files
  if Download.Count > 0 then begin

    DownloadCount:=Download.Count;
    DownloadIndex:=0;

    for i:=Download.Count - 1 downto 0 do begin
      Inc(DownloadIndex);

      if DownloadPodcasts then // Разрешение на загрузку / Permission to download
        if HTTPDownloadFile(Download.Strings[i], DownloadPath, DownloadedFileName, DownloadIndex, DownloadCount) = false then begin //В случае ошибки / If error
          Download.Delete(i); // Удаляем из списка на сохранение файл, который не загрузился целиком / Remove from list to save the file, which is not fully downloaded
          Error:=true;
          Inc(ErrorCount);
        end;
    end;

    if Error = false then begin

      if DownloadPodcasts then
        StatusBar.SimpleText:=' ' + IDS_PODCASTS_DOWNLOADED  // Все подкасты загружены // All Podcasts downloaded
      else
        StatusBar.SimpleText:=' ' + IDS_PODCASTS_SKIPPED;  // Все подкасты пропущены // All Podcasts skipped

    end else
      StatusBar.SimpleText:=' ' + Format(IDS_DOWNLOAD_ERROR, [DownloadCount - ErrorCount, DownloadCount]); // Ошибка загрузки / Download error

    // Сохранение ссылок на загруженные подкасты, чтобы не загружать их снова / Save links to downloaded podcasts to not download them again
    Downloaded.Add(Download.Text);

    // Удаляем пустые строки / Remove the blank lines
    for i:=Downloaded.Count - 1 downto 0 do
      if Length(Trim(Downloaded.Strings[i])) = 0 then Downloaded.Delete(i);
    // Сохранение списка загруженных подкастов / Save list of podcasts downloaded links
    Downloaded.SaveToFile(ExtractFilePath(ParamStr(0)) + 'Downloaded.txt');

  end else StatusBar.SimpleText:=' ' + IDS_PODCASTS_NOT_FOUND; // Новых подкастов не найдено / Not found new podcasts

  RefreshBtn.Visible:=true;
  CancelBtn.Visible:=false;

  //Включение кнопок / Enable buttons
  RefreshBtn.Enabled:=true;
  RSSListMemo.ReadOnly:=false;
  SettingsBtn.Enabled:=true;

  RefreshBtn.Refresh;
  OpenFolderBtn.Refresh;

  Download.Free;
  GetRSS.Free;
  Downloaded.Free;
  RegExp.Free;
end;

procedure ProxyInit(ProxyAddress, ProxyPort: string);
var
  PIInfo: PInternetProxyInfo;
begin
  New(PIInfo);
  PIInfo^.dwAccessType:=INTERNET_OPEN_TYPE_PROXY;
  PIInfo^.lpszProxy:=PChar(ProxyAddress + ':' + ProxyPort);
  PIInfo^.lpszProxyBypass:=PChar('');
  UrlMkSetSessionOption(INTERNET_OPTION_PROXY, PIInfo, SizeOf(Internet_Proxy_Info), 0);
  Dispose(PIInfo);
end;

function GetDesktopPath: string;
var
  Path: array[0..MAX_PATH] of Char;
begin
  SHGetSpecialFolderPath(0, Path, CSIDL_DESKTOPDIRECTORY, False);
  Result := StrPas(Path);
end;

procedure TMain.FormCreate(Sender: TObject);
var
  Ini: TIniFile;
  SystemLang, ForceLangFile: string;
  i: integer;
begin
  //RefreshBtn.ControlState:=[csFocusing];
  DownloadPodcasts:=true;

  Ini:=TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'Setup.ini');
  DownloadPath:=Ini.ReadString('Main', 'Path', '');
  if Trim(DownloadPath) = '' then DownloadPath:=GetDesktopPath + '\';
  ProxyAddress:=Ini.ReadString('Proxy', 'Address', '');
  ProxyPort:=Ini.ReadString('Proxy', 'Port', '');
  Ini.Free;

  if (ProxyAddress <> '') and (ProxyPort <> '') then
    ProxyInit(ProxyAddress, ProxyPort);

  Application.Title:=Caption;
  AppFilePath:=ExtractFilePath(ParamStr(0));

  if FileExists(AppFilePath + 'RSS.txt') then
    RSSListMemo.Lines.LoadFromFile(AppFilePath + 'RSS.txt');
  RSSChanged:=false;

  for i:=1 to ParamCount do
    if ParamStr(i) = '-lang' then
      ForceLangFile:=ParamStr(i + 1);

  // Перевод / Translate
  SystemLang:=GetLocaleInformation(LOCALE_SENGLANGUAGE);
  if Pos('Chinese', SystemLang) > 0  then begin
    if Pos('Traditional', SystemLang) > 0 then
      SystemLang:='Chinese (Traditional)'
    else
      SystemLang:='Chinese (Simplified)';
  end else if Pos('Spanish', SystemLang) > 0 then
    SystemLang:='Spanish'
  else if Pos('Portuguese', SystemLang) > 0 then
    SystemLang:='Portuguese';

  if ForceLangFile <> '' then SystemLang:=ForceLangFile;
  LangFileName:=SystemLang + '.ini';

  if not FileExists(AppFilePath + 'Languages\' + LangFileName) then
    LangFileName:='English.Ini';
  Ini:=TIniFile.Create(AppFilePath + 'Languages\' + LangFileName);

  RefreshBtn.Caption:=Ini.ReadString('Main', 'REFRESH', 'Refresh');
  CancelBtn.Caption:=Ini.ReadString('Main', 'CANCEL', 'Cancel');
  OpenFolderBtn.Caption:=Ini.ReadString('Main', 'DOWNLOADS', 'Downloads');

  IDS_NEW_FEED_QUESTION:=Ini.ReadString('Main', 'NEW_FEED_QUESTION', 'After adding a new feed is recommended to\nskip downloading all new podcasts.\n\nSkip the download podcasts (Yes) or\ndownload all podcasts of new feed (No)?');
  IDS_CHECK_FEED:=Ini.ReadString('Main', 'CHECK_FEED', 'Checking news feeds: %d of %d');
  IDS_NEW_PODCAST:=Ini.ReadString('Main', 'NEW_PODCAST', 'Found new podcast on');
  IDS_DOWNLOAD_PODCASTS:=Ini.ReadString('Main', 'DOWNLOAD_PODCASTS', 'Downloading podcasts: %d of %d, current %d%%');
  IDS_PODCASTS_DOWNLOADED:=Ini.ReadString('Main', 'PODCASTS_DOWNLOADED', 'All podcasts downloaded');
  IDS_PODCASTS_SKIPPED:=Ini.ReadString('Main', 'PODCASTS_SKIPPED', 'All podcasts skipped');
  IDS_PODCASTS_NOT_FOUND:=Ini.ReadString('Main', 'PODCASTS_NOT_FOUND', 'New podcasts not found');
  IDS_DOWNLOAD_ERROR:=Ini.ReadString('Main', 'DOWNLOAD_ERROR', 'Download error, downloaded podcasts: %d of %d');

  IDS_ABOUT_TITLE:=Ini.ReadString('About', 'ABOUT_TITLE', 'About...');
  IDS_LAST_UPDATE:=Ini.ReadString('About', 'LAST_UPDATE', 'Last update:');

  IDS_STAGE_1:=Ini.ReadString('Main', 'STAGE_1', 'Preparing the common list');
  IDS_STAGE_2:=Ini.ReadString('Main', 'STAGE_2', 'Checking links in list');
  IDS_REMOVED_LINKS:=Ini.ReadString('Main', 'REMOVED_LINKS', 'Removed outdated links: ');
  IDS_FAILED_GET_RSS:=StringReplace(Ini.ReadString('Main', 'FAILED_GET_RSS', 'Error, feed "%s" not available.\nIf it ceased to exist, then simply remove it and try again.'), '\n', #13#10, [rfReplaceAll]);

  Ini.Free;
end;

procedure TMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if RSSChanged then
    RSSListMemo.Lines.SaveToFile(AppFilePath + 'RSS.txt');
end;

procedure TMain.OpenFolderBtnClick(Sender: TObject);
begin
  ShellExecute(Handle, nil, PChar(DownloadPath), nil, nil, SW_SHOWNORMAL);
end;

procedure TMain.CheckDownloadedLinks;
var
  i, j: integer;
  Downloaded, Links: TStringList; Source: string;
  Error: boolean;
begin
  Settings.ProgressBar.Visible:=true;
  RSSListMemo.Enabled:=false;
  RefreshBtn.Enabled:=false;
  Error:=false;
  Downloaded:=TStringList.Create;
  Links:=TStringList.Create;
  Downloaded.LoadFromFile('Downloaded.txt');
  Settings.StatusLbl.Caption:=' ' + IDS_STAGE_1;
  Settings.ProgressBar.Max:=RSSListMemo.Lines.Count - 1;
  // Создание общего списка / Creating a common list
  for i:=RSSListMemo.Lines.Count - 1 downto 0 do begin
    if Trim(RSSListMemo.Lines.Strings[i]) = '' then Continue;
    if HTTPCheck(RSSListMemo.Lines.Strings[i]) = false then begin
      Error:=true;
      break;
    end;
    Source:=Source + #13#10 + HTTPGet(RSSListMemo.Lines.Strings[i]);
    Application.ProcessMessages;
    Settings.ProgressBar.Position:=RSSListMemo.Lines.Count - 1 - i;
  end;
  Settings.ProgressBar.Position:=0;
  if Error = false then begin
    Settings.StatusLbl.Caption:=' ' + IDS_STAGE_2;
    Settings.ProgressBar.Max:=Downloaded.Count - 1;
    // Создание нового списка загруженных подкастов /Create a new list of downloaded podcasts
    for j:=Downloaded.Count - 1 downto 0 do begin
      if Pos(Downloaded.Strings[j], Source) > 0 then Links.Add(Downloaded.Strings[j]);
      Application.ProcessMessages;
      Settings.ProgressBar.Position:=Downloaded.Count - 1 - j;
    end;
    // Сортировка / Sort
    Links.Sort;
    Links.SaveToFile('Downloaded.txt');

    Application.MessageBox(PChar(IDS_REMOVED_LINKS + ' ' + IntToStr(Downloaded.Count - Links.Count)), PChar(Caption), MB_ICONINFORMATION);
  end else
    Application.MessageBox(PChar(Format(IDS_FAILED_GET_RSS, [RSSListMemo.Lines.Strings[i]])), PChar(Caption), MB_ICONWARNING);
  Settings.StatusLbl.Caption:='';
  Downloaded.Free;
  Links.Free;
  Settings.ProgressBar.Position:=0;
  Settings.ProgressBar.Visible:=false;
  RSSListMemo.Enabled:=true;
  RefreshBtn.Enabled:=true;
end;

procedure TMain.RSSListMemoChange(Sender: TObject);
begin
  RSSChanged:=true;
end;

procedure TMain.RSSListMemoKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  // Убираем баг скрытия контролов
  if Key = VK_MENU then
    Key:=0;
end;

procedure TMain.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  // Убираем баг скрытия контролов
  if Key = VK_MENU then
    Key:=0;
end;

procedure TMain.SettingsBtnClick(Sender: TObject);
begin
  Settings.ShowModal;
end;

procedure TMain.CancelBtnClick(Sender: TObject);
begin
  StopDownload:=true;
end;

end.
