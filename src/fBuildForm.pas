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
    AniIndicator1: TAniIndicator;
    procedure btnCloseClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  private
    procedure LoadRepositoryDatabase(RepositoryFolder: string;
      var DB: TDelphiBooksDatabase);
    procedure UpdateNewObjectsProperties(DB: TDelphiBooksDatabase);
    procedure SaveRepositoryDatabase(DB: TDelphiBooksDatabase);
    procedure BuildWebSitePages(TemplateFolder, DBFolder, SiteFolder: string;
      DB: TDelphiBooksDatabase);
    procedure BuildWebSiteAPI(TemplateFolder, DBFolder, SiteFolder: string;
      DB: TDelphiBooksDatabase);
    procedure BuildWebSiteImages(DBFolder, SiteFolder: string;
      DB: TDelphiBooksDatabase);
    procedure getFolders(var RootFolder, DBFolder, TemplateFolder,
      SiteFolder: string);
    procedure CreateAndSaveThumb(SiteFolder, CoverFilePath,
      ThumbFileName: string; AWidth, AHeight: integer);
    procedure RemoveThumbFile(SiteFolder, ThumbFileName: string;
      AWidth, AHeight: integer);
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
  DelphiBooks.Classes,
  uBuilder;

procedure TfrmBuildForm.btnCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmBuildForm.Execute;
var
  DB: TDelphiBooksDatabase;
  RootFolder, DBFolder, TemplateFolder, SiteFolder: string;
begin
  onErrorLog := logError;
  onDebugLog := debuglog;
  onLog := log;

  DB := nil;
  try
    getFolders(RootFolder, DBFolder, TemplateFolder, SiteFolder);

    LoadRepositoryDatabase(RootFolder, DB);
    try
      UpdateNewObjectsProperties(DB);
      BuildWebSitePages(TemplateFolder, DBFolder, SiteFolder, DB);
      BuildWebSiteAPI(TemplateFolder, DBFolder, SiteFolder, DB);
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
  RootFolder := tpath.Combine(ProgFolder, '..');
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
      if b.hasNewImage then
      begin
        CoverFilePath := tpath.Combine(DBFolder, b.GetImageFileName);
        ThumbFileName := b.PageName.Replace('.html',
          TDelphiBooksDatabase.CThumbExtension);
        if tfile.Exists(CoverFilePath) then
        begin
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
          CreateAndSaveThumb(SiteFolder, CoverFilePath, ThumbFileName,
            100, 100);
          CreateAndSaveThumb(SiteFolder, CoverFilePath, ThumbFileName,
            200, 200);
          CreateAndSaveThumb(SiteFolder, CoverFilePath, ThumbFileName,
            300, 300);
          CreateAndSaveThumb(SiteFolder, CoverFilePath, ThumbFileName,
            400, 400);
          CreateAndSaveThumb(SiteFolder, CoverFilePath, ThumbFileName,
            500, 500);
          CreateAndSaveThumb(SiteFolder, CoverFilePath, ThumbFileName,
            130, 110);
        end
        else
        begin
          logError('Missing cover picture for book "' + b.ToString + '".');
          RemoveThumbFile(SiteFolder, ThumbFileName, 100, 0);
          RemoveThumbFile(SiteFolder, ThumbFileName, 150, 0);
          RemoveThumbFile(SiteFolder, ThumbFileName, 200, 0);
          RemoveThumbFile(SiteFolder, ThumbFileName, 300, 0);
          RemoveThumbFile(SiteFolder, ThumbFileName, 400, 0);
          RemoveThumbFile(SiteFolder, ThumbFileName, 500, 0);
          RemoveThumbFile(SiteFolder, ThumbFileName, 0, 100);
          RemoveThumbFile(SiteFolder, ThumbFileName, 0, 200);
          RemoveThumbFile(SiteFolder, ThumbFileName, 0, 300);
          RemoveThumbFile(SiteFolder, ThumbFileName, 0, 400);
          RemoveThumbFile(SiteFolder, ThumbFileName, 0, 500);
          RemoveThumbFile(SiteFolder, ThumbFileName, 100, 100);
          RemoveThumbFile(SiteFolder, ThumbFileName, 200, 200);
          RemoveThumbFile(SiteFolder, ThumbFileName, 300, 300);
          RemoveThumbFile(SiteFolder, ThumbFileName, 400, 400);
          RemoveThumbFile(SiteFolder, ThumbFileName, 500, 500);
          RemoveThumbFile(SiteFolder, ThumbFileName, 130, 110);
        end;
        b.SetHasNewImage(false);
      end;

  log('Finished');
