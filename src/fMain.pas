unit fMain;

interface

uses
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Classes,
  System.Variants,
  FMX.Types,
  FMX.Controls,
  FMX.Forms,
  FMX.Graphics,
  FMX.Dialogs,
  uDMAboutBoxImage,
  Olf.FMX.AboutDialog,
  FMX.Controls.Presentation,
  FMX.StdCtrls;

type
  TfrmMain = class(TForm)
    OlfAboutDialog1: TOlfAboutDialog;
    btnAbout: TButton;
    btnClose: TButton;
    btnBuild: TButton;
    procedure btnCloseClick(Sender: TObject);
    procedure btnAboutClick(Sender: TObject);
    procedure OlfAboutDialog1URLClick(const AURL: string);
    procedure btnBuildClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Déclarations privées }
  public
    { Déclarations publiques }
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.fmx}

uses
  u_urlOpen,
  fBuildForm;

procedure TfrmMain.btnAboutClick(Sender: TObject);
begin
  OlfAboutDialog1.execute;
end;

procedure TfrmMain.btnBuildClick(Sender: TObject);
var
  f: tfrmBuildForm;
begin
  f := tfrmBuildForm.create(self);
  try
    f.showmodal;
  finally
    f.free;
  end;
end;

procedure TfrmMain.btnCloseClick(Sender: TObject);
begin
  close;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  OlfAboutDialog1.Titre := caption;
  caption := caption + ' v' + OlfAboutDialog1.VersionNumero + ' - ' +
    OlfAboutDialog1.VersionDate;
end;

procedure TfrmMain.OlfAboutDialog1URLClick(const AURL: string);
begin
  url_Open_In_Browser(AURL);
end;

initialization

{$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := true;
{$ENDIF}

end.
