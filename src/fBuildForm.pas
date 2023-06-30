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
    procedure LoadRepositoryDatabase(DBFolder: string;
      var DB: TDelphiBooksDatabase);
    procedure UpdateNewObjectsProperties(DB: TDelphiBooksDatabase);
    procedure SaveRepositoryDatabase(DBFolder: string;
      DB: TDelphiBooksDatabase);
    procedure BuildWebSitePages(TemplateFolder, SiteFolder: string;
      DB: TDelphiBooksDatabase);
    procedure BuildWebSiteAPI(TemplateFolder, SiteFolder: string;
      DB: TDelphiBooksDatabase);
    procedure BuildWebSiteImages(DBFolder, SiteFolder: string;
      DB: TDelphiBooksDatabase);
    procedure getFolders(var DBFolder, TemplateFolder, SiteFolder: string);
    { D�clarations priv�es }
  public
    { D�clarations publiques }
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
  DBFolder, TemplateFolder, SiteFolder: string;
begin
  DB := nil;
  try
    getFolders(DBFolder, TemplateFolder, SiteFolder);

    LoadRepositoryDatabase(DBFolder, DB);
    try
      UpdateNewObjectsProperties(DB);
      BuildWebSitePages(TemplateFolder, SiteFolder, DB);
      BuildWebSiteAPI(TemplateFolder, SiteFolder, DB);
      BuildWebSiteImages(DBFolder, SiteFolder, DB);
      SaveRepositoryDatabase(DBFolder, DB);
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

procedure TfrmBuildForm.getFolders(var DBFolder, TemplateFolder,
  SiteFolder: string);
var
  ProgFolder: string;
  RootSiteRepositoryFolder: string;
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
  RootSiteRepositoryFolder := tpath.Combine(ProgFolder, '..');
  RootSiteRepositoryFolder := tpath.Combine(RootSiteRepositoryFolder, '..');
  RootSiteRepositoryFolder := tpath.Combine(RootSiteRepositoryFolder, '..');
  RootSiteRepositoryFolder := tpath.Combine(RootSiteRepositoryFolder,
    'lib-externes');
  RootSiteRepositoryFolder := tpath.Combine(RootSiteRepositoryFolder,
    'DelphiBooks-WebSite');
{$ENDIF}
  if RootSiteRepositoryFolder.isempty then
    raise exception.Create('Can''t define root repository path.');
  if not tdirectory.Exists(RootSiteRepositoryFolder) then
    raise exception.Create('Can''t find folder "' +
      RootSiteRepositoryFolder + '".');
  debuglog(RootSiteRepositoryFolder);

  // Database is in /database/datas folder in the WebSite repository
  DBFolder := tpath.Combine(RootSiteRepositoryFolder, 'database');
  DBFolder := tpath.Combine(DBFolder, 'datas');
  if DBFolder.isempty then
    raise exception.Create('Can''t define database path.');
  if not tdirectory.Exists(DBFolder) then
    raise exception.Create('Can''t find folder "' + DBFolder + '".');
  debuglog(DBFolder);

  // Templates are in /site-templates/templates folder
  TemplateFolder := tpath.Combine(RootSiteRepositoryFolder, 'site-templates');
  TemplateFolder := tpath.Combine(TemplateFolder, 'templates');
  if TemplateFolder.isempty then
    raise exception.Create('Can''t define templates path.');
  if not tdirectory.Exists(TemplateFolder) then
    raise exception.Create('Can''t find folder "' + TemplateFolder + '".');
  debuglog(TemplateFolder);

  // The generated pages are in /docs folder
  SiteFolder := tpath.Combine(RootSiteRepositoryFolder, 'docs');
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
  // TODO : � compl�ter
  log('Finished');
end;

procedure TfrmBuildForm.BuildWebSiteAPI(TemplateFolder, SiteFolder: string;
  DB: TDelphiBooksDatabase);
begin
  // build the API
  logTitle('Build the API files');
  // TODO : � compl�ter
  log('Finished');
end;

procedure TfrmBuildForm.BuildWebSitePages(TemplateFolder, SiteFolder: string;
  DB: TDelphiBooksDatabase);
begin
  // build the website
  logTitle('Build the web pages');
  // TODO : � compl�ter
  log('Finished');
end;

procedure TfrmBuildForm.debuglog(ATxt: string);
begin
{$IFDEF DEBUG}
  log(ATxt);
{$ENDIF}
end;

procedure TfrmBuildForm.SaveRepositoryDatabase(DBFolder: string;
  DB: TDelphiBooksDatabase);
begin
  // save the new objects in the repository database
  logTitle('Save the changed objects in the repository database');
  // TODO : � compl�ter
  log('Finished');
end;

procedure TfrmBuildForm.UpdateNewObjectsProperties(DB: TDelphiBooksDatabase);
begin
  // update the missing id properties (from new objects)
  logTitle('Fill new objects IDs');
  // TODO : � compl�ter
  log('Finished');
end;

procedure TfrmBuildForm.LoadRepositoryDatabase(DBFolder: string;
  var DB: TDelphiBooksDatabase);
begin
  // load the repository database
  logTitle('Load the repository database');
  // TODO : � compl�ter
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