unit uYTD;
{$INCLUDE 'ytd.inc'}

interface

uses
  SysUtils, Classes, {$IFNDEF FPC} FileCtrl, {$ENDIF}
  PCRE,
  uConsoleApp, uOptions, uLanguages, uMessages,
  uDownloader, uCommonDownloader,
  uPlaylistDownloader, listHTML, listHTMLfile,
  uDownloadClassifier;

type
  TYTD = class(TConsoleApp)
    private
      fLastProgressPercentage: int64;
      fDownloadClassifier: TDownloadClassifier;
      fHtmlPlaylist: TPlaylist_HTML;
      fHtmlFilePlaylist: TPlaylist_HTMLfile;
      fUrlList: TStringList;
      fOptions: TYTDOptions;
    protected
      function AppTitle: string; override;
      function AppVersion: string; override;
      function DoExecute: integer; override;
      procedure ShowSyntax(const Error: string = ''); override;
      procedure ParamInitialize; override;
      property UrlList: TStringList read fUrlList;
    protected
      function DoDownload(const Url: string; Downloader: TDownloader): boolean; virtual;
      procedure DownloaderProgress(Sender: TObject; TotalSize, DownloadedSize: int64; var DoAbort: boolean); virtual;
      procedure DownloaderFileNameValidate(Sender: TObject; var FileName: string; var Valid: boolean); virtual;
      function DownloadUrlList: integer; virtual;
      function DownloadURL(const URL: string): boolean; virtual;
      function DownloadURLsFromFileList(const FileName: string): integer; virtual;
      function DownloadURLsFromHTML(const Source: string): integer; virtual;
      procedure ShowProviders; virtual;
      procedure ShowVersion; virtual;
      property DownloadClassifier: TDownloadClassifier read fDownloadClassifier;
      property HtmlPlaylist: TPlaylist_HTML read fHtmlPlaylist;
      property HtmlFilePlaylist: TPlaylist_HTMLfile read fHtmlFilePlaylist;
    public
      constructor Create; override;
      destructor Destroy; override;
      property Options: TYTDOptions read fOptions;
    end;

const
  RESCODE_DOWNLOADFAILED = 1;
  RESCODE_NOURLS = 2;
  RESCODE_BADPARAMS = 3;
  RESCODE_BADDATA = 4;

implementation

{ TYTD }

constructor TYTD.Create;
begin
  inherited;
  fOptions := TYTDOptions.Create;
  UseLanguage(Options.Language);
  fDownloadClassifier := TDownloadClassifier.Create;
  fHtmlPlaylist := TPlaylist_HTML.Create('');
  fHtmlFilePlaylist := TPlaylist_HTMLfile.Create('');
  fUrlList := TStringList.Create;
end;

destructor TYTD.Destroy;
begin
  FreeAndNil(fOptions);
  FreeAndNil(fDownloadClassifier);
  FreeAndNil(fHtmlPlaylist);
  FreeAndNil(fHtmlFilePlaylist);
  FreeAndNil(fUrlList);
  inherited;
end;

function TYTD.AppTitle: string;
begin
  Result := APPLICATION_TITLE;
end;

function TYTD.AppVersion: string;
begin
  Result := {$INCLUDE 'ytd.version'} ;
end;

