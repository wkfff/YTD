(******************************************************************************

______________________________________________________________________________

YouTube Downloader                                           (c) 2009-11 Pepak
http://www.pepak.net/download/youtube-downloader/         http://www.pepak.net
______________________________________________________________________________


Copyright (c) 2011, Pepak (http://www.pepak.net)
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Pepak nor the
      names of his contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL PEPAK BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

******************************************************************************)

unit downCNBC;
{$INCLUDE 'ytd.inc'}

interface

uses
  SysUtils, Classes,
  uPCRE, uXml, HttpSend,
  uDownloader, uCommonDownloader, uRtmpDownloader;

type
  TDownloader_CNBC = class(TRtmpDownloader)
    private
    protected
      InfoUrlRegExp: TRegExp;
      RtmpUrlRegExp: TRegExp;
    protected
      function GetMovieInfoUrl: string; override;
      function AfterPrepareFromPage(var Page: string; PageXml: TXmlDoc; Http: THttpSend): boolean; override;
    public
      class function Provider: string; override;
      class function UrlRegExp: string; override;
      constructor Create(const AMovieID: string); override;
      destructor Destroy; override;
    end;

implementation

uses
  uDownloadClassifier,
  uMessages;

// http://video.cnbc.com/gallery/?video=3000016920
// http://www.cnbc.com/id/15840232?video=3000016920&play=1
const
  URLREGEXP_BEFORE_ID = '^https?://(?:[a-z0-9-]+\.)*cnbc\.com/.*[?&]video=';
  URLREGEXP_ID =        '[0-9]+';
  URLREGEXP_AFTER_ID =  '';

const
  REGEXP_MOVIE_TITLE = '<h1>\s*<a\s[^>]*>(?P<TITLE>.*?)</a>\s*</h1>';
  REGEXP_INFO_URL = '\bformatLink\s*:\s*''[^''|]+\|(?P<URL>https?://[^''|]+)';
  REGEXP_RTMP_URL = '(?P<URL>rtmpt?e?://[^?]+)\?(?:[^&]*&)*slist=(?P<LIST>[^&]+)';

{ TDownloader_CNBC }

class function TDownloader_CNBC.Provider: string;
begin
  Result := 'CNBC.com';
end;

class function TDownloader_CNBC.UrlRegExp: string;
begin
  Result := Format(URLREGEXP_BEFORE_ID + '(?P<%s>' + URLREGEXP_ID + ')' + URLREGEXP_AFTER_ID, [MovieIDParamName]);;
end;

constructor TDownloader_CNBC.Create(const AMovieID: string);
begin
  inherited;
  InfoPageEncoding := peUTF8;
  MovieTitleRegExp := RegExCreate(REGEXP_MOVIE_TITLE);
  InfoUrlRegExp := RegExCreate(REGEXP_INFO_URL);
  RtmpUrlRegExp := RegExCreate(REGEXP_RTMP_URL);
end;

destructor TDownloader_CNBC.Destroy;
begin
  RegExFreeAndNil(MovieTitleRegExp);
  RegExFreeAndNil(InfoUrlRegExp);
  RegExFreeAndNil(RtmpUrlRegExp);
  inherited;
end;

function TDownloader_CNBC.GetMovieInfoUrl: string;
begin
  Result := 'http://video.cnbc.com/gallery/?video=' + MovieID;
end;

function TDownloader_CNBC.AfterPrepareFromPage(var Page: string; PageXml: TXmlDoc; Http: THttpSend): boolean;
const STR_BREAK = '<break>';
      STR_BREAK_LENGTH = Length(STR_BREAK);
var Url, Title, App, List: string;
    Xml: TXmlDoc;
    i, idx: integer;
begin
  inherited AfterPrepareFromPage(Page, PageXml, Http);
  Result := False;
  if not GetRegExpVar(InfoUrlRegExp, Page, 'URL', Url) then
    SetLastErrorMsg(_(ERR_FAILED_TO_LOCATE_MEDIA_INFO_PAGE))
  else if not DownloadXml(Http, Url, Xml) then
    SetLastErrorMsg(_(ERR_FAILED_TO_DOWNLOAD_MEDIA_INFO_PAGE))
  else
    try
      for i := 0 to Pred(Xml.Root.NodeCount) do
        if Xml.Root.Nodes[i].Name = 'choice' then
          if GetXmlVar(Xml.Root.Nodes[i], 'url', Url) then
            begin
            GetXmlVar(Xml.Root.Nodes[i], 'title', Title);
            if AnsiCompareText(Title, 'Ad Media') <> 0 then
              if GetRegExpVars(RtmpUrlRegExp, Url, ['URL', 'LIST'], [@App, @List]) then
                if App <> '' then
                  while List <> '' do
                    begin
                    idx := Pos(STR_BREAK, List);
                    if idx <= 0 then
                      begin
                      Url := List;
                      List := '';
                      end
                    else
                      begin
                      Url := Copy(List, 1, Pred(idx));
                      System.Delete(List, 1, idx+STR_BREAK_LENGTH-1);
                      end;
                    if Url <> '' then
                      begin
                      MovieUrl := App + Url;
                      AddRtmpDumpOption('r', App);
                      AddRtmpDumpOption('y', Url);
                      SetPrepared(True);
                      Result := True;
                      Exit;
                      end;
                    end;
            end;
    finally
      Xml.Free;
      end;
end;

initialization
  RegisterDownloader(TDownloader_CNBC);

end.
