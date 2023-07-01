program DelphiBooksWebSiteBuilder;

uses
  System.StartUpCopy,
  FMX.Forms,
  fMain in 'fMain.pas' {frmMain},
  uDMAboutBoxImage in 'uDMAboutBoxImage.pas' {DMAboutBoxImage: TDataModule},
  Olf.FMX.AboutDialog in '..\lib-externes\AboutDialog-Delphi-Component\sources\Olf.FMX.AboutDialog.pas',
  Olf.FMX.AboutDialogForm in '..\lib-externes\AboutDialog-Delphi-Component\sources\Olf.FMX.AboutDialogForm.pas' {OlfAboutDialogForm},
  u_urlOpen in '..\lib-externes\librairies\u_urlOpen.pas',
  fBuildForm in 'fBuildForm.pas' {frmBuildForm},
  DelphiBooks.Classes in '..\lib-externes\DelphiBooks-Common\src\DelphiBooks.Classes.pas',
  DelphiBooks.DB.Repository in '..\lib-externes\DelphiBooks-Common\src\DelphiBooks.DB.Repository.pas',
  uBuilder in 'uBuilder.pas',
  uOutilsCommuns in 'uOutilsCommuns.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TDMAboutBoxImage, DMAboutBoxImage);
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
