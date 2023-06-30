unit fMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  uDMAboutBoxImage, Olf.FMX.AboutDialog, FMX.Controls.Presentation,
  FMX.StdCtrls;

type
  TfmrMain = class(TForm)
    OlfAboutDialog1: TOlfAboutDialog;
    btnAbout: TButton;
    btnClose: TButton;
    btnBuild: TButton;
    procedure btnCloseClick(Sender: TObject);
    procedure btnAboutClick(Sender: TObject);
    procedure OlfAboutDialog1URLClick(const AURL: string);
    procedure btnBuildClick(Sender: TObject);
  private
    { Déclarations privées }
  public
    { Déclarations publiques }
  end;

var
  fmrMain: TfmrMain;

implementation

{$R *.fmx}

uses u_urlOpen;

procedure TfmrMain.btnAboutClick(Sender: TObject);
begin
  OlfAboutDialog1.execute;
end;

procedure TfmrMain.btnBuildClick(Sender: TObject);
begin
// TODO : à compléter
end;

procedure TfmrMain.btnCloseClick(Sender: TObject);
begin
  close;
end;

procedure TfmrMain.OlfAboutDialog1URLClick(const AURL: string);
begin
  url_Open_In_Browser(AURL);
end;

end.
