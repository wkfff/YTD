unit uYTDAbout;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, HttpSend, ShellApi, ComCtrls, 
  uLanguages, uDownloadClassifier, uDownloader, uOptions;

const
  WM_FIRSTSHOW = WM_USER + 1;

type
  TFormAbout = class(TForm)
    LabelYTD: TLabel;
    LabelVersionLabel: TLabel;
    LabelVersion: TLabel;
    LabelNewestVersionLabel: TLabel;
    LabelNewestVersion: TLabel;
    LabelHomepageLabel: TLabel;
    LabelHomepage: TLabel;
    LabelMediaProviders: TLabel;
    ListProviders: TListView;
    procedure LabelNewestVersionClick(Sender: TObject);
    procedure LabelHomepageClick(Sender: TObject);
    procedure ListProvidersData(Sender: TObject; Item: TListItem);
  private
    fFirstShow: boolean;
    fDownloadClassifier: TDownloadClassifier;
    fNewVersionUrl: string;
    fOptions: TYTDOptions;
    procedure WMFirstShow(var Msg: TMessage); message WM_FIRSTSHOW;
  protected
    procedure DoShow; override;
    procedure DoFirstShow; {$IFDEF FPC} override; {$ELSE} virtual; {$ENDIF}
    procedure SetUrlStyle(ALabel: TLabel); virtual;
    procedure LoadProviders; virtual;
    property NewVersionUrl: string read fNewVersionUrl write fNewVersionUrl;
  public
    constructor Create(AOwner: TComponent); override;
    property Options: TYTDOptions read fOptions write fOptions;
    property DownloadClassifier: TDownloadClassifier read fDownloadClassifier write fDownloadClassifier;
  end;

implementation

{$R *.DFM}

{ TFormAbout }

constructor TFormAbout.Create(AOwner: TComponent);
begin
  inherited;
  TranslateProperties(self);
  fFirstShow := True;
end;

procedure TFormAbout.DoShow;
begin
  inherited;
  if fFirstShow then
    begin
    fFirstShow := False;
    PostMessage(Handle, WM_FIRSTSHOW, 0, 0);
    end;
end;

procedure TFormAbout.WMFirstShow(var Msg: TMessage);
begin
  {$IFNDEF FPC}
  DoFirstShow;
  {$ENDIF}
end;

procedure TFormAbout.DoFirstShow;
var Version, Url: string;
begin
  {$IFDEF FPC}
  inherited;
  {$ENDIF}
  // Show current version
  LabelVersion.Caption := {$INCLUDE 'YTD.version'};
  // Homepage
  SetUrlStyle(LabelHomepage);
  // Providers
  LoadProviders;
  // Show available version
  LabelNewestVersion.Caption := _('not found'); // GUI: Check for a new version wasn't made yet - or failed.
  Application.ProcessMessages;
  if Options <> nil then
    if Options.GetNewestVersion(Version, Url) then
      begin
      LabelNewestVersion.Caption := Version;
      NewVersionUrl := Url;
      if Version > {$INCLUDE 'YTD.version'} then
        SetUrlStyle(LabelNewestVersion);
      end;
end;

procedure TFormAbout.SetUrlStyle(ALabel: TLabel);
begin
  ALabel.Font.Color := clBlue;
  ALabel.Font.Style := LabelNewestVersion.Font.Style + [fsUnderline];
  ALabel.Cursor := crHandPoint;
end;

procedure TFormAbout.LabelNewestVersionClick(Sender: TObject);
begin
  if NewVersionUrl <> '' then
    ShellExecute(Handle, 'open', PChar(NewVersionUrl), nil, nil, 0);
end;

procedure TFormAbout.LabelHomepageClick(Sender: TObject);
begin
  ShellExecute(Handle, 'open', PChar((Sender as TLabel).Caption), nil, nil, 0);
end;

procedure TFormAbout.LoadProviders;
{$IFDEF FPC}
var i: integer;
{$ENDIF}
begin
  ListProviders.Items.BeginUpdate;
  {$IFDEF FPC}
  ListProviders.Items.Clear;
  if DownloadClassifier <> nil then
    for i := 0 to Pred(DownloadClassifier.NameCount) do
      ListProviders.Items.Add;
  {$ELSE}
  if DownloadClassifier = nil then
    ListProviders.Items.Count := 0
  else
    ListProviders.Items.Count := DownloadClassifier.NameCount;
  {$ENDIF}
  ListProviders.Items.EndUpdate;
end;

procedure TFormAbout.ListProvidersData(Sender: TObject; Item: TListItem);
begin
  if DownloadClassifier <> nil then
    begin
    Item.Caption := DownloadClassifier.Names[Item.Index];
    Item.SubItems.Clear;
    //Item.SubItems.Add(DownloadClassifier.Names[Item.Index]);
    Item.SubItems.Add(DownloadClassifier.NameClasses[Item.Index]);
    end;
end;

end.