procedure TYTD.ShowSyntax(const Error: string);
//var i: integer;
begin
  inherited;
  WriteColored(ccWhite, '<arg> [<arg>] ...'); Writeln; // Intentionally no _(...) - this should not be translated
  Writeln;
  WriteColored(ccWhite, ' -h, -?'); Writeln(_(' ...... Show this help screen.')); // CLI: Help for -h/-? command line argument
  WriteColored(ccWhite, ' -i <file>'); Writeln(_(' ... Load URL list from <file> (one URL per line).')); // CLI: Help for -i command line argument
  WriteColored(ccWhite, ' -o <path>'); Writeln(_(' ... Store files to <path> (default is current directory).')); // CLI: Help for -o command line argument
  WriteColored(ccWhite, ' -e <file>'); Writeln(_(' ... Save failed URLs to <file>.')); // CLI: Help for -e command line argument
  WriteColored(ccWhite, ' -s <src>'); Writeln(_(' .... Load links from a HTML source. <src> can be a file or an URL.')); // CLI: Help for -s command line argument
  WriteColored(ccWhite, ' -n'); Writeln(_(' .......... Never overwrite existing files.')); // CLI: Help for -n command line argument
  WriteColored(ccWhite, ' -a'); Writeln(_(' .......... Always overwrite existing files.')); // CLI: Help for -a command line argument
  WriteColored(ccWhite, ' -r'); Writeln(_(' .......... Rename files to a new name if they already exist.')); // CLI: Help for -r command line argument
  WriteColored(ccWhite, ' -k'); Writeln(_(' .......... Ask what to do with existing files (default).')); // CLI: Help for -k command line argument
  WriteColored(ccWhite, ' -l'); Writeln(_(' .......... List all available providers.')); // CLI: Help for -l command line argument
  WriteColored(ccWhite, ' -v'); Writeln(_(' .......... Test for updated version of YTD.')); // CLI: Help for -v command line argument
  Writeln;
  WriteColored(ccWhite, ' <url>'); Writeln(_(' ....... URL to download.')); // CLI: Help for <url> command line argument
  {
  Writeln('               Supported:');
  for i := 0 to Pred(DownloadClassifier.ProviderCount) do
    begin
    WriteColored(ccWhite, '                 ' + DownloadClassifier.Providers[i].Provider);
    Writeln;
    end;
  }
  Writeln;
  Writeln;
end;

procedure TYTD.ShowProviders;
{$DEFINE GROUPPED}
var i: integer;
begin
  Writeln;
  WriteColored(ccWhite, _('Available providers:')); Writeln; // CLI: Title for the list of providers (-l command line argument)
  for i := 0 to Pred({$IFDEF GROUPPED} DownloadClassifier.NameCount {$ELSE} DownloadClassifier.ProviderCount {$ENDIF}) do
    begin
    Write('  - ');
    WriteColored(ccLightCyan, {$IFDEF GROUPPED} DownloadClassifier.Names[i] {$ELSE} DownloadClassifier.Providers[i].Provider {$ENDIF});
    Writeln(' (' + {$IFDEF GROUPPED} DownloadClassifier.NameClasses[i] {$ELSE} DownloadClassifier.Providers[i].ClassName {$ENDIF} + ')');
    end;
  Write(_('Total: ')); // CLI: The "Total: " part of "Total: 123 providers." Note the ending space
  WriteColored(ccWhite, IntToStr({$IFDEF GROUPPED} DownloadClassifier.NameCount {$ELSE} DownloadClassifier.ProviderCount {$ENDIF}));
  Writeln(_(' providers.')); // CLI: The " providers" part of "Total: 123 providers." Note the starting space
  Writeln;
end;

procedure TYTD.ShowVersion;
var Url, Version: string;
begin
  Write(_('Current version: ')); WriteColored(ccWhite, AppVersion); Writeln; // CLI: Note: pad with spaces to the same length as "Newest version:"
  Write(_('Newest version:  ')); // CLI: Note: pad with spaces to the same length as "Current version:"
  if not Options.GetNewestVersion(Version, Url) then
    WriteColored(ccLightRed, _('check failed')) // CLI: Couldn't check for a newer version
  else if Version <= AppVersion then
    WriteColored(ccWhite, Version)
  else
    begin
    WriteColored(ccLightCyan, Version); Writeln;
    Write(_('Download URL:    ')); WriteColored(ccWhite, Url); // CLI: Note: pad with spaces to the same length as "Current version:"
    end;
  Writeln;
  Writeln;
end;

procedure TYTD.ParamInitialize;
begin
  inherited;
  if Options <> nil then
    Options.Init;
end;

function TYTD.DoExecute: integer;
var Param: string;
    n: integer;
