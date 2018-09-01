unit downVideaCesky;
{$INCLUDE 'ytd.inc'}
{$DEFINE SUBTITLES}

interface

uses
  SysUtils, Classes,
  uPCRE, HttpSend,
  uDownloader, uCommonDownloader, uNestedDownloader;

type
  TDownloader_VideaCesky = class(TNestedDownloader)
    private
    protected
      YouTubeUrlRegexp1, YouTubeUrlRegExp2: TRegExp;
      {$IFDEF SUBTITLES}
      SubtitlesRegExp1, SubtitlesRegExp2: TRegExp;
      Subtitles: string;
      SubtitlesName: string;
      {$ENDIF}
    protected
      function GetMovieInfoUrl: string; override;
      function AfterPrepareFromPage(var Page: string; Http: THttpSend): boolean; override;
      function CreateNestedDownloaderFromURL(var Url: string): boolean; override;
    public
      class function Provider: string; override;
      class function UrlRegExp: string; override;
      constructor Create(const AMovieID: string); override;
      destructor Destroy; override;
      function Download: boolean; override;
    end;

implementation

uses
  uDownloadClassifier,
  uMessages;

// http://www.videacesky.cz/serialy/upoutavka-na-treti-radu-the-guild
const
  URLREGEXP_BEFORE_ID = '^https?://(?:[a-z0-9-]+\.)*videacesky\.cz/[^/]+/';
  URLREGEXP_ID =        '[^/?&]+';
  URLREGEXP_AFTER_ID =  '';

const
  REGEXP_EXTRACT_TITLE = '<title>(?P<TITLE>[^<]*?)\s*-\s*Videa\s*�esky';
  REGEXP_EXTRACT_YOUTUBE_URL = '\sflashvars="(?:[^"]*&amp;)?file=(?P<URL>https?[^"]+?)(?:&amp;|")';
  REGEXP_EXTRACT_YOUTUBE_URL2 = '<param\s+name="flashvars"\s+value="(?:[^"]*&amp;)?file=(?P<URL>https?[^"]+?)(?:&amp;|")';
  {$IFDEF SUBTITLES}
  REGEXP_EXTRACT_SUBTITLES = '\sflashvars="(?:[^"]*&amp;)?captions\.file=(?P<SUBTITLES>https?://[^&"]+)';
  REGEXP_EXTRACT_SUBTITLES2 = '<param\s+name="flashvars"\s+value="(?:[^"]*&amp;)?captions\.file=(?P<SUBTITLES>https?://[^&"]+)';
  {$ENDIF}

{ TDownloader_VideaCesky }

class function TDownloader_VideaCesky.Provider: string;
begin
  Result := 'VideaCesky.cz';
end;

class function TDownloader_VideaCesky.UrlRegExp: string;
begin
  Result := URLREGEXP_BEFORE_ID + '(?P<' + MovieIDParamName + '>' + URLREGEXP_ID + ')' + URLREGEXP_AFTER_ID;
end;

constructor TDownloader_VideaCesky.Create(const AMovieID: string);
begin
  inherited Create(AMovieID);
  SetInfoPageEncoding(peUTF8);
  MovieTitleRegExp := RegExCreate(REGEXP_EXTRACT_TITLE, [rcoIgnoreCase, rcoSingleLine]);
  //NestedUrlRegExp := RegExCreate(REGEXP_EXTRACT_YOUTUBE_ID, [rcoIgnoreCase, rcoSingleLine]);
  YouTubeUrlRegExp1 := RegExCreate(REGEXP_EXTRACT_YOUTUBE_URL, [rcoIgnoreCase, rcoSingleLine]);
  YouTubeUrlRegExp2 := RegExCreate(REGEXP_EXTRACT_YOUTUBE_URL2, [rcoIgnoreCase, rcoSingleLine]);
  {$IFDEF SUBTITLES}
  SubtitlesRegExp1 := RegExCreate(REGEXP_EXTRACT_SUBTITLES, [rcoIgnoreCase, rcoSingleLine]);
  SubtitlesRegExp2 := RegExCreate(REGEXP_EXTRACT_SUBTITLES2, [rcoIgnoreCase, rcoSingleLine]);
  {$ENDIF}
end;

destructor TDownloader_VideaCesky.Destroy;
begin
  RegExFreeAndNil(MovieTitleRegExp);
  //RegExFreeAndNil(NestedUrlRegExp);
  RegExFreeAndNil(YouTubeUrlRegExp1);
  RegExFreeAndNil(YouTubeUrlRegExp2);
  {$IFDEF SUBTITLES}
  RegExFreeAndNil(SubtitlesRegExp1);
  RegExFreeAndNil(SubtitlesRegExp2);
  {$ENDIF}
  inherited;
end;

function TDownloader_VideaCesky.GetMovieInfoUrl: string;
begin
  Result := 'http://www.videacesky.cz/dummy/' + MovieID;
end;

function TDownloader_VideaCesky.AfterPrepareFromPage(var Page: string; Http: THttpSend): boolean;
{$IFDEF SUBTITLES}
var Url: string;
{$ENDIF}
begin
  try
    NestedUrlRegExp := YouTubeUrlRegExp1;
    Result := inherited AfterPrepareFromPage(Page, Http);
    if not Result then
      begin
      NestedUrlRegExp := YouTubeUrlRegExp2;
      Result := inherited AfterPrepareFromPage(Page, Http);
      end;
    {$IFDEF SUBTITLES}
    Subtitles := '';
    SubtitlesName := '';
    if Result then
      if GetRegExpVar(SubtitlesRegExp1, Page, 'SUBTITLES', Url) or GetRegExpVar(SubtitlesRegExp2, Page, 'SUBTITLES', Url) then
        if not DownloadPage(Http, Url, Subtitles, peUTF8) then
          Subtitles := ''
        else
          SubtitlesName := ChangeFileExt(GetThisFileName, ExtractFileExt(Url));
    {$ENDIF}
  finally
    NestedUrlRegExp := nil;
    end;
end;

function TDownloader_VideaCesky.Download: boolean;
{$IFDEF SUBTITLES}
var Overwrite: boolean;
{$ENDIF}
begin
  Result := inherited Download;
  {$IFDEF SUBTITLES}
  if (Subtitles <> '') and (SubtitlesName <> '') then
    begin
    Overwrite := True;
    if FileExists(SubtitlesName) then
      if Assigned(OnFileNameValidate) then
        OnFileNameValidate(Self, SubtitlesName, Overwrite);
    if Overwrite then
      with TFileStream.Create(SubtitlesName, fmCreate) do
        try
          WriteBuffer(Subtitles[1], Length(Subtitles));
        finally
          Free;
          end;
    end;
  {$ENDIF}
end;

function TDownloader_VideaCesky.CreateNestedDownloaderFromURL(var Url: string): boolean;
begin
  Url := UrlDecode(Url);
  Result := inherited CreateNestedDownloaderFromURL(Url);
end;

initialization
  RegisterDownloader(TDownloader_VideaCesky);

end.