end;

procedure TfrmBuildForm.BuildWebSiteAPI(TemplateFolder, DBFolder,
  SiteFolder: string; DB: TDelphiBooksDatabase);
var
  l: TDelphiBooksLanguage;
  a: tdelphibooksauthor;
  p: tdelphibookspublisher;
  b: tdelphibooksbook;
  APIFolder, DestFolder: string;
begin
  // build the API
  logTitle('Build the API files');

  l := DB.Languages.GetItemByLanguage('en');
  if not assigned(l) then
    raise exception.Create
      ('Can''t find English language to generate the API files.');

  APIFolder := tpath.Combine(SiteFolder, 'api');
  if not tdirectory.Exists(APIFolder) then
    tdirectory.CreateDirectory(APIFolder);

  // **********
  // * Authors
  // **********

  DestFolder := tpath.Combine(APIFolder, 'a');
  if not tdirectory.Exists(APIFolder) then
    tdirectory.CreateDirectory(APIFolder);

  BuildPageFromTemplate(DB, l, tpath.Combine(TemplateFolder,
    'api-auteurs_tpl.txt'), tpath.Combine(DestFolder, 'all.json'), DBFolder);

  if DB.Authors.Count > 0 then
    for a in DB.Authors do
      BuildPageFromTemplate(DB, l, tpath.Combine(TemplateFolder,
        'api-auteur-dtl_tpl.txt'), tpath.Combine(DestFolder,
        a.id.ToString + '.json'), DBFolder, 'auteurs', a);

  // **********
  // * Publishers
  // **********

  DestFolder := tpath.Combine(APIFolder, 'p');
  if not tdirectory.Exists(APIFolder) then
    tdirectory.CreateDirectory(APIFolder);

  BuildPageFromTemplate(DB, l, tpath.Combine(TemplateFolder,
    'api-editeurs_tpl.txt'), tpath.Combine(DestFolder, 'all.json'), DBFolder);

  if DB.Publishers.Count > 0 then
    for p in DB.Publishers do
      BuildPageFromTemplate(DB, l, tpath.Combine(TemplateFolder,
        'api-editeur-dtl_tpl.txt'), tpath.Combine(DestFolder,
        p.id.ToString + '.json'), DBFolder, 'editeurs', p);

  // **********
  // * Books
  // **********

  DestFolder := tpath.Combine(APIFolder, 'b');
  if not tdirectory.Exists(APIFolder) then
    tdirectory.CreateDirectory(APIFolder);

  BuildPageFromTemplate(DB, l, tpath.Combine(TemplateFolder,
    'api-livres_tpl.txt'), tpath.Combine(DestFolder, 'all.json'), DBFolder);

  BuildPageFromTemplate(DB, l, tpath.Combine(TemplateFolder,
    'api-livres-recents_tpl.txt'), tpath.Combine(DestFolder, 'lastyear.json'),
    DBFolder);

  if DB.Books.Count > 0 then
    for b in DB.Books do
      BuildPageFromTemplate(DB, l, tpath.Combine(TemplateFolder,
        'api-livre-dtl_tpl.txt'), tpath.Combine(DestFolder,
        b.id.ToString + '.json'), DBFolder, 'livres', b);

  // **********
  // * Keywords
  // **********

  // TODO : implement "keywords" API files generation when available in the database

  log('Finished');
