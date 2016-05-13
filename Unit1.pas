unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, WinInet, XPMan, ComCtrls, IniFiles, ShellAPI, ExtCtrls;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Memo1: TMemo;
    StatusBar1: TStatusBar;
    XPManifest1: TXPManifest;
    CheckBox1: TCheckBox;
    Button3: TButton;
    Timer1: TTimer;
    ProgressBar1: TProgressBar;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Button3Click(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure StatusBar1Click(Sender: TObject);
    procedure CheckLinksDownloaded;
  private
    procedure WMCopyData(var Msg: TWMCopyData); message WM_COPYDATA;
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  PathDownload: string;
  SyncList: TStringList;
  hTargetWnd: hWnd;
  ClickStatusBar: integer;

implementation

{$R *.dfm}

function DelHttp(url:string):string;
begin
  if Pos('http://',url) > 0 then Delete(url, 1, 7);
  Result:=Copy(url,1,Pos('/', url)-1);
  if Result='' then Result:=url;
end;

function CheckUrl(url:string):boolean;
var
  hSession, hfile, hRequest: hInternet;
  dwindex, dwcodelen: dword;
  dwcode: array [1..20] of char;
  res: PChar;
begin
  if Pos('http://',LowerCase(url))= 0 then
    url:='http://'+url;
  Result:=false;
  hSession:=InternetOpen('InetURL:/1.0',INTERNET_OPEN_TYPE_PRECONFIG, nil,nil,0);
  if Assigned(hsession) then begin
    hFile:=InternetOpenURL(hsession,PChar(url),nil,0,INTERNET_FLAG_RELOAD,0);
    dwIndex:=0;
    dwCodeLen:=10;
    HttpQueryInfo(hfile, HTTP_QUERY_STATUS_CODE,@dwcode, dwcodeLen, dwIndex);
    res:=PChar(@dwcode);
    result:=(res='200') or (res='302');
    if Assigned(hfile) then
      InternetCloseHandle(hfile);
    InternetCloseHandle(hsession);
  end;
end;

function GetUrl(const URL:string):string;
var
  FSession, FConnect ,FRequest: HINTERNET;
  FHost, FScript, SRequest: string;
  Ansi: PAnsiChar;
  Buff: array [0..1023] of Char;
  BytesRead: Cardinal;
  Res, Len: DWORD;
const
  HTTP_PORT=80;
  CRLF=#13#10;
  Header='Content-Type: application/x-www-form-urlencoded' + CRLF;
begin
  Result:='';
  FHost:=DelHttp(Url);
  FScript:=Url;
  Delete(FScript, 1, Pos(FHost, FScript) + Length(FHost));
  FSession:=InternetOpen('DMFR', INTERNET_OPEN_TYPE_PRECONFIG, nil, nil, 0);
  if not Assigned(FSession) then Exit;
  try
    FConnect := InternetConnect(FSession, PChar(FHost), HTTP_PORT, nil,'HTTP/1.0', INTERNET_SERVICE_HTTP, 0, 0);
    if not Assigned(FConnect) then Exit;
    try
      Ansi:='text/*';
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
            Result:=Result + Buff;
            FillChar(Buff, SizeOf(Buff), 0);
            InternetReadFile(FRequest, @Buff, SizeOf(Buff), BytesRead);
          until BytesRead = 0;
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

function GetInetFile(const FileUrl, Path: string): boolean;
const
  BufferSize=1024;
var
  hSession, hUrl: hInternet;
  Buffer: array[1..buffersize] of byte;
  BufferLen: dword;
  f: File;
  sAppName: string;
  i: integer;
begin
  Result:=false;
  sAppName:=ExtractFileName(Application.ExeName);
  hSession:=InternetOpen(PChar(sAppName),
  Internet_Open_Type_Preconfig, nil, nil, 0);
  try
    hUrl:=InternetOpenURL(hSession, PChar(FileUrl), nil, 0, 0, 0);
    try
      if not FileExists(Path+ExtractFileName(StringReplace(FileUrl, '/', '\', [rfReplaceAll]))) then begin
        SyncList.Add(Path+ExtractFileName(StringReplace(FileUrl, '/', '\', [rfReplaceAll])));  //Standard modular program
        AssignFile(f, Path+ExtractFileName(StringReplace(FileUrl, '/', '\', [rfReplaceAll])))
       end else begin
        for i:=1 to 999999 do
          if not FileExists(Path+ExtractFileName(StringReplace(Copy(FileUrl,1,Length(FileUrl)-4), '/', '\', [rfReplaceAll]))+'('+inttostr(i)+').mp3') then begin
            SyncList.Add(Path+ExtractFileName(StringReplace(Copy(FileUrl,1,Length(FileUrl)-4), '/', '\', [rfReplaceAll]))+'('+inttostr(i)+').mp3'); //Standard modular program
            AssignFile(f, Path+ExtractFileName(StringReplace(Copy(FileUrl,1,Length(FileUrl)-4), '/', '\', [rfReplaceAll]))+'('+inttostr(i)+').mp3');
            break;
          end;
        end;
      Rewrite(f,1);
      repeat
        InternetReadFile(hurl, @buffer, sizeof(buffer), bufferlen);
        BlockWrite(f, buffer, bufferlen);
        Application.ProcessMessages;
      until
        BufferLen=0;
        CloseFile(F);
        Result:=true;
    finally
      InternetCloseHandle(hurl);
    end;
  finally
    InternetCloseHandle(hsession);
  end;
end;

procedure SendMessageToHandle(TRGWND:hWnd; MsgToHandle: string);
var
  CDS: TCopyDataStruct;
begin
  CDS.dwData:=0;
  CDS.cbData:=(Length(MsgToHandle)+ 1)*Sizeof(char);
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

procedure TForm1.Button1Click(Sender: TObject);
var
GetRss, Downloaded, Download: TStringList; i ,j ,n ,d: integer;
begin
  GetRss:=TStringList.Create;
  Downloaded:=TStringList.Create;
  Download:=TStringList.Create;
  Button1.Enabled:=false;
  Checkbox1.Enabled:=false;
  Memo1.ReadOnly:=true;
  if FileExists(ExtractFilePath(ParamStr(0))+'downloaded.txt') then
    Downloaded.LoadFromFile(ExtractFilePath(ParamStr(0))+'downloaded.txt');
  for i:=0 to Memo1.Lines.Count-1 do begin
    GetRss.Text:=GetUrl(Memo1.Lines.Strings[i]);
    GetRss.Text:=StringReplace(GetRss.Text,'<enclosure',#13+'<enclosure',[rfReplaceAll]);
    GetRss.Text:=StringReplace(GetRss.Text,'<pubDate>',#13+'<pubDate>',[rfReplaceAll]);
    if Pos('<audio src="',GetRss.Text)>0 then GetRss.Text:=StringReplace(GetRss.Text,'<audio src="',#13+'<audio url="',[rfReplaceAll]);
    StatusBar1.SimpleText:=' Проверка новостных лент : '+IntToStr(i+1)+' из '+IntToStr(Memo1.Lines.Count);
    if Trim(GetRss.Text)='' then Continue;
    for j:=0 to GetRss.Count-1 do
      if Pos('.MP3',AnsiUpperCase(GetRss.Strings[j]))>0 then
        if (Pos(Copy(GetRss.Strings[j],Pos('URL="',AnsiUpperCase(GetRss.Strings[j]))+5,Pos('.MP3',AnsiUpperCase(GetRss.Strings[j]))-Pos('URL="',AnsiUpperCase(GetRss.Strings[j]))-1),Downloaded.Text)=0) and (Pos('<GUID',AnsiUpperCase(GetRss.Strings[j]))=0) and
        (CheckUrl(Copy(GetRss.Strings[j],Pos('URL="',AnsiUpperCase(GetRss.Strings[j]))+5,Pos('.MP3',AnsiUpperCase(GetRss.Strings[j]))-Pos('URL="',AnsiUpperCase(GetRss.Strings[j]))-1))=true) then
          if (Pos(Copy(GetRss.Strings[j],Pos('URL="',AnsiUpperCase(GetRss.Strings[j]))+5,Pos('.MP3',AnsiUpperCase(GetRss.Strings[j]))-Pos('URL="',AnsiUpperCase(GetRss.Strings[j]))-1),Download.Text)=0) then begin
            StatusBar1.SimpleText:=' Найден новый подкаст на '+Copy(Memo1.Lines.Strings[i],1,20)+'...';
            Download.Add(Copy(GetRss.Strings[j],Pos('URL="',AnsiUpperCase(GetRss.Strings[j]))+5,Pos('.MP3',AnsiUpperCase(GetRss.Strings[j]))-Pos('URL="',AnsiUpperCase(GetRss.Strings[j]))-1));
          end;
  end;

  if Download.Count>0 then begin
  //Standard modular program
  SyncList:=TStringList.Create;
  SyncList.Add('FILES TO SYNC');
  //end Smp
  for i:=0 to Download.Count-1 do begin
    StatusBar1.SimpleText:=' Загрузка подкастов : '+IntToStr(i)+' из '+IntToStr(Download.Count);
    if CheckBox1.Checked then getinetfile(Download.Strings[i],PathDownload);
    Application.ProcessMessages;
  end;
  StatusBar1.SimpleText:=' Все подкасты загружены';
  Downloaded.Add(Download.Text);

  for d:=Downloaded.Count-1 downto 0 do
    if Length(Trim(Downloaded.Strings[d]))=0 then Downloaded.Delete(d);
  Downloaded.SaveToFile(ExtractFilePath(ParamStr(0))+'downloaded.txt');

  end else StatusBar1.SimpleText:=' Новых подкастов не найдено';

  if Memo1.Lines.Count>0 then
    Memo1.Lines.SaveToFile(ExtractFilePath(ParamStr(0))+'rss.txt');
  Button1.Enabled:=true;
  Checkbox1.Enabled:=true;
  Memo1.ReadOnly:=false;
  Timer1.Enabled:=true;  //Standard modular program
  Download.Free;
  GetRss.Free;
  Downloaded.Free;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  Ini:TIniFile;
begin
  ClickStatusBar:=0;
  Button1.ControlState:=[csFocusing];
  Ini:=TIniFile.Create(ExtractFilePath(ParamStr(0))+'setup.ini');
  PathDownload:=Ini.ReadString('Main','Path',ExtractFilePath(ParamStr(0)));
  Ini.Free;
  Application.Title:=Caption;
  if FileExists(ExtractFilePath(ParamStr(0))+'rss.txt') then
    Memo1.Lines.LoadFromFile(ExtractFilePath(ParamStr(0))+'rss.txt');
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if Memo1.Lines.Count>0 then Memo1.Lines.SaveToFile(ExtractFilePath(ParamStr(0))+'rss.txt');
  if Assigned(SyncList) then SyncList.Free;
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  ShellExecute(Handle,nil,PChar(PathDownload),nil,nil,SW_SHOWNORMAL);
end;

procedure TForm1.WMCopyData(var Msg: TWMCopyData);
var
  i: integer;
begin
  if PChar(TWMCopyData(msg).CopyDataStruct.lpData)='YES' then if Assigned(SyncList) then if (SyncList.Count>0) and (hTargetWnd<>0) then SendMessageToHandle(hTargetWnd,SyncList.Text);
  if PChar(TWMCopyData(msg).CopyDataStruct.lpData)='GOOD' then begin
  SyncList.Delete(0);
  for i:=0 to SyncList.Count-1 do
    if FileExists(SyncList.Strings[i]) then DeleteFile(SyncList.Strings[i]);
  FreeAndNil(SyncList);
  StatusBar1.SimpleText:=' Все подкасты загружены на устройство';
end;
  //SendMessageToHandle(msg.From,'YES');
  Msg.Result:=Integer(True);
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  //Standard modular program
  hTargetWnd:=FindWindowExtd('iOS Sync - ');
  if hTargetWnd<>0 then begin
    SendMessageToHandle(hTargetWnd,'WORK');
    Timer1.Enabled:=false;
  end;
  //end Smp
end;

procedure TForm1.StatusBar1Click(Sender: TObject);
begin
  if Button1.Enabled then begin
    inc(ClickStatusBar);
    if ClickStatusBar=1 then
      case MessageBox(Handle,'Удалить старые ссылки? Ускорит поиск новых подкастов.','Проверка старых ссылок',35) of
        6: CheckLinksDownloaded;
      end;
    if ClickStatusBar=2 then begin
     Application.MessageBox('PodCast Easy 0.5.1'+#13#10+'https://github.com/r57zone'+#13#10+'Последнее обновление: 14.12.2015','О программе...',0);
     ClickStatusBar:=0;
    end;
  end;
end;

procedure TForm1.CheckLinksDownloaded;
var
  i, j, c: integer; Downloaded, Rss, Links: TStringList; source: string;
  Error: boolean;
begin
  Form1.Height:=161;
  ProgressBar1.Visible:=true;
  Memo1.Visible:=false;
  CheckBox1.Enabled:=false;
  Button1.Enabled:=false;
  Error:=false;
  Downloaded:=TStringList.Create();
  Rss:=TStringList.Create();
  Links:=TStringList.Create();
  Downloaded.LoadFromFile('downloaded.txt');
  Rss.LoadFromFile('rss.txt');
  StatusBar1.SimpleText:=' Этап 1 - Подготовка общего списка';
  ProgressBar1.Max:=rss.Count-1;
  for i:=Rss.Count-1 downto 0 do begin
    if CheckUrl(rss.Strings[i])=false then begin error:=true; ShowMessage(rss.Strings[i]); break; end;
    source:=source+#13+GetUrl(rss.Strings[i]);
    Application.ProcessMessages;
    ProgressBar1.Position:=Rss.Count-1-i;
  end;
  StatusBar1.SimpleText:=' Этап 2 - Проверка ссылок в списке';
  ProgressBar1.Position:=0;
  if Error=false then begin
    ProgressBar1.Max:=Downloaded.Count-1;
    for j:=Downloaded.Count-1 downto 0 do begin
      if Pos(Downloaded.Strings[j],source)>0 then links.Add(Downloaded.Strings[j]);
      Application.ProcessMessages;
      ProgressBar1.Position:=Downloaded.Count-1-j;
    end;
    Links.Sort;
    Links.SaveToFile('downloaded.txt');
    Showmessage('Удалено ссылок : '+IntToStr(Downloaded.Count-links.Count));
    StatusBar1.SimpleText:='';
  end else ShowMessage('Ошибка, лента '+rss.Strings[i]+' недоступна. Если она перестала существовать,'+#13#10+'то просто удалите ее из rss.txt и повторите попытку.');
  Downloaded.free;
  Rss.free;
  Links.free;
  ProgressBar1.Position:=0;
  ProgressBar1.Visible:=false;
  Memo1.Visible:=true;
  CheckBox1.Enabled:=true;
  Button1.Enabled:=true;
  Form1.ClientHeight:=166;
end;

end.