begin
  if ParamCount = 0 then
    begin
    ShowSyntax;
    Result := RESCODE_OK;
    end
  else
    begin
    Result := RESCODE_NOURLS;
    ParamInitialize;
    while ParamGetNext(Param) do
      if Param[1] = '-' then
        begin
        if (Param = '-?') or (Param = '-h') then
          begin
          ShowSyntax;
          if Result in [RESCODE_OK, RESCODE_NOURLS] then
            Result := RESCODE_OK;
          Break;
          end
        else if (Param = '-l') then
          begin
          ShowProviders;
          if Result in [RESCODE_OK, RESCODE_NOURLS] then
            Result := RESCODE_OK;
          Break;
          end
        else if (Param = '-v') then
          begin
          ShowVersion;
          if Result in [RESCODE_OK, RESCODE_NOURLS] then
            Result := RESCODE_OK;
          Break;
          end
        else if (Param = '-n') then
          Options.OverwriteMode := omNever
        else if (Param = '-a') then
          Options.OverwriteMode := omAlways
        else if (Param = '-r') then
          Options.OverwriteMode := omRename
        else if (Param = '-k') then
          Options.OverwriteMode := omAsk
        else if (Param = '-e') then
          if ParamGetNext(Param) then
            begin
            Options.ErrorLog := Param;
            if FileExists(Param) then
              DeleteFile(Param);
            end
          else
            begin
            ShowSyntax(_('With -e a filename must be provided.')); // CLI: Error message for invalid command line argument
            Result := RESCODE_BADPARAMS;
            Break;
            end
        else if (Param = '-s') then
          if ParamGetNext(Param) then
            begin
            n := DownloadURLsFromHTML(Param);
            if n = 0 then
              begin
              ShowSyntax(_('HTML source "%s" doesn''t contain any useful links.'), [Param]); // CLI: Error message for invalid command line argument
              Result := RESCODE_DOWNLOADFAILED;
              end
            else if n < 0 then
              begin
              ShowSyntax(_('HTML source "%s" not found.'), [Param]); // CLI: Error message for invalid command line argument
              Result := RESCODE_BADDATA;
              Break;
              end
            else
              if Result = RESCODE_NOURLS then
                Result := RESCODE_OK;
            end
          else
            begin
            ShowSyntax(_('With -s a filename or an URL must be provided.')); // CLI: Error message for invalid command line argument
            Result := RESCODE_BADPARAMS;
            Break;
            end
        else if (Param = '-i') then
          if ParamGetNext(Param) then
            if FileExists(Param) then
              if DownloadURLsFromFileList(Param) > 0 then
                begin
                if Result = RESCODE_NOURLS then
                  Result := RESCODE_OK;
                end
              else
                Result := RESCODE_DOWNLOADFAILED
            else
              begin
              ShowSyntax(_('URL list-file "%s" not found.'), [Param]); // CLI: Error message for invalid command line argument
              Result := RESCODE_BADDATA;
              Break;
              end
          else
            begin
            ShowSyntax(_('With -i a filename must be provided.')); // CLI: Error message for invalid command line argument
            Result := RESCODE_BADPARAMS;
            Break;
            end
        else if (Param = '-o') then
          if ParamGetNext(Param) then
            if DirectoryExists(Param) then
              Options.DestinationPath := Param
            else
              begin
              ShowSyntax(_('Destination directory "%s" not found.'), [Param]); // CLI: Error message for invalid command line argument
              Result := RESCODE_BADDATA;
              Break;
              end
          else
            begin
            ShowSyntax(_('With -o a directory name must be provided.')); // CLI: Error message for invalid command line argument
            Result := RESCODE_BADPARAMS;
            Break;
            end
        else
          begin
          ShowSyntax(_('Unknown parameter "%s".'), [Param]); // CLI: Error message for invalid command line argument
          Result := RESCODE_BADPARAMS;
          Break;
          end
        end
      else
        if DownloadURL(Param) then
          begin
          if Result = RESCODE_NOURLS then
            Result := RESCODE_OK;
          end
        else
          Result := RESCODE_DOWNLOADFAILED;
    if Result = RESCODE_NOURLS then
      ShowError(_('No valid URLs found.')); // CLI: Error message for invalid command line argument
    end;
end;

function Int64ToStrF(Value: int64): string;
var Sign: string;
begin
  if Value = 0 then
    Result := '0'
  else if (PByteArray(@Value)^[0]=$80) and ((Value and $00ffffffffffffff) = 0) then
    Result := '-9' + ThousandSeparator + '223' + ThousandSeparator + '372' + ThousandSeparator + '036' + ThousandSeparator + '854' + ThousandSeparator + '775' + ThousandSeparator + '808'
  else
    begin
    if Value < 0 then
      begin
      Sign := '-';
      Value := -Value;
      end;
    Result := '';
    while Value >= 1000 do
      begin
      Result := Format('%s%03.3d%s', [ThousandSeparator, Value mod 1000, Result]);
      Value := Value div 1000;
      end;
    Result := Sign + IntToStr(Value) + Result;
    end;
end;

procedure TYTD.DownloaderProgress(Sender: TObject; TotalSize, DownloadedSize: int64; var DoAbort: boolean);
const EmptyProgressBar = '                             ';
      ProgressBarLength = Length(EmptyProgressBar);
var Proc: int64;
    i, n: integer;
    ProgressBar: string;
begin
  if TotalSize >= 1 then
    begin
    Proc := 1000 * DownloadedSize div TotalSize;
    if (not StdOutRedirected) and (Proc <> fLastProgressPercentage) then
      begin
      fLastProgressPercentage := Proc;
      n := Proc div (1000 div ProgressBarLength);
      ProgressBar := EmptyProgressBar;
      for i := 1 to n do
        ProgressBar[i] := '#';
      Write(Format(_('  Downloading: <%s> %d.%d%% (%s/%s)') + #13, [ProgressBar, Proc div 10, Proc mod 10, Int64ToStrF(DownloadedSize), Int64ToStrF(TotalSize)])); // CLI progress bar. %: Progress bar "graphics", Percent done (integer part), Percent done (fractional part), Downloaded size, Total size
      end;
    end;
end;

function TYTD.DoDownload(const Url: string; Downloader: TDownloader): boolean;

  procedure ShowDownloadError(const Url, Msg: string);
    begin
      ShowError(_('  ERROR: ') + Msg);
      if Options.ErrorLog <> '' then
        Log(Options.ErrorLog, _('FAILED "%s": %s'), [Url, Msg]); // CLI: Error message to be written to the log file. %: URL, message
    end;

var Playlist: TPlaylistDownloader;
    i: integer;
begin
  Result := False;
  try
    Downloader.Options := Options;
    if Downloader is TPlaylistDownloader then
      begin
      PlayList := TPlaylistDownloader(Downloader);
      if Playlist.Prepare then
        begin
        for i := 0 to Pred(Playlist.Count) do
          begin
          Result := True;
          UrlList.Add(Playlist[i]);
          Write(_('  Playlist item: ')); // CLI: Title shown before playlist item's name. Pad with spaces to the same length as "URL:"
          if Playlist.Names[i] <> '' then
            begin
            WriteColored(ccWhite, Playlist.Names[i]);
            Writeln;
            Write(_('            URL: ')); // CLI: Title shown before playlist item's URL. Pad with spaces to the same length as "Playlist item:"
            end;
          WriteColored(ccWhite, Playlist[i]);
          Writeln;
          end;
        end
      else
        ShowDownloadError(Url, Downloader.LastErrorMsg);
      end
    else
      begin
      fLastProgressPercentage := -1;
      Downloader.OnProgress := DownloaderProgress;
      Downloader.OnFileNameValidate := DownloaderFileNameValidate;
      if Downloader.Prepare {$IFDEF MULTIDOWNLOADS} and Downloader.First {$ENDIF} then
        begin
        {$IFDEF MULTIDOWNLOADS}
        repeat
        {$ENDIF}
        Write(_('  Media title: ')); WriteColored(ccWhite, Downloader.Name); Writeln; // CLI: Title shown before media title. Pad to the same length as "File name:'
        Write(_('    File name: ')); WriteColored(ccWhite, Downloader.FileName); Writeln; // CLI: Title shown before media file name. Pad to the same length as "Media title:'
        if Downloader is TCommonDownloader then
          Write(_('  Content URL: ')); WriteColored(ccWhite, TCommonDownloader(Downloader).ContentUrl); Writeln; // CLI: Title shown before media URL. Pad to the same length as "Media title:'
        Result := Downloader.ValidateFileName and Downloader.Download;
        if fLastProgressPercentage >= 0 then
          Writeln;
        if Result then
          begin
          WriteColored(ccWhite, _('  SUCCESS.')); // CLI: Media downloaded successfully
          Writeln;
          Writeln;
          end
        else
          ShowDownloadError(Url, Downloader.LastErrorMsg);
        {$IFDEF MULTIDOWNLOADS}
        until (not Result) or (not Downloader.Next);
        {$ENDIF}
        end
      else
        ShowDownloadError(Url, Downloader.LastErrorMsg);
      end;
  except
    on E: EAbort do
      begin
      ShowError(_('  ABORTED BY USER')); // CLI: User aborted the download
      Raise;
      end;
    on E: Exception do
      begin
      ShowError(_('ERROR %s: %s'), [E.ClassName, E.Message]); // CLI: Error. %: Exception type, Exception message
      Result := False;
      end;
    end;
end;

function TYTD.DownloadUrlList: integer;
begin
  Result := 0;
  while UrlList.Count > 0 do
    begin
    WriteColored(ccLightCyan, UrlList[0]);
    Writeln;
    DownloadClassifier.URL := UrlList[0];
    if DownloadClassifier.Downloader = nil then
      ShowError(_('Unknown URL.')) // CLI: URL couldn't be assigned to any available downloader
    else
      if DoDownload(DownloadClassifier.URL, DownloadClassifier.Downloader) then
        Inc(Result);
    UrlList.Delete(0);
    end;
end;

function TYTD.DownloadURL(const URL: string): boolean;
begin
  UrlList.Add(URL);
  Result := DownloadUrlList > 0;
end;

function TYTD.DownloadURLsFromHTML(const Source: string): integer;
const HTTP_PREFIX = 'http://';
      HTTPS_PREFIX = 'https://';
var Playlist: TPlaylist_HTML;
begin
  if (AnsiCompareText(Copy(Source, 1, Length(HTTP_PREFIX)), HTTP_PREFIX) = 0) or (AnsiCompareText(Copy(Source, 1, Length(HTTPS_PREFIX)), HTTPS_PREFIX) = 0) then
    Playlist := HtmlPlaylist
  else
    Playlist := HtmlFilePlaylist;
  Playlist.MovieID := Source;
  if DoDownload(Source, Playlist) then
    Result := DownloadUrlList
  else
    Result := -1;
end;

function TYTD.DownloadURLsFromFileList(const FileName: string): integer;
var T: TextFile;
    s: string;
begin
  AssignFile(T, FileName);
  Reset(T);
  try
    while not Eof(T) do
      begin
      Readln(T, s);
      s := Trim(s);
      if s <> '' then
        UrlList.Add(s);
      end;
  finally
    CloseFile(T);
    end;
  Result := DownloadUrlList;
end;

procedure TYTD.DownloaderFileNameValidate(Sender: TObject; var FileName: string; var Valid: boolean);
var FilePath, Answer: string;

    function AutoRename(var FileName: string): boolean;
      var FileNameBase, FileNameExt: string;
          Index: integer;
      begin
        Index := 1;
        FileNameExt := ExtractFileExt(FileName);
        FileNameBase := ChangeFileExt(FileName, '');
        repeat
          FileName := Format('%s%s.%d%s', [FilePath, FileNameBase, Index, FileNameExt]);
          Inc(Index);
        until not FileExists(FileName);
        Result := True;
      end;

begin
  FilePath := (Sender as TDownloader).Options.DestinationPath;
  if FileExists(FilePath + FileName) then
    case Options.OverwriteMode of
      omNever:
        Valid := False;
      omAlways:
        Valid := True;
      omRename:
        begin
        Valid := AutoRename(FileName);
        if Valid then
          begin
          Write(_('    File name: ')); WriteColored(ccWhite, FileName); Writeln; // CLI: File already exists, renaming it to a new filename
          end;
        end;
      omAsk:
        begin
        repeat
          Write(_('  File ')); // CLI: "File ... already exists. What do you want me to do?"
          WriteColored(ccWhite, FileName);
          Writeln(_(' already exists.'));
          Write(_('  Do you want to: '));
          WriteColored(ccLightCyan, '[S]'); Write(_('kip it, ')); // CLI: File already exists. [S]kip it
          WriteColored(ccLightCyan, '[O]'); Write(_('verwrite it, or ')); // CLI: File already exists. [O]verwrite it
          WriteColored(ccLightCyan, '[R]'); Write(_('ename it? ')); // CLI: File already exists. [R]ename it
          Readln(Answer);
          if Answer <> '' then
            case Upcase(Answer[1]) of
              'S':
                begin
                Valid := False;
                Break;
                end;
              'O':
                begin
                Valid := True;
                Break;
                end;
              'R':
                begin
                Write(_('  New filename: ')); // CLI: File already exists. Asking user to provide a new filename.
                Readln(Answer);
                if Answer <> '' then
                  begin
                  FileName := Answer;
                  Valid := True;
                  if not FileExists(FilePath + Answer) then
                    Break;
                  end;
                end;
              else
                ShowError(_('Incorrect answer.'));  // CLI: File already exists. User answered something else than [S]kip, [O]verwrite or [R]ename
              end;
        until False;
        end;
      end;
  if Valid and FileExists(FilePath + FileName) then
    DeleteFile(FilePath + FileName);
end;

end.
