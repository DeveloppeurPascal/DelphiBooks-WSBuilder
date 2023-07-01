unit uBuilder;

interface

uses
  DelphiBooks.Classes,
  DelphiBooks.DB.Repository;

procedure BuildPageFromTemplate(ADB: TDelphiBooksDatabase;
  ALang: TDelphiBooksLanguage; TemplatePath, DestFile: string;
  ADataName: string = ''; AItem: TDelphiBooksItem = nil);

implementation

procedure BuildPageFromTemplate(ADB: TDelphiBooksDatabase;
  ALang: TDelphiBooksLanguage; TemplatePath, DestFile: string;
  ADataName: string; AItem: TDelphiBooksItem);
begin
  // TODO : à compléter
end;

end.
