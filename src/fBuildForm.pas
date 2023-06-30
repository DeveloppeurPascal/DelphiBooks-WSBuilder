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
    procedure CreateAndSaveThumb(SiteFolder, CoverFilePath,
      ThumbFileName: string; AWidth, AHeight: integer);
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
var
  b: tdelphibooksbook;
  CoverFilePath, ThumbFileName: string;
begin
  // build the images thumbs
  logTitle('Build the images');

  if (DB.Books.Count > 0) then
    for b in DB.Books do
    begin
      CoverFilePath := tpath.Combine(DBFolder, 'b-' + b.Guid + '.png');
      if tfile.Exists(CoverFilePath) then
      begin
        ThumbFileName := b.PageName.Replace('.html',
          TDelphiBooksDatabase.CThumbExtension);
        CreateAndSaveThumb(SiteFolder, CoverFilePath, ThumbFileName, 100, 0);
        CreateAndSaveThumb(SiteFolder, CoverFilePath, ThumbFileName, 150, 0);
        CreateAndSaveThumb(SiteFolder, CoverFilePath, ThumbFileName, 200, 0);
        CreateAndSaveThumb(SiteFolder, CoverFilePath, ThumbFileName, 300, 0);
        CreateAndSaveThumb(SiteFolder, CoverFilePath, ThumbFileName, 400, 0);
        CreateAndSaveThumb(SiteFolder, CoverFilePath, ThumbFileName, 500, 0);
        CreateAndSaveThumb(SiteFolder, CoverFilePath, ThumbFileName, 0, 100);
        CreateAndSaveThumb(SiteFolder, CoverFilePath, ThumbFileName, 0, 200);
        CreateAndSaveThumb(SiteFolder, CoverFilePath, ThumbFileName, 0, 300);
        CreateAndSaveThumb(SiteFolder, CoverFilePath, ThumbFileName, 0, 400);
        CreateAndSaveThumb(SiteFolder, CoverFilePath, ThumbFileName, 0, 500);
        CreateAndSaveThumb(SiteFolder, CoverFilePath, ThumbFileName, 100, 100);
        CreateAndSaveThumb(SiteFolder, CoverFilePath, ThumbFileName, 200, 200);
        CreateAndSaveThumb(SiteFolder, CoverFilePath, ThumbFileName, 300, 300);
        CreateAndSaveThumb(SiteFolder, CoverFilePath, ThumbFileName, 400, 400);
        CreateAndSaveThumb(SiteFolder, CoverFilePath, ThumbFileName, 500, 500);
        CreateAndSaveThumb(SiteFolder, CoverFilePath, ThumbFileName, 130, 110);
      end
      else
        logError('Missing cover picture for book ' + b.ToString);
    end;

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

procedure TfrmBuildForm.CreateAndSaveThumb(SiteFolder, CoverFilePath,
  ThumbFileName: string; AWidth, AHeight: integer);
var
  bitmap: TBitmap;
  ThumbFilePath: string;
begin
  ThumbFilePath := tpath.Combine(tpath.Combine(SiteFolder, 'covers'),
    AWidth.ToString + 'x' + AHeight.ToString);
  if not tdirectory.Exists(ThumbFilePath) then
  begin
    tdirectory.CreateDirectory(ThumbFilePath);
    log('Created thumb directory : ' + ThumbFilePath);
  end;

  ThumbFilePath := tpath.Combine(ThumbFilePath, ThumbFileName);
  // TODO : find a way to not erase pictures if they don't have changed
  // if (not tfile.Exists(FichierDestination)) or
  // (tfile.GetLastWriteTime(PhotoARedimensionner) > tfile.GetLastWriteTime
  // (FichierDestination)) then

  bitmap := TBitmap.CreateFromFile(CoverFilePath);
  try
    if (AWidth > 0) then
    begin
      if (AHeight > 0) then
        // TODO : corriger le ratio largeur / hauteur pour gérer un stretch ou prendre un morceau de l'image
        bitmap.Resize(AWidth, AHeight)
      else
        bitmap.Resize(AWidth, (bitmap.Height * AWidth) div bitmap.Width);
    end
    else if (AHeight > 0) then
      bitmap.Resize((bitmap.Width * AHeight) div bitmap.Height, AHeight)
    else
      raise exception.Create('Unknow final thumb size for picture ' +
        ThumbFileName);

    bitmap.SaveToFile(ThumbFilePath);
  finally
    bitmap.free;
  end;
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
var
  NewID: integer;
begin
  // update the missing id properties (from new objects)
  logTitle('Fill new objects IDs');

  log('- New languages');
  if DB.Languages.Count > 0 then
    for var item in DB.Languages do
      if item.Id = CDelphiBooksNullID then
      begin
        NewID := DB.Languages.GetMaxID + 1;
        item.SetId(NewID);
        log('Id ' + NewID.ToString + ' => ' + item.ToString + ' (GUID=' +
          item.Guid + ')');
      end;

  log('- New authors');
  if DB.authors.Count > 0 then
    for var item in DB.authors do
      if item.Id = CDelphiBooksNullID then
      begin
        NewID := DB.authors.GetMaxID + 1;
        item.SetId(NewID);
        log('Id ' + NewID.ToString + ' => ' + item.ToString + ' (GUID=' +
          item.Guid + ')');
      end;

  log('- New publishers');
  if DB.publishers.Count > 0 then
    for var item in DB.publishers do
      if item.Id = CDelphiBooksNullID then
      begin
        NewID := DB.publishers.GetMaxID + 1;
        item.SetId(NewID);
        log('Id ' + NewID.ToString + ' => ' + item.ToString + ' (GUID=' +
          item.Guid + ')');
      end;

  log('- New books');
  if DB.Books.Count > 0 then
    for var item in DB.Books do
      if item.Id = CDelphiBooksNullID then
      begin
        NewID := DB.Books.GetMaxID + 1;
        item.SetId(NewID);
        log('Id ' + NewID.ToString + ' => ' + item.ToString + ' (GUID=' +
          item.Guid + ')');
      end;

  log('Finished');
end;

procedure TfrmBuildForm.LoadRepositoryDatabase(RepositoryFolder: string;
  var DB: TDelphiBooksDatabase);
begin
  // load the repository database
  logTitle('Load the repository database');
  debuglog(RepositoryFolder);
  DB := TDelphiBooksDatabase.CreateFromRepository(RepositoryFolder);
  debuglog('Authors : ' + DB.authors.Count.ToString);
  debuglog('Publishers : ' + DB.publishers.Count.ToString);
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
