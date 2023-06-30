unit fBuildForm;

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
  FMX.Memo.Types,
  FMX.StdCtrls,
  FMX.Controls.Presentation,
  FMX.ScrollBox,
  FMX.Memo,
  DelphiBooks.DB.Repository;

type
  TfrmBuildForm = class(TForm)
    mmoLog: TMemo;
    btnClose: TButton;
    procedure btnCloseClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    procedure LoadRepositoryDatabase(RepositoryFolder: string;
      var DB: TDelphiBooksDatabase);
    procedure UpdateNewObjectsProperties(DB: TDelphiBooksDatabase);
    procedure SaveRepositoryDatabase(DB: TDelphiBooksDatabase);
    procedure BuildWebSitePages(TemplateFolder, SiteFolder: string;
      DB: TDelphiBooksDatabase);
    procedure BuildWebSiteAPI(TemplateFolder, SiteFolder: string;
      DB: TDelphiBooksDatabase);
    procedure BuildWebSiteImages(DBFolder, SiteFolder: string;
      DB: TDelphiBooksDatabase);
    procedure getFolders(var RootFolder, DBFolder, TemplateFolder,
      SiteFolder: string);
    { Déclarations privées }
  public
    { Déclarations publiques }
    procedure debuglog(ATxt: string);
    procedure log(ATxt: string);
    procedure logTitle(ATxt: string);
    procedure logError(ATxt: string);
    procedure Execute;
  end;

var
  frmBuildForm: TfrmBuildForm;

implementation

{$R *.fmx}

uses
  System.IOUtils,
  DelphiBooks.Classes;

procedure TfrmBuildForm.btnCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmBuildForm.Execute;
var
  DB: TDelphiBooksDatabase;
  RootFolder, DBFolder, TemplateFolder, SiteFolder: string;
begin
  DB := nil;
  try
    getFolders(RootFolder, DBFolder, TemplateFolder, SiteFolder);

    LoadRepositoryDatabase(RootFolder, DB);
    try
      UpdateNewObjectsProperties(DB);
      BuildWebSitePages(TemplateFolder, SiteFolder, DB);
      BuildWebSiteAPI(TemplateFolder, SiteFolder, DB);
      BuildWebSiteImages(DBFolder, SiteFolder, DB);
      SaveRepositoryDatabase(DB);
    finally
      DB.free;
    end;
  except
    on e: exception do
    begin
      logError(e.Message);
      raise;
    end;
  end;
end;

procedure TfrmBuildForm.getFolders(var RootFolder, DBFolder, TemplateFolder,
  SiteFolder: string);
var
  ProgFolder: string;
begin
  // get exe file folder
  ProgFolder := tpath.GetDirectoryName(paramstr(0));
  if ProgFolder.isempty then
    raise exception.Create('Can''t extract program directory path.');
  if not tdirectory.Exists(ProgFolder) then
    raise exception.Create('Can''t find folder "' + ProgFolder + '".');
  debuglog(ProgFolder);

  // get DelphiBooks-WebSite folder depending on DEBUG/RELEASE version
{$IFDEF RELEASE}
  // the exe file is in "/site-builder" folder of the repository
  RootSiteRepositoryFolder := tpath.Combine(ProgFolder, '..');
{$ELSE}
  // the compiled exe is in /src/Win32/debug (or else)
  // the web site repository is in /lib-externes/DelphiBooks-WebSite
  RootFolder := tpath.Combine(ProgFolder, '..');
  RootFolder := tpath.Combine(RootFolder, '..');
  RootFolder := tpath.Combine(RootFolder, '..');
  RootFolder := tpath.Combine(RootFolder, 'lib-externes');
  RootFolder := tpath.Combine(RootFolder, 'DelphiBooks-WebSite');
{$ENDIF}
  if RootFolder.isempty then
    raise exception.Create('Can''t define root repository path.');
  if not tdirectory.Exists(RootFolder) then
    raise exception.Create('Can''t find folder "' + RootFolder + '".');
  debuglog(RootFolder);

  // Database is in /database/datas folder in the WebSite repository
  DBFolder := tpath.Combine(RootFolder, 'database');
  DBFolder := tpath.Combine(DBFolder, 'datas');
  if DBFolder.isempty then
    raise exception.Create('Can''t define database path.');
  if not tdirectory.Exists(DBFolder) then
    raise exception.Create('Can''t find folder "' + DBFolder + '".');
  debuglog(DBFolder);

  // Templates are in /site-templates/templates folder
  TemplateFolder := tpath.Combine(RootFolder, 'site-templates');
  TemplateFolder := tpath.Combine(TemplateFolder, 'templates');
  if TemplateFolder.isempty then
    raise exception.Create('Can''t define templates path.');
  if not tdirectory.Exists(TemplateFolder) then
    raise exception.Create('Can''t find folder "' + TemplateFolder + '".');
  debuglog(TemplateFolder);

  // The generated pages are in /docs folder
  SiteFolder := tpath.Combine(RootFolder, 'docs');
  if SiteFolder.isempty then
    raise exception.Create('Can''t define web site path.');
  if not tdirectory.Exists(SiteFolder) then
    raise exception.Create('Can''t find folder "' + SiteFolder + '".');
  debuglog(SiteFolder);