end;

procedure TfrmBuildForm.BuildWebSitePages(TemplateFolder, DBFolder,
  SiteFolder: string; DB: TDelphiBooksDatabase);
var
  CurLanguage, l: TDelphiBooksLanguage;
  a: tdelphibooksauthor;
  p: tdelphibookspublisher;
  b: tdelphibooksbook;
  DestFolder: string;
begin
  // build the website
  logTitle('Build the web pages');

  if DB.Languages.Count > 0 then
    for CurLanguage in DB.Languages do
      if not CurLanguage.LanguageISOCode.isempty then
      begin
        debuglog('Langue: ' + CurLanguage.LanguageISOCode);

        DestFolder := tpath.Combine(SiteFolder, CurLanguage.LanguageISOCode);
        if not tdirectory.Exists(DestFolder) then
          tdirectory.CreateDirectory(DestFolder);

        BuildPageFromTemplate(DB, CurLanguage, tpath.Combine(TemplateFolder,
          'index_tpl.html'), tpath.Combine(DestFolder, 'index.html'), DBFolder);

        BuildPageFromTemplate(DB, CurLanguage, tpath.Combine(TemplateFolder,
          'auteurs_tpl.html'), tpath.Combine(DestFolder, 'auteurs.html'),
          DBFolder);

        if DB.Authors.Count > 0 then
          for a in DB.Authors do
            BuildPageFromTemplate(DB, CurLanguage, tpath.Combine(TemplateFolder,
              'auteur_tpl.html'), tpath.Combine(DestFolder, a.PageName),
              DBFolder, 'auteurs', a);

        BuildPageFromTemplate(DB, CurLanguage, tpath.Combine(TemplateFolder,
          'editeurs_tpl.html'), tpath.Combine(DestFolder, 'editeurs.html'),
          DBFolder);

        if DB.Publishers.Count > 0 then
          for p in DB.Publishers do
            BuildPageFromTemplate(DB, CurLanguage, tpath.Combine(TemplateFolder,
              'editeur_tpl.html'), tpath.Combine(DestFolder, p.PageName),
              DBFolder, 'editeurs', p);

        BuildPageFromTemplate(DB, CurLanguage, tpath.Combine(TemplateFolder,
          'langues_tpl.html'), tpath.Combine(DestFolder, 'langues.html'),
          DBFolder);

        if DB.Languages.Count > 0 then
          for l in DB.Languages do
            BuildPageFromTemplate(DB, CurLanguage, tpath.Combine(TemplateFolder,
              'langue_tpl.html'), tpath.Combine(DestFolder, l.PageName),
              DBFolder, 'langues', l);

        {
          //"Readers" are not implemented in this project release

          BuildPageFromTemplate(DB, CurLanguage, tpath.Combine(TemplateFolder,
          'lecteurs_tpl.html'), tpath.Combine(DestFolder, 'lecteurs.html'),DBFolder);

          if DB.Readers.Count > 0 then
          for r in DB.Readers do
          BuildPageFromTemplate(DB, CurLanguage, tpath.Combine(TemplateFolder,
          'lecteur_tpl.html'), tpath.Combine(DestFolder, r.PageName),DBFolder,
          'lecteurs', r);
        }

        BuildPageFromTemplate(DB, CurLanguage, tpath.Combine(TemplateFolder,
          'livres_tpl.html'), tpath.Combine(DestFolder, 'livres.html'),
          DBFolder);

        BuildPageFromTemplate(DB, CurLanguage, tpath.Combine(TemplateFolder,
          'livres-par-date_tpl.html'), tpath.Combine(DestFolder,
          'livres-par-date.html'), DBFolder);

        if DB.Books.Count > 0 then
          for b in DB.Books do
            BuildPageFromTemplate(DB, CurLanguage, tpath.Combine(TemplateFolder,
              'livre_tpl.html'), tpath.Combine(DestFolder, b.PageName),
              DBFolder, 'livres', b);

        {
          //"Keywords" are not implemented in this project release

          BuildPageFromTemplate(DB, CurLanguage, tpath.Combine(TemplateFolder,
          'motscles_tpl.html'), tpath.Combine(DestFolder, 'motscles.html'));

          if DB.Keywords.Count > 0 then
          for k in DB.Keywords do
          BuildPageFromTemplate(DB, CurLanguage, tpath.Combine(TemplateFolder,
          'motcle_tpl.html'), tpath.Combine(DestFolder, k.PageName),
          'motscles', k);
        }
        // TODO : implement "keywords" pages generation when available in the database

        BuildPageFromTemplate(DB, CurLanguage, tpath.Combine(TemplateFolder,
          'rss_tpl.xml'), tpath.Combine(DestFolder, 'rss.xml'), DBFolder);

        BuildPageFromTemplate(DB, CurLanguage, tpath.Combine(TemplateFolder,
          'sitemap_tpl.xml'), tpath.Combine(DestFolder, 'sitemap.xml'),
          DBFolder);
      end;

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
      if item.id = CDelphiBooksNullID then
      begin
        NewID := DB.Languages.GetMaxID + 1;
        item.SetId(NewID);
        log('Id ' + NewID.ToString + ' => ' + item.ToString + ' (GUID=' +
          item.Guid + ')');
      end;

  log('- New authors');
  if DB.Authors.Count > 0 then
    for var item in DB.Authors do
      if item.id = CDelphiBooksNullID then
      begin
        NewID := DB.Authors.GetMaxID + 1;
        item.SetId(NewID);
        log('Id ' + NewID.ToString + ' => ' + item.ToString + ' (GUID=' +
          item.Guid + ')');
      end;

  log('- New publishers');
  if DB.Publishers.Count > 0 then
    for var item in DB.Publishers do
      if item.id = CDelphiBooksNullID then
      begin
        NewID := DB.Publishers.GetMaxID + 1;
        item.SetId(NewID);
        log('Id ' + NewID.ToString + ' => ' + item.ToString + ' (GUID=' +
          item.Guid + ')');
      end;

  log('- New books');
  if DB.Books.Count > 0 then
    for var item in DB.Books do
      if item.id = CDelphiBooksNullID then
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
  debuglog('Authors : ' + DB.Authors.Count.ToString);
  debuglog('Publishers : ' + DB.Publishers.Count.ToString);
  debuglog('Books : ' + DB.Books.Count.ToString);
  debuglog('Languages : ' + DB.Languages.Count.ToString);
  log('Finished');
end;

procedure TfrmBuildForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := btnClose.Enabled;
end;

procedure TfrmBuildForm.FormCreate(Sender: TObject);
begin
  mmoLog.lines.clear;
  btnClose.Enabled := false;
  AniIndicator1.Visible := true;
  AniIndicator1.Enabled := true;
  AniIndicator1.BringToFront;
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
              AniIndicator1.Visible := false;
              AniIndicator1.Enabled := false;
            end);
        end;
      end).start;
  except
    btnClose.Enabled := true;
    AniIndicator1.Visible := false;
    AniIndicator1.Enabled := false;
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

procedure TfrmBuildForm.RemoveThumbFile(SiteFolder, ThumbFileName: string;
AWidth, AHeight: integer);
var
  ThumbFilePath: string;
begin
  ThumbFilePath := tpath.Combine(tpath.Combine(SiteFolder, 'covers'),
    AWidth.ToString + 'x' + AHeight.ToString);
  ThumbFilePath := tpath.Combine(ThumbFilePath, ThumbFileName);
  if tfile.Exists(ThumbFilePath) then
    tfile.Delete(ThumbFilePath);
end;

end.
