unit fMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  uDMAboutBoxImage, Olf.FMX.AboutDialog;

type
  TfmrMain = class(TForm)
    OlfAboutDialog1: TOlfAboutDialog;
  private
    { Déclarations privées }
  public
    { Déclarations publiques }
  end;

var
  fmrMain: TfmrMain;

implementation

{$R *.fmx}

end.
