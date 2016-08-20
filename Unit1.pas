unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, WinInet, XPMan, ComCtrls, IniFiles, ShellAPI, ExtCtrls,
  Buttons;

type
  TMain = class(TForm)
    RefreshBtn: TButton;
    MemoRssList: TMemo;
    StatusBar1: TStatusBar;
    XPManifest1: TXPManifest;
    OpenFolderBtn: TButton;
    Timer1: TTimer;
    ProgressBar1: TProgressBar;
    SettingsBtn: TSpeedButton;
    procedure RefreshBtnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure OpenFolderBtnClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure StatusBar1Click(Sender: TObject);
    procedure CheckLinksDownloaded;
    procedure MemoRssListChange(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure SettingsBtnClick(Sender: TObject);
  private
    procedure WMCopyData(var Msg: TWMCopyData); message WM_COPYDATA;
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Main: TMain;
  PathDownload, LanguageFile: string;
  SyncList: TStringList;
  hTargetWnd: hWnd;
  DownloadPodcasts, MemoChanged, FirstStart: boolean;

  //Язык / Language
  CheckNewsFeedTitle: string;
  FoundNewPodcastTitle, DownloadPodcastsTitle, PodcastsDownloadedTitle, PodcastsNotFoundTitle: string;
  PodcastsErrorDownloadedTitle: string;

  AboutLastUpdateTitle, AboutCaptionTitle: string;
  Stage1Title, Stage2Title, DeletedLinksTitle, ErrorDeletedLinksTitle, FirstStartTitle: string;

  //StandartModularProgram
  PodcastDownloadedToDeviceTitle: string;

implementation

uses Unit2;

{$R *.dfm}

function GetLocaleInformation(Flag: Integer): string;
var
  pcLCA: array [0..20] of Char;
begin
  if GetLocaleInfo(LOCALE_SYSTEM_DEFAULT, Flag, pcLCA, 19)<=0 then
    pcLCA[0]:=#0;
  Result:=pcLCA;
end;

function CheckUrl(Url: string): boolean;
var
  hSession, hFile, hRequest: hInternet;
  dwIndex, dwCodeLen: dword;
  dwCode: array [1..20] of char;
  res: PChar;
begin
  Result:=false;
  hSession:=InternetOpen('InetURL:/1.0',INTERNET_OPEN_TYPE_PRECONFIG, nil,nil,0);
  if Assigned(hSession) then begin
    if Copy(UpperCase(Url),1,8)='HTTPS://' then hFile:=InternetOpenURL(hSession,PChar(Url),nil,0,INTERNET_FLAG_SECURE,0) else
      hFile:=InternetOpenURL(hSession,PChar(Url),nil,0,INTERNET_FLAG_RELOAD,0);
    dwIndex:=0;
    dwCodeLen:=10;
    HttpQueryInfo(hFile, HTTP_QUERY_STATUS_CODE,@dwCode, dwCodeLen, dwIndex);
    res:=PChar(@dwCode);
    Result:=(res='200') or (res='302');
    if Assigned(hFile) then InternetCloseHandle(hFile);
    InternetCloseHandle(hSession);
  end;
end;

function GetUrl(Url: string): string;
var
  FSession, FConnect ,FRequest: hInternet;
  FHost, FScript, SRequest, Uri: string;
  Ansi: PAnsiChar;
  Buff: array [0..1023] of Char;
  BytesRead: Cardinal;
  Res, Len: DWORD;
  https: boolean;
const
  CRLF=#13#10;
  Header='Content-Type: application/x-www-form-urlencoded' + CRLF;
begin
  https:=false;
  if Copy(UpperCase(Url),1,8)='HTTPS://' then https:=true;
  Result:='';

  if Copy(UpperCase(Url),1,7)='HTTP://' then Delete(Url, 1, 7);
  if Copy(UpperCase(Url),1,8)='HTTPS://' then Delete(Url, 1, 8);

  Uri:=Url;
  Uri:=Copy(Uri,1,Pos('/', Uri)-1);
  FHost:=Uri;
  FScript:=Url;
  Delete(FScript, 1, Pos(FHost, FScript) + Length(FHost));

  FSession:=InternetOpen('DMFR', INTERNET_OPEN_TYPE_PRECONFIG, nil, nil, 0);
  if not Assigned(FSession) then Exit;
  try
    if https then FConnect:=InternetConnect(FSession, PChar(FHost), INTERNET_DEFAULT_HTTPS_PORT, nil,'HTTP/1.0', INTERNET_SERVICE_HTTP, 0, 0) else
      FConnect:=InternetConnect(FSession, PChar(FHost), INTERNET_DEFAULT_HTTP_PORT, nil,'HTTP/1.0', INTERNET_SERVICE_HTTP, 0, 0);
    if not Assigned(FConnect) then Exit;
    try
      Ansi:='text/*';
      if https then FRequest:=HttpOpenRequest(FConnect, 'GET', PChar(FScript), 'HTTP/1.1',nil, @Ansi, INTERNET_FLAG_SECURE, 0) else
        FRequest:=HttpOpenRequest(FConnect, 'GET', PChar(FScript), 'HTTP/1.1',nil, @Ansi, INTERNET_FLAG_RELOAD, 0);
      if not Assigned(FConnect) then Exit;
        try
          if not (HttpAddRequestHeaders(FRequest, Header, Length(Header),HTTP_ADDREQ_FLAG_REPLACE or HTTP_ADDREQ_FLAG_ADD or HTTP_ADDREQ_FLAG_COALESCE_WITH_COMMA)) then Exit;
          Len:=0;
          Res:=0;
          SRequest:=' ';
          HttpQueryInfo(FRequest, HTTP_QUERY_RAW_HEADERS_CRLF or HTTP_QUERY_FLAG_REQUEST_HEADERS, @SRequest[1], Len, Res);
          if Len>0 then begin
            SetLength(SRequest, Len);
            HttpQueryInfo(FRequest, HTTP_QUERY_RAW_HEADERS_CRLF or
            HTTP_QUERY_FLAG_REQUEST_HEADERS, @SRequest[1], Len, Res);
          end;
          if not (HttpSendRequest(FRequest, nil, 0, nil, 0)) then Exit;
          FillChar(Buff, SizeOf(Buff), 0);
          repeat
            Application.ProcessMessages;
            Result:=Result+Buff;
            FillChar(Buff, SizeOf(Buff), 0);
            InternetReadFile(FRequest, @Buff, SizeOf(Buff), BytesRead);
          until BytesRead=0;
        finally
          InternetCloseHandle(FRequest);
        end;
    finally
      InternetCloseHandle(FConnect);
    end;
  finally
    InternetCloseHandle(FSession);
  end;
end;

function GetUrlSize(const URL: string): integer;
var
  hSession, hFile :hInternet;
  dwBuffer: array[1..20] of char;
  dwBufferLen, dwIndex: DWORD;
begin
  Result:=0;
  hSession:=InternetOpen('GetUrlSize',INTERNET_OPEN_TYPE_PRECONFIG,nil,nil,0);
  if Assigned(hSession) then begin
    if Copy(UpperCase(Url),1,8)='HTTPS://' then hFile:=InternetOpenURL(hSession,PChar(URL),nil,0,INTERNET_FLAG_SECURE,0) else
      hFile:=InternetOpenURL(hSession,PChar(URL),nil,0,INTERNET_FLAG_RELOAD,0);
    dwIndex:=0;
    dwBufferLen:=20;
    if HttpQueryInfo(hFile,HTTP_QUERY_CONTENT_LENGTH,@dwBuffer,dwBufferLen,dwIndex) then Result:=StrToInt(StrPas(@dwBuffer));
    if Assigned(hFile) then InternetCloseHandle(hFile);
    InternetCloseHandle(hSession);
  end;
end;

function GetFileSize(const FileName: string): int64;
var
  s: TSearchRec;
begin
   FindFirst(FileName, faAnyFile, s);
   Result:=(int64(s.FindData.nFileSizeHigh)*MAXDWORD)+int64(s.FindData.nFileSizeLow);
   FindClose(s);
end;

function DownloadFile(const FileUrl, Path: string): boolean;
const
  BufferSize=1024;
var
  hSession, hUrl: hInternet;
  Buffer: array[1..BufferSize] of Byte;
  BufferLen: DWord;
  F: File;
  FileSize, FileExistsCounter: int64;
  sAppName, cFileName: string;
begin
  FileSize:=GetUrlSize(FileUrl);
  sAppName:=ExtractFileName(Application.ExeName);
  hSession:=InternetOpen(PChar(sAppName),Internet_Open_Type_Preconfig, nil, nil, 0);
  if not Assigned(hSession) then Result:=false;
  try
    hUrl:=InternetOpenURL(hSession, PChar(FileUrl), nil, 0, 0, 0);
    if not Assigned(hUrl) then Result:=false;
    try
      cFileName:=ExtractFileName(StringReplace(FileUrl, '/', '\', [rfReplaceAll]));
      if not FileExists(Path+cFileName) then begin
        SyncList.Add(Path+cFileName);  //Standard modular program
        AssignFile(F, Path+cFileName);
      end else begin
        FileExistsCounter:=1;
        while true do begin
          cFileName:=ExtractFileName(StringReplace(Copy(FileUrl,1,Length(FileUrl)-4), '/', '\', [rfReplaceAll]))+'('+IntToStr(FileExistsCounter)+')'+ExtractFileExt(FileUrl);
          if not FileExists(Path+cFileName) then begin
            SyncList.Add(Path+cFileName); //Standard modular program
            AssignFile(F, Path+cFileName);
            Break;
          end;
          inc(FileExistsCounter);
        end;
      end;
      Rewrite(F,1);
      repeat
        InternetReadFile(hUrl, @Buffer, SizeOf(Buffer), BufferLen);
        BlockWrite(F, Buffer, BufferLen);
        Application.ProcessMessages;
      until BufferLen=0;
      CloseFile(F);
      Result:=true;
    finally
      InternetCloseHandle(hUrl);
    end;
  finally
    InternetCloseHandle(hSession);
  end;
  //Проверка на целостность файла / Checking file integrity
  if FileSize<>GetFileSize(Path+cFileName) then begin
    //Удаляем неполный файл / Delete the incomplete file
    DeleteFile(Path+cFileName);
    Result:=false;
  end;
end;

//Стандарт модульных программ / Standart modular program - https://github.com/r57zone/Standard-modular-program
//Отправка сообщений модульным программам / Send messages to modular programs
procedure SendMessageToHandle(TRGWND:hWnd; MsgToHandle: string);
var
  CDS: TCopyDataStruct;
begin
  CDS.dwData:=0;
  CDS.cbData:=(Length(MsgToHandle)+1)*Sizeof(char);
  CDS.lpData:=PChar(MsgToHandle);
  SendMessage(TRGWND,WM_COPYDATA, Integer(Application.Handle), Integer(@CDS));
end;

function FindWindowExtd(PartialTitle: string): HWND;
var
  hWndTemp: hWnd;
  iLenText: Integer;
  cTitletemp: array [0..254] of Char;
  sTitleTemp: string;
begin
  hWndTemp:=FindWindow(nil, nil);
  while hWndTemp<>0 do begin
    iLenText:=GetWindowText(hWndTemp, cTitletemp, 255);
    sTitleTemp:=cTitletemp;
    sTitleTemp:=UpperCase(Copy(sTitleTemp, 1, iLenText));
    PartialTitle:=UpperCase(partialTitle);
    if Pos(partialTitle, sTitleTemp)<>0 then
      Break;
    hWndTemp:=GetWindow(hWndTemp, GW_HWNDNEXT);
  end;
  Result:=hWndTemp;
end;

procedure TMain.RefreshBtnClick(Sender: TObject);
var
  GetRss, Downloaded, Download: TStringList;
  i, j, ErrorCount, DownloadCount, DownloadIndex: integer;
  Error: boolean;
  MyLink: string;
begin
  Error:=false; //Ошибка загрузки файлов / Error downloaded files
  ErrorCount:=0; //Счетчик неполных файлов / Counter incomplete files
  DownloadCount:=0; //Счетчик файлов на загрузку / Counter files to download
  GetRss:=TStringList.Create; //Лента / Rss
  Downloaded:=TStringList.Create; //Список ссылок загруженных подкастов / List of links downloaded podcasts
  Download:=TStringList.Create;
  //Отключение кнопок / Disable buttons
  RefreshBtn.Enabled:=false;
  MemoRssList.ReadOnly:=true;
  SettingsBtn.Enabled:=false;

  if FileExists(ExtractFilePath(ParamStr(0))+'Downloaded.txt') then
    Downloaded.LoadFromFile(ExtractFilePath(ParamStr(0))+'Downloaded.txt');

  //Проверка лент на новые подкасты / Check feed for new podcasts
  for i:=0 to MemoRssList.Lines.Count-1 do begin

    GetRss.Text:=GetUrl(MemoRssList.Lines.Strings[i]);

    StatusBar1.SimpleText:=' '+Format(CheckNewsFeedTitle,[i+1, MemoRssList.Lines.Count]);
    if Trim(GetRss.Text)='' then Continue;

    //Перенос тега на новую строку / Move tag to new line
    GetRss.Text:=StringReplace(GetRss.Text,'<enclosure',#13+'<enclosure',[rfReplaceAll]);
    GetRss.Text:=StringReplace(GetRss.Text,'<pubDate>',#13+'<pubDate>',[rfReplaceAll]);
    
    //Костыль для старых лент, например, для "http://pirates.radio-t.com/atom.xml" / Сrutch for old feed, example - "http://pirates.radio-t.com/atom.xml"
    if Pos('<audio src="',GetRss.Text)>0 then GetRss.Text:=StringReplace(GetRss.Text,'<audio src="',#13+'<audio url="',[rfReplaceAll]);

    for j:=0 to GetRss.Count-1 do
      if Pos('.MP3',AnsiUpperCase(GetRss.Strings[j]))>0 then //Ищем строку с ".MP3" / Look for line with ".MP3"

        //Проверям строку на наличие тега "<GUID" / Check line for the presence of tag "<GUID"
        if Pos('<GUID',AnsiUpperCase(GetRss.Strings[j]))=0 then begin

          //Ссылка на mp3 файл / Link to mp3 file
          MyLink:=Copy(GetRss.Strings[j],Pos('URL="',AnsiUpperCase(GetRss.Strings[j]))+5,Pos('.MP3',AnsiUpperCase(GetRss.Strings[j]))-Pos('URL="',AnsiUpperCase(GetRss.Strings[j]))-1);

          if (Copy(UpperCase(MyLink),1,7)='HTTP://') or (Copy(UpperCase(MyLink),1,8)='HTTPS://') then

            //Проверяем ссылку на наличие в ее списке загруженных подкастов и на возмоможность загрузки / Check presence of link on list of downloaded podcasts and the ability to download
            if (Pos(MyLink,Downloaded.Text)=0) and (CheckUrl(MyLink)=true) then

              //Проверяем не добавлена ли она уже в список загрузки / Check if it is added in the download list
              if (Pos(MyLink,Download.Text)=0) then begin
                StatusBar1.SimpleText:=' '+FoundNewPodcastTitle+' '+Copy(MemoRssList.Lines.Strings[i],1,20)+'...';

                //Добавление ссылки в список для загрузки / Add link to download list
                Download.Add(Copy(GetRss.Strings[j],Pos('URL="',AnsiUpperCase(GetRss.Strings[j]))+5,Pos('.MP3',AnsiUpperCase(GetRss.Strings[j]))-Pos('URL="',AnsiUpperCase(GetRss.Strings[j]))-1));
              end;
        end;
  end;

  //Список загрузки / Download list
  if Download.Count>0 then begin
    //Стандарт модульных программ / Standart modular program - https://github.com/r57zone/Standard-modular-program
    SyncList:=TStringList.Create;
    SyncList.Add('FILES TO SYNC');

    DownloadCount:=Download.Count;
    DownloadIndex:=0;

    for i:=Download.Count-1 downto 0 do begin
      inc(DownloadIndex);
      StatusBar1.SimpleText:=' '+Format(DownloadPodcastsTitle,[DownloadIndex, DownloadCount]);

      if DownloadPodcasts then //Разрешение на загрузку / Permission to download
        if DownloadFile(Download.Strings[i],PathDownload)=false then begin //В случае ошибки / If error
          Download.Delete(i); //Удаляем из списка на сохранение файл, который не загрузился целиком / Remove from list to save the file, which is not fully downloaded
          Error:=true;
          inc(ErrorCount);
        end;
      Application.ProcessMessages;
    end;

    if Error=false then
    StatusBar1.SimpleText:=' '+PodcastsDownloadedTitle else  //Все подкасты загружены // All Podcasts donwloaded
    StatusBar1.SimpleText:=' '+Format(PodcastsErrorDownloadedTitle, [Download.Count, DownloadCount]); //Ошибка загрузки / Error downloaded

    //Сохранение ссылок на загруженные подкасты, чтобы не загрузить их снова / Save links to downloaded podcasts to not download them again
    Downloaded.Add(Download.Text);

    //Удаляем пустые строки / Remove the blank lines
    for i:=Downloaded.Count-1 downto 0 do
      if Length(Trim(Downloaded.Strings[i]))=0 then Downloaded.Delete(i);
    //Сохранение списка загруженных подкастов / Save list of podcasts downloaded links  
    Downloaded.SaveToFile(ExtractFilePath(ParamStr(0))+'Downloaded.txt');

  end else StatusBar1.SimpleText:=' '+PodcastsNotFoundTitle; //Новых подкастов не найдено / Not found new podcasts

  //Если редактировались ленты, то сохраняем новый список лент / If edited feeds then save new list feeds
  if MemoChanged then if MemoRssList.Lines.Count>0 then begin
    MemoRssList.Lines.SaveToFile(ExtractFilePath(ParamStr(0))+'Rss.txt');
    MemoChanged:=false;
  end;

  //Включение кнопок / Enable buttons
  RefreshBtn.Enabled:=true;
  MemoRssList.ReadOnly:=false;
  SettingsBtn.Enabled:=true;

  //Стандарт модульных программ / Standard modular program
  Timer1.Enabled:=true;

  Download.Free;
  GetRss.Free;
  Downloaded.Free;
end;

procedure TMain.FormCreate(Sender: TObject);
var
  Ini:TIniFile;
begin
  RefreshBtn.ControlState:=[csFocusing];
  DownloadPodcasts:=true;

  Ini:=TIniFile.Create(ExtractFilePath(ParamStr(0))+'Setup.ini');
  PathDownload:=Ini.ReadString('Main','Path',ExtractFilePath(ParamStr(0)));
  FirstStart:=Ini.ReadBool('Main','FirstStart',false);
  if FirstStart then begin
    Ini.WriteBool('Main','FirstStart',false);
    if FileExists(ExtractFilePath(ParamStr(0))+'Languages\'+GetLocaleInformation(LOCALE_SENGLANGUAGE)+'.ini') then
      Ini.WriteString('Main','LanguageFile',GetLocaleInformation(LOCALE_SENGLANGUAGE)+'.ini');
  end;
  LanguageFile:=Ini.ReadString('Main','LanguageFile','English.ini');
  Ini.Free;

  Application.Title:=Caption;
  MemoChanged:=false;

  if FileExists(ExtractFilePath(ParamStr(0))+'Rss.txt') then
    MemoRssList.Lines.LoadFromFile(ExtractFilePath(ParamStr(0))+'Rss.txt');

  //Язык / Language

  Ini:=TIniFile.Create(ExtractFilePath(ParamStr(0))+'Languages\'+LanguageFile);

  RefreshBtn.Caption:=Ini.ReadString('Main','ButtonRefresh','');
  OpenFolderBtn.Caption:=Ini.ReadString('Main','ButtonOpenFolder','');

  CheckNewsFeedTitle:=Ini.ReadString('Main','CheckNewsFeed','');
  FoundNewPodcastTitle:=Ini.ReadString('Main','FoundNewPodcast','');
  DownloadPodcastsTitle:=Ini.ReadString('Main','DownloadPodcasts','');
  PodcastsDownloadedTitle:=Ini.ReadString('Main','PodcastsDownloaded','');
  PodcastsNotFoundTitle:=Ini.ReadString('Main','PodcastsNotFound','');
  PodcastsErrorDownloadedTitle:=Ini.ReadString('Main','PodcastsErrorDownloaded','');

  AboutLastUpdateTitle:=Ini.ReadString('Main','AboutLastUpdate','');
  AboutCaptionTitle:=Ini.ReadString('Main','AboutLastUpdate','');

  Stage1Title:=Ini.ReadString('Main','Stage1','');
  Stage2Title:=Ini.ReadString('Main','Stage2','');
  DeletedLinksTitle:=Ini.ReadString('Main','DeletedLinks','');
  ErrorDeletedLinksTitle:=StringReplace(Ini.ReadString('Main','ErrorDeletedLinks',''),'<BR>',#13#10,[rfReplaceAll]);

  if FirstStart then
    FirstStartTitle:=StringReplace(Ini.ReadString('Other','FirstStart',''),'<BR>',#13#10,[rfReplaceAll]);

  PodcastDownloadedToDeviceTitle:=Ini.ReadString('Other','PodcastDownloadedToDevice','');
  Ini.Free;
end;

procedure TMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if MemoChanged then if MemoRssList.Lines.Count>0 then MemoRssList.Lines.SaveToFile(ExtractFilePath(ParamStr(0))+'Rss.txt');
  if Assigned(SyncList) then SyncList.Free;
end;

procedure TMain.OpenFolderBtnClick(Sender: TObject);
begin
  ShellExecute(Handle, nil, PChar(PathDownload), nil, nil, SW_SHOWNORMAL);
end;

procedure TMain.WMCopyData(var Msg: TWMCopyData);
var
  i: integer;
begin
  if PChar(TWMCopyData(msg).CopyDataStruct.lpData)='YES' then if Assigned(SyncList) then if (SyncList.Count>0) and (hTargetWnd<>0) then SendMessageToHandle(hTargetWnd,SyncList.Text);
  if PChar(TWMCopyData(msg).CopyDataStruct.lpData)='GOOD' then begin
    SyncList.Delete(0);
    for i:=0 to SyncList.Count-1 do
      if FileExists(SyncList.Strings[i]) then DeleteFile(SyncList.Strings[i]);
    FreeAndNil(SyncList);
    StatusBar1.SimpleText:=' '+PodcastDownloadedToDeviceTitle;
  end;
  //SendMessageToHandle(msg.From,'YES');
  Msg.Result:=Integer(True);
end;

procedure TMain.Timer1Timer(Sender: TObject);
begin
  //Стадарт модульных программ / Standard modular program
  hTargetWnd:=FindWindowExtd('iOS Sync - ');
  if hTargetWnd<>0 then begin
    SendMessageToHandle(hTargetWnd,'WORK');
    Timer1.Enabled:=false;
  end;
end;

procedure TMain.StatusBar1Click(Sender: TObject);
begin
  Application.MessageBox(PChar('PodCast Easy 0.8.1 beta'+#13#10+AboutLastUpdateTitle+' 20.08.2016'+#13#10+'http://r57zone.github.io'+#13#10+'r57zone@gmail.com'),PChar(AboutCaptionTitle),0);
end;

procedure TMain.CheckLinksDownloaded;
var
  i, j: integer;
  Downloaded, Rss, Links: TStringList; Source: string;
  Error: boolean;
begin
  if Settings.Showing then Settings.Close;
  Main.ClientHeight:=108;
  ProgressBar1.Visible:=true;
  MemoRssList.Visible:=false;
  RefreshBtn.Enabled:=false;
  Error:=false;
  Downloaded:=TStringList.Create();
  Rss:=TStringList.Create();
  Links:=TStringList.Create();
  Downloaded.LoadFromFile('Downloaded.txt');
  Rss.LoadFromFile('Rss.txt');
  StatusBar1.SimpleText:=' '+Stage1Title;
  ProgressBar1.Max:=Rss.Count-1;
  //Создание общего списка / Creating a common list
  for i:=Rss.Count-1 downto 0 do begin
    if CheckUrl(Rss.Strings[i])=false then begin Error:=true; break; end;
    Source:=Source+#13#10+GetUrl(Rss.Strings[i]);
    Application.ProcessMessages;
    ProgressBar1.Position:=Rss.Count-1-i;
  end;
  ProgressBar1.Position:=0;
  if Error=false then begin
    StatusBar1.SimpleText:=' '+Stage2Title;
    ProgressBar1.Max:=Downloaded.Count-1;
    //Создание нового списка загруженных подкастов /Create a new list of downloaded podcasts
    for j:=Downloaded.Count-1 downto 0 do begin
      if Pos(Downloaded.Strings[j],Source)>0 then Links.Add(Downloaded.Strings[j]);
      Application.ProcessMessages;
      ProgressBar1.Position:=Downloaded.Count-1-j;
    end;
    //Сортировка / Sort
    Links.Sort;
    Links.SaveToFile('Downloaded.txt');
    Showmessage(DeletedLinksTitle+' '+IntToStr(Downloaded.Count-links.Count));
  end else ShowMessage(Format(ErrorDeletedLinksTitle,[rss.Strings[i]]));
  StatusBar1.SimpleText:='';
  Downloaded.Free;
  Rss.Free;
  Links.Free;
  ProgressBar1.Position:=0;
  ProgressBar1.Visible:=false;
  MemoRssList.Visible:=true;
  RefreshBtn.Enabled:=true;
  Main.ClientHeight:=162;
end;

procedure TMain.MemoRssListChange(Sender: TObject);
begin
  MemoChanged:=true;
end;

procedure TMain.FormShow(Sender: TObject);
begin
  if FirstStart then ShowMessage(FirstStartTitle);
end;

procedure TMain.SettingsBtnClick(Sender: TObject);
begin
  Settings.ShowModal;
end;

end.