end;

procedure TfrmBuildForm.BuildWebSiteImages(DBFolder, SiteFolder: string;
  DB: TDelphiBooksDatabase);
begin
  // build the images thumbs
  logTitle('Build the images');
  // TODO : à compléter
  log('Finished');
end;

procedure TfrmBuildForm.BuildWebSiteAPI(TemplateFolder, SiteFolder: string;
  DB: TDelphiBooksDatabase);
begin
  // build the API
  logTitle('Build the API files');
  // TODO : à compléter
  log('Finished');
end;

procedure TfrmBuildForm.BuildWebSitePages(TemplateFolder, SiteFolder: string;
  DB: TDelphiBooksDatabase);
begin
  // build the website
  logTitle('Build the web pages');
  // TODO : à compléter
  log('Finished');
end;

procedure TfrmBuildForm.debuglog(ATxt: string);
begin
{$IFDEF DEBUG}
  log(ATxt);
{$ENDIF}
end;

procedure TfrmBuildForm.SaveRepositoryDatabase(DB: TDelphiBooksDatabase);
begin
  // save the new objects in the repository database
  logTitle('Save the changed objects in the repository database');
  DB.SaveToRepository;
  log('Finished');
end;

procedure TfrmBuildForm.UpdateNewObjectsProperties(DB: TDelphiBooksDatabase);
begin
  // update the missing id properties (from new objects)
  logTitle('Fill new objects IDs');
  // TODO : à compléter
  log('Finished');
end;

procedure TfrmBuildForm.LoadRepositoryDatabase(RepositoryFolder: string;
  var DB: TDelphiBooksDatabase);
begin
  // load the repository database
  logTitle('Load the repository database');
  debuglog(RepositoryFolder);
  DB := TDelphiBooksDatabase.CreateFromRepository(RepositoryFolder);
  debuglog('Autors : ' + DB.Authors.Count.ToString);
  debuglog('Publishers : ' + DB.Publishers.Count.ToString);
  debuglog('Books : ' + DB.Books.Count.ToString);
  debuglog('Languages : ' + DB.Languages.Count.ToString);
  log('Finished');
end;

procedure TfrmBuildForm.FormCreate(Sender: TObject);
begin
  mmoLog.lines.clear;
  btnClose.Enabled := false;
  try
    tthread.CreateAnonymousThread(
      procedure
      begin
        try
          Execute;
        finally
          tthread.Synchronize(nil,
            procedure
            begin
              btnClose.Enabled := true;
            end);
        end;
      end).start;
  except
    btnClose.Enabled := true;
    raise;
  end;
end;

procedure TfrmBuildForm.log(ATxt: string);
begin
  tthread.Synchronize(nil,
    procedure
    begin
      mmoLog.lines.add(ATxt);
      mmoLog.GoToTextEnd;
    end);
end;

procedure TfrmBuildForm.logError(ATxt: string);
begin
  tthread.Synchronize(nil,
    procedure
    begin
      mmoLog.lines.add('');
      mmoLog.lines.add('*****************');
      mmoLog.lines.add('*** EXCEPTION ***');
      mmoLog.lines.add('*****************');
      mmoLog.lines.add(ATxt);
      mmoLog.lines.add('*****************');
      mmoLog.lines.add('');
      mmoLog.GoToTextEnd;
    end);
end;

procedure TfrmBuildForm.logTitle(ATxt: string);
begin
  tthread.Synchronize(nil,
    procedure
    begin
      mmoLog.lines.add('');
      mmoLog.lines.add('****************************************');
      mmoLog.lines.add(ATxt);
      mmoLog.lines.add('****************************************');
      mmoLog.lines.add('');
      mmoLog.GoToTextEnd;
    end);
end;

end.
