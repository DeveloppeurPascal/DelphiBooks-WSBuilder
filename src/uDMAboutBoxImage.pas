unit uDMAboutBoxImage;

interface

uses
  System.SysUtils, System.Classes, System.ImageList, FMX.ImgList;

type
  TDMAboutBoxImage = class(TDataModule)
    ImageList1: TImageList;
  private
    { D�clarations priv�es }
  public
    { D�clarations publiques }
  end;

var
  DMAboutBoxImage: TDMAboutBoxImage;

implementation

{%CLASSGROUP 'FMX.Controls.TControl'}

{$R *.dfm}

end.
