unit uBuilder;

interface

uses
  DelphiBooks.Classes,
  DelphiBooks.DB.Repository;

type
  TLogEvent = procedure(Txt: string) of object;

var
  onErrorLog: TLogEvent;
  onDebugLog: TLogEvent;
  onLog: TLogEvent;

procedure BuildPageFromTemplate(ADB: TDelphiBooksDatabase;
  ALang: TDelphiBooksLanguage; ATemplateFile, ADestFile: string;
  DBFolder: string; ADataName: string = ''; AItem: TDelphiBooksItem = nil);

implementation

uses
  System.DateUtils,
  System.SysUtils,
  System.IOUtils,
  System.Generics.Collections,
  System.StrUtils,
  DelphiBooks.Tools;

type
  TBookFilterProc = reference to function(ABook: TDelphiBooksBook): boolean;
  TAuthorFilterProc = reference to function
    (AAuthor: TDelphiBooksAuthor): boolean;
  TPublisherFilterProc = reference to function
    (APublisher: TDelphiBooksPublisher): boolean;
  TLanguageFilterProc = reference to function
    (ALanguage: TDelphiBooksLanguage): boolean;
  TDescriptionFilterProc = reference to function(ADescription
    : TDelphiBooksDescription): boolean;
  TTableOfContentFilterProc = reference to function
    (ATOC: TDelphiBooksTableOfContent): boolean;
  TKeywordFilterProc = reference to function
    (AKeyword: TDelphiBooksKeyword): boolean;

  TItemsList = class(TList<TDelphiBooksItem>)
  private
    FCurrentIndex: integer;
  public
    function AsBook: TDelphiBooksBook;
    function AsPublisher: TDelphiBooksPublisher;
    function AsAuthor: TDelphiBooksAuthor;
    function AsLanguage: TDelphiBooksLanguage;
    function AsDescription: TDelphiBooksDescription;
    function AsTOC: TDelphiBooksTableOfContent;
    function AsKeyword: TDelphiBooksKeyword;
    procedure SelectBooks(ABooks: TDelphiBooksBooksObjectList;
      AFilterProc: TBookFilterProc = nil);
    procedure SelectAuthors(AAuthors: TDelphiBooksAuthorsObjectList;
      AFilterProc: TAuthorFilterProc = nil);
    procedure SelectPublishers(APublishers: TDelphiBooksPublishersObjectList;
      AFilterProc: TPublisherFilterProc = nil);
    procedure SelectLanguages(ALanguages: TDelphiBooksLanguagesObjectList;
      AFilterProc: TLanguageFilterProc = nil);
    procedure SelectDescriptions(ADescriptions
      : TDelphiBooksDescriptionsObjectList;
      AFilterProc: TDescriptionFilterProc = nil);
    procedure SelectTableOfContents(ATableOfContents
      : TDelphiBooksTableOfContentsObjectList;
      AFilterProc: TTableOfContentFilterProc = nil);
    procedure SelectKeywords(AKeywords: TDelphiBooksKeywordsObjectList;
      AFilterProc: TKeywordFilterProc = nil);
    Procedure Next;
    function EOF: boolean;
    constructor Create(AItem: TDelphiBooksItem = nil);
  end;

procedure BuildPageFromTemplate(ADB: TDelphiBooksDatabase;
  ALang: TDelphiBooksLanguage; ATemplateFile, ADestFile: string;
  DBFolder: string; ADataName: string; AItem: TDelphiBooksItem);
var
  LShortBooksList: TDelphiBooksBookShortsObjectList;
  LShortAuthorsList: TDelphiBooksAuthorShortsObjectList;
  LShortPublishersList: TDelphiBooksPublisherShortsObjectList;
  LTOCsList: TDelphiBooksTableOfContentsObjectList;
  LDescriptionsList: TDelphiBooksDescriptionsObjectList;
  LKeywordsList: TDelphiBooksKeywordsObjectList;
  Source, Destination, PrecedentFichier: string;
  DelphiBooksItemsLists: TDictionary<string, TItemsList>;
  qry: TItemsList;
  PosCurseur, PosMarqueur: integer;
  Marqueur: string;
  Listes: TDictionary<string, string>;
  ListePrecedentePosListe: tstack<integer>;
  PosListe: integer;
  PremierElementListesPrecedentes: tstack<boolean>;
  PremierElementListeEnCours: boolean;
  ListePrecedenteAvaitElem: tstack<boolean>;
  ListeAvaitElem: boolean;
  AfficheBlocsPrecedents: tstack<boolean>;
  AfficheBlocEnCours: boolean;
  ListeNomTable: string;

  function GetQry(NomTable: string): TItemsList;
  begin
    // onDebugLog('GetQry : ' + NomTable);
    if (not DelphiBooksItemsLists.TryGetValue(NomTable, result)) then
    begin
      result := TItemsList.Create;
      DelphiBooksItemsLists.Add(NomTable, result);
    end;
  end;

  function RemplaceMarqueur(Marqueur: string): string;
  begin
    // onDebugLog('Tag : ' + Marqueur);
    result := '';
    if Marqueur = 'livre_code' then
    begin
      qry := GetQry('livres');
      if (not qry.EOF) then
        result := qry.AsBook.id.tostring;
    end
    else if Marqueur = 'livre_titre' then
    begin
      qry := GetQry('livres');
      if (not qry.EOF) then
        result := qry.AsBook.title;
    end
    else if Marqueur = 'livre_titre-xml' then
    begin
      qry := GetQry('livres');
      if (not qry.EOF) then
        result := qry.AsBook.title.Replace('&', 'and');
    end
    else if Marqueur = 'livre_isbn10' then
    begin
      qry := GetQry('livres');
      if (not qry.EOF) then
        result := qry.AsBook.isbn10;
    end
    else if Marqueur = 'livre_gencod' then
    begin
      qry := GetQry('livres');
      if (not qry.EOF) then
        result := qry.AsBook.isbn13;
    end
    else if Marqueur = 'livre_anneedesortie' then
    begin
      qry := GetQry('livres');
      if (not qry.EOF) then
        result := qry.AsBook.PublishedDateYYYY;
    end
    else if Marqueur = 'livre_datedesortie' then
    begin
      qry := GetQry('livres');
      if (not qry.EOF) then
        result := Date8ToString(qry.AsBook.PublishedDateYYYYMMDD);
    end
    else if Marqueur = 'livre_datedesortie-iso' then
    begin
      qry := GetQry('livres');
      if (not qry.EOF) then
        result := Date8ToStringISO(qry.AsBook.PublishedDateYYYYMMDD);
    end
    else if Marqueur = 'livre_datedesortie-rfc822' then
    begin
      qry := GetQry('livres');
      if (not qry.EOF) then
        result := Date8ToStringRFC822(qry.AsBook.PublishedDateYYYYMMDD);
    end
    else if Marqueur = 'livre_url_site' then
    begin
      qry := GetQry('livres');
      if (not qry.EOF) then
        result := qry.AsBook.WebSiteURL;
    end
    else if Marqueur = 'livre_nom_page' then
    begin
      qry := GetQry('livres');
      if (not qry.EOF) then
        result := qry.AsBook.PageName;
    end
    else if Marqueur = 'livre_langue_libelle' then
    begin
      qry := GetQry('livres');
      if (not qry.EOF) then
        result := ADB.Languages.GetItemByLanguage
          (qry.AsBook.LanguageISOCode).Text;
    end
    else if Marqueur = 'livre_langue_nom_page' then
    begin
      qry := GetQry('livres');
      if (not qry.EOF) then
        result := ADB.Languages.GetItemByLanguage
          (qry.AsBook.LanguageISOCode).PageName;
    end
    else if Marqueur = 'livre_langue_code_iso' then
    begin
      qry := GetQry('livres');
      if (not qry.EOF) then
        result := qry.AsBook.LanguageISOCode;
    end
    else if Marqueur = 'livre_photo' then
    begin
      qry := GetQry('livres');
      if (not qry.EOF) then
        result := qry.AsBook.PageName.Replace('.html',
          TDelphiBooksDatabase.CThumbExtension);
    end
    {
      //
      // Readers and there comments are not available in this release
      //
      else if Marqueur = 'livre_commentaire' then
      begin
      qry := GetQry('livre_commentaires');
      if (not qry.EOF) then
      result := qry.FieldByName('commentaire').asstring;
      end
      else if Marqueur = 'livre_commentaire_langue_libelle' then
      begin
      qry := GetQry('livre_commentaires');
      if (not qry.EOF) then
      result := qry.FieldByName('langue_libelle').asstring;
      end
      else if Marqueur = 'livre_commentaire_langue_code_iso' then
      begin
      qry := GetQry('livre_commentaires');
      if (not qry.EOF) then
      result := qry.FieldByName('langue_code_iso').asstring;
      end
      else if Marqueur = 'livre_commentaire_langue_nom_page' then
      begin
      qry := GetQry('livre_commentaires');
      if (not qry.EOF) then
      result := qry.FieldByName('langue_nom_page').asstring;
      end
      else if Marqueur = 'livre_commentaire_date' then
      begin
      qry := GetQry('livre_commentaires');
      if (not qry.EOF) then
      result := Date8ToString(qry.FieldByName('dateducommentaire').asstring);
      end
      else if Marqueur = 'livre_commentaire_pseudo' then
      begin
      qry := GetQry('livre_commentaires');
      if (not qry.EOF) then
      result := qry.FieldByName('pseudo').asstring;
      end
      else if Marqueur = 'livre_commentaire_nom_page' then
      begin
      qry := GetQry('livre_commentaires');
      if (not qry.EOF) then
      result := qry.FieldByName('nom_page').asstring;
      end
    }
    else if Marqueur = 'livre_tabledesmatieres' then
    begin
      qry := GetQry('livre_tablesdesmatieres');
      if (not qry.EOF) then
        result := qry.AsTOC.Text;
    end
    else if Marqueur = 'livre_tabledesmatieres_langue_libelle' then
    begin
      qry := GetQry('livre_tablesdesmatieres');
      if (not qry.EOF) then
        result := ADB.Languages.GetItemByLanguage
          (qry.AsTOC.LanguageISOCode).Text;
    end
    else if Marqueur = 'livre_tabledesmatieres_langue_code_iso' then
    begin
      qry := GetQry('livre_tablesdesmatieres');
      if (not qry.EOF) then
        result := qry.AsTOC.LanguageISOCode;
    end
    else if Marqueur = 'livre_tabledesmatieres_langue_nom_page' then
    begin
      qry := GetQry('livre_tablesdesmatieres');
      if (not qry.EOF) then
        result := ADB.Languages.GetItemByLanguage
          (qry.AsTOC.LanguageISOCode).PageName;
    end
    else if Marqueur = 'livre_description' then
    begin
      qry := GetQry('livre_descriptions');
      if (not qry.EOF) then
        result := qry.AsDescription.Text;
    end
    else if Marqueur = 'livre_description_langue_libelle' then
    begin
      qry := GetQry('livre_descriptions');
      if (not qry.EOF) then
        result := ADB.Languages.GetItemByLanguage
          (qry.AsDescription.LanguageISOCode).Text;
    end
    else if Marqueur = 'livre_description_langue_code_iso' then
    begin
      qry := GetQry('livre_descriptions');
      if (not qry.EOF) then
        result := qry.AsDescription.LanguageISOCode;
    end
    else if Marqueur = 'livre_description_langue_nom_page' then
    begin
      qry := GetQry('livre_descriptions');
      if (not qry.EOF) then
        result := ADB.Languages.GetItemByLanguage
          (qry.AsDescription.LanguageISOCode).PageName;
    end
    else if Marqueur = 'motcle_libelle' then
    begin
      qry := GetQry('motscles');
      if (not qry.EOF) then
        result := qry.AsKeyword.Text;
    end
    else if Marqueur = 'motcle_nom_page' then
    begin
      qry := GetQry('motscles');
      if (not qry.EOF) then
        result := qry.AsKeyword.PageName;
    end
    {
      //
      // Readers are not available in this release
      //

      else if Marqueur = 'lecteur_pseudo' then
      begin
      qry := GetQry('lecteurs');
      if (not qry.EOF) then
      result := qry.FieldByName('pseudo').asstring;
      end
      else if Marqueur = 'lecteur_url_site' then
      begin
      qry := GetQry('lecteurs');
      if (not qry.EOF) then
      result := qry.FieldByName('url_site').asstring;
      end
      else if Marqueur = 'lecteur_nom_page' then
      begin
      qry := GetQry('lecteurs');
      if (not qry.EOF) then
      result := qry.FieldByName('nom_page').asstring;
      end
      else if Marqueur = 'lecteur_photo' then
      begin
      qry := GetQry('lecteurs');
      if (not qry.EOF) then
      result := qry.FieldByName('nom_page').asstring.Replace('.html',
      CImageExtension);
      end
    }
    else if Marqueur = 'langue_libelle' then
    begin
      qry := GetQry('langues');
      if (not qry.EOF) then
        result := qry.AsLanguage.Text;
    end
    else if Marqueur = 'langue_code_iso' then
    begin
      qry := GetQry('langues');
      if (not qry.EOF) then
        result := qry.AsLanguage.LanguageISOCode;
    end
    else if Marqueur = 'langue_nom_page' then
    begin
      qry := GetQry('langues');
      if (not qry.EOF) then
        result := qry.AsLanguage.PageName;
    end
    else if Marqueur = 'langue_photo' then
    begin
      qry := GetQry('langues');
      if (not qry.EOF) then
        result := qry.AsLanguage.PageName.Replace('.html',
          TDelphiBooksDatabase.CThumbExtension);
    end
    else if Marqueur = 'page_langue_libelle' then
    begin
      result := ALang.Text;
    end
    else if Marqueur = 'page_langue_code_iso' then
    begin
      result := ALang.LanguageISOCode;
    end
    else if Marqueur = 'page_langue_nom_page' then
    begin
      result := ALang.PageName;
    end
    else if Marqueur = 'page_langue_photo' then
    begin
      result := ALang.PageName.Replace('.html',
        TDelphiBooksDatabase.CThumbExtension);
    end
    else if Marqueur = 'page_copyright_annees' then
    begin
      if yearof(now) > 2020 then
        result := '2020-' + yearof(now).tostring
      else
        result := '2020';
    end
    else if Marqueur = 'page_filename' then
    begin
      result := tpath.GetFileName(ADestFile);
    end
    else if Marqueur = 'page_url' then
    begin
      result := 'https://delphi-books.com/' + ALang.LanguageISOCode + '/' +
        tpath.GetFileName(ADestFile);
    end
    else if Marqueur = 'editeur_code' then
    begin
      qry := GetQry('editeurs');
      if (not qry.EOF) then
        result := qry.AsPublisher.id.tostring;
    end
    else if Marqueur = 'editeur_raison_sociale' then
    begin
      qry := GetQry('editeurs');
      if (not qry.EOF) then
        result := qry.AsPublisher.CompanyName;
    end
    else if Marqueur = 'editeur_url_site' then
    begin
      qry := GetQry('editeurs');
      if (not qry.EOF) then
        result := qry.AsPublisher.WebSiteURL;
    end
    else if Marqueur = 'editeur_nom_page' then
    begin
      qry := GetQry('editeurs');
      if (not qry.EOF) then
        result := qry.AsPublisher.PageName;
    end
    else if Marqueur = 'editeur_photo' then
    begin
      qry := GetQry('editeurs');
      if (not qry.EOF) then
        result := qry.AsPublisher.PageName.Replace('.html',
          TDelphiBooksDatabase.CThumbExtension);
    end
    else if Marqueur = 'editeur_description' then
    begin
      qry := GetQry('editeur_descriptions');
      if (not qry.EOF) then
        result := qry.AsDescription.Text;
    end
    else if Marqueur = 'editeur_description_langue_libelle' then
    begin
      qry := GetQry('editeur_descriptions');
      if (not qry.EOF) then
        result := ADB.Languages.GetItemByLanguage
          (qry.AsDescription.LanguageISOCode).Text;
    end
    else if Marqueur = 'editeur_description_langue_code_iso' then
    begin
      qry := GetQry('editeur_descriptions');
      if (not qry.EOF) then
        result := qry.AsDescription.LanguageISOCode;
    end
    else if Marqueur = 'editeur_description_langue_nom_page' then
    begin
      qry := GetQry('editeur_descriptions');
      if (not qry.EOF) then
        result := ADB.Languages.GetItemByLanguage
          (qry.AsDescription.LanguageISOCode).PageName;
    end
    else if Marqueur = 'auteur_code' then
    begin
      qry := GetQry('auteurs');
      if (not qry.EOF) then
        result := qry.AsAuthor.id.tostring;
    end
    else if Marqueur = 'auteur_nom' then
    begin
      qry := GetQry('auteurs');
      if (not qry.EOF) then
        result := qry.AsAuthor.LastName;
    end
    else if Marqueur = 'auteur_prenom' then
    begin
      qry := GetQry('auteurs');
      if (not qry.EOF) then
        result := qry.AsAuthor.FirstName;
    end
    else if Marqueur = 'auteur_pseudo' then
    begin
      qry := GetQry('auteurs');
      if (not qry.EOF) then
        result := qry.AsAuthor.Pseudo;
    end
    else if Marqueur = 'auteur_libelle' then
    begin
      qry := GetQry('auteurs');
      if (not qry.EOF) then
        result := qry.AsAuthor.PublicName;
    end
    else if Marqueur = 'auteur_url_site' then
    begin
      qry := GetQry('auteurs');
      if (not qry.EOF) then
        result := qry.AsAuthor.WebSiteURL;
    end
    else if Marqueur = 'auteur_nom_page' then
    begin
      qry := GetQry('auteurs');
      if (not qry.EOF) then
        result := qry.AsAuthor.PageName;
    end
    else if Marqueur = 'auteur_photo' then
    begin
      qry := GetQry('auteurs');
      if (not qry.EOF) then
        result := qry.AsAuthor.PageName.Replace('.html',
          TDelphiBooksDatabase.CThumbExtension);
    end
    else if Marqueur = 'auteur_description' then
    begin
      qry := GetQry('auteur_descriptions');
      if (not qry.EOF) then
        result := qry.AsDescription.Text;
    end
    else if Marqueur = 'auteur_description_langue_libelle' then
    begin
      qry := GetQry('auteur_descriptions');
      if (not qry.EOF) then
        result := ADB.Languages.GetItemByLanguage
          (qry.AsDescription.LanguageISOCode).Text;
    end
    else if Marqueur = 'auteur_description_langue_code_iso' then
    begin
      qry := GetQry('auteur_descriptions');
      if (not qry.EOF) then
        result := qry.AsDescription.LanguageISOCode;
    end
    else if Marqueur = 'auteur_description_langue_nom_page' then
    begin
      qry := GetQry('auteur_descriptions');
      if (not qry.EOF) then
        result := ADB.Languages.GetItemByLanguage
          (qry.AsDescription.LanguageISOCode).Text;
    end
    else if Marqueur = 'date' then
    begin
      result := Date8ToString(DateToString8(now));
    end
    else if Marqueur = 'date-iso' then
    begin
      result := Date8ToStringISO(DateToString8(now));
    end
    else if Marqueur = 'date-rfc822' then
    begin
      result := Date8ToStringRFC822(DateToString8(now));
    end
    else
      raise exception.Create('Unknown tag "' + Marqueur + '" in template "' +
        ATemplateFile + '".');
  end;

begin
  onDebugLog('Template : ' + tpath.GetFileNameWithoutExtension(ATemplateFile));

  if assigned(AItem) then
    onDebugLog('Item "' + AItem.tostring + '" from "' + ADataName + '".');

  if not tfile.Exists(ATemplateFile) then
    raise exception.Create('Template file "' + ATemplateFile + '" not found.');
  try
    Source := tfile.ReadAllText(ATemplateFile, tencoding.UTF8);
  except
    raise exception.Create('Can''t load "' + ATemplateFile + '".');
  end;

  if ADestFile.IsEmpty then
    raise exception.Create('Empty page name for "' + AItem.tostring + '" from "'
      + ADataName + '".');

  DelphiBooksItemsLists := TDictionary<string, TItemsList>.Create;
  try
    if (not ADataName.IsEmpty) and assigned(AItem) then
      DelphiBooksItemsLists.Add(ADataName, TItemsList.Create(AItem));
    Listes := TDictionary<string, string>.Create;
    try
      PremierElementListeEnCours := false;
      PremierElementListesPrecedentes := tstack<boolean>.Create;
      try
        ListeAvaitElem := false;
        ListePrecedenteAvaitElem := tstack<boolean>.Create;
        try
          AfficheBlocEnCours := true;
          AfficheBlocsPrecedents := tstack<boolean>.Create;
          try
            PosListe := length(Source);
            ListePrecedentePosListe := tstack<integer>.Create;
            try
              Destination := '';
              PosCurseur := 0;
              try
                while (PosCurseur < length(Source)) do
                begin
                  PosMarqueur := Source.IndexOf('!$', PosCurseur);
                  if (PosMarqueur >= 0) then
                  begin // tag trouvé, on le traite
                    if AfficheBlocEnCours then
                      Destination := Destination + Source.Substring(PosCurseur,
                        PosMarqueur - PosCurseur);
                    Marqueur := Source.Substring(PosMarqueur + 2,
                      Source.IndexOf('$!', PosMarqueur + 2) - PosMarqueur -
                      2).ToLower;
                    if Marqueur.StartsWith('liste_') then
                    begin
                      // ne traite pas de listes imbriquées
{$REGION 'listes gérées par le logiciel'}
                      if Marqueur = 'liste_livres' then
                      begin
                        ListeNomTable := 'livres';
                        ADB.Books.SortByTitle;
                        qry := GetQry(ListeNomTable);
                        qry.SelectBooks(ADB.Books);
                      end
                      else if Marqueur = 'liste_livres-par_date' then
                      begin
                        ListeNomTable := 'livres';
                        ADB.Books.SortByPublishedDateDesc;
                        qry := GetQry(ListeNomTable);
                        qry.SelectBooks(ADB.Books);
                      end
                      else if Marqueur = 'liste_livres_recents' then
                      begin
                        // que les livres édités depuis 1 an (année glissante)
                        ListeNomTable := 'livres';
                        ADB.Books.SortByPublishedDateDesc;
                        var
                        OneYearAgo := DateToString8(incyear(now, -1));
                        qry := GetQry(ListeNomTable);
                        qry.SelectBooks(ADB.Books,
                          function(ABook: TDelphiBooksBook): boolean
                          begin
                            result := ABook.PublishedDateYYYYMMDD > OneYearAgo;
                          end);
                      end
                      else if Marqueur = 'liste_livres_derniers_ajouts' then
                      begin
                        // que les 14 derniers (7 par ligne dans le design classique du site, donc 2 lignes)
                        ListeNomTable := 'livres';
                        ADB.Books.SortByIdDesc;
                        var
                          nb: byte := 0;
                        qry := GetQry(ListeNomTable);
                        qry.SelectBooks(ADB.Books,
                          function(ABook: TDelphiBooksBook): boolean
                          begin
                            if (nb < 14) then
                            begin
                              result := true;
                              inc(nb);
                            end
                            else
                              result := false;
                          end);
                      end
                      else if Marqueur = 'liste_livres_par_editeur' then
                      begin
                        ADB.Books.SortByTitle;
                        qry := GetQry('editeurs');
                        try
                          LShortBooksList := qry.AsPublisher.Books;
                        except
                          LShortBooksList := nil;
                        end;
                        ListeNomTable := 'livres';
                        qry := GetQry(ListeNomTable);
                        qry.SelectBooks(ADB.Books,
                          function(ABook: TDelphiBooksBook): boolean
                          begin
                            result := assigned(LShortBooksList) and
                              assigned(LShortBooksList.GetItemByID(ABook.id));
                          end);
                      end
                      else if Marqueur = 'liste_livres_par_auteur' then
                      begin
                        ADB.Books.SortByTitle;
                        qry := GetQry('auteurs');
                        try
                          LShortBooksList := qry.AsAuthor.Books;
                        except
                          LShortBooksList := nil;
                        end;
                        ListeNomTable := 'livres';
                        qry := GetQry(ListeNomTable);
                        qry.SelectBooks(ADB.Books,
                          function(ABook: TDelphiBooksBook): boolean
                          begin
                            result := assigned(LShortBooksList) and
                              assigned(LShortBooksList.GetItemByID(ABook.id));
                          end);
                      end
                      else if Marqueur = 'liste_livres_par_motcle' then
                      begin
                        raise exception.Create
                          ('"liste_livres_par_motcle" is not available in this release');
                      end
                      else if Marqueur = 'liste_livres_par_langue' then
                      begin
                        ADB.Books.SortByTitle;
                        qry := GetQry('langues');
                        var
                        ISO := qry.AsLanguage.LanguageISOCode;
                        ListeNomTable := 'livres';
                        qry := GetQry(ListeNomTable);
                        qry.SelectBooks(ADB.Books,
                          function(ABook: TDelphiBooksBook): boolean
                          begin
                            result := (ABook.LanguageISOCode = ISO);
                          end);
                      end
                      {
                        else if Marqueur = 'liste_commentaires_par_livre' then
                        begin
                        raise exception.Create
                        ('"liste_commentaires_par_livre" is not available in this release');
                        end
                      }
                      else if Marqueur = 'liste_tabledesmatieres_par_livre' then
                      begin
                        qry := GetQry('livres');
                        try
                          LTOCsList := qry.AsBook.TOCs;
                        except
                          LTOCsList := nil;
                        end;
                        ListeNomTable := 'livre_tablesdesmatieres';
                        qry := GetQry(ListeNomTable);
                        qry.SelectTableOfContents(LTOCsList);
                      end
                      else if Marqueur = 'liste_descriptions_par_livre' then
                      begin
                        qry := GetQry('livres');
                        try
                          LDescriptionsList := qry.AsBook.Descriptions;
                        except
                          LDescriptionsList := nil;
                        end;
                        ListeNomTable := 'livre_descriptions';
                        qry := GetQry(ListeNomTable);
                        qry.SelectDescriptions(LDescriptionsList);
                      end
                      { else if Marqueur = 'liste_motscles' then
                        begin
                        raise exception.Create
                        ('not implemented in this release');
                        ListeNomTable := 'motscles';
                        end
                      }
                      else if Marqueur = 'liste_motscles_par_livre' then
                      begin
                        qry := GetQry('livres');
                        try
                          LKeywordsList := qry.AsBook.Keywords;
                        except
                          LKeywordsList := nil;
                        end;
                        ListeNomTable := 'motscles';
                        qry := GetQry(ListeNomTable);
                        qry.SelectKeywords(LKeywordsList);
                      end
                      {
                        // "readers" not implemented in this release
                        else if Marqueur = 'liste_lecteurs' then
                        begin
                        sql := 'select * from lecteurs order by pseudo';
                        ListeNomTable := 'lecteurs';
                        end
                      }
                      else if Marqueur = 'liste_langues' then
                      begin
                        ADB.Languages.SortByText;
                        ListeNomTable := 'langues';
                        qry := GetQry(ListeNomTable);
                        qry.SelectLanguages(ADB.Languages);
                      end
                      else if Marqueur = 'liste_editeurs' then
                      begin
                        ADB.Publishers.SortByCompanyName;
                        ListeNomTable := 'editeurs';
                        qry := GetQry(ListeNomTable);
                        qry.SelectPublishers(ADB.Publishers);
                      end
                      else if Marqueur = 'liste_editeurs_par_livre' then
                      begin
                        ADB.Publishers.SortByCompanyName;
                        qry := GetQry('livres');
                        try
                          LShortPublishersList := qry.AsBook.Publishers;
                        except
                          LShortPublishersList := nil;
                        end;
                        ListeNomTable := 'editeurs';
                        qry := GetQry(ListeNomTable);
                        qry.SelectPublishers(ADB.Publishers,
                          function(APublisher: TDelphiBooksPublisher): boolean
                          begin
                            result := assigned(LShortPublishersList) and
                              assigned(LShortPublishersList.GetItemByID
                              (APublisher.id));
                          end);
                      end
                      else if Marqueur = 'liste_descriptions_par_editeur' then
                      begin
                        qry := GetQry('editeurs');
                        try
                          LDescriptionsList := qry.AsPublisher.Descriptions;
                        except
                          LDescriptionsList := nil;
                        end;
                        ListeNomTable := 'editeur_descriptions';
                        qry := GetQry(ListeNomTable);
                        qry.SelectDescriptions(LDescriptionsList);
                      end
                      else if Marqueur = 'liste_auteurs' then
                      begin
                        ADB.Authors.SortByName;
                        ListeNomTable := 'auteurs';
                        qry := GetQry(ListeNomTable);
                        qry.SelectAuthors(ADB.Authors);
                      end
                      else if Marqueur = 'liste_auteurs_par_livre' then
                      begin
                        ADB.Authors.SortByName;
                        qry := GetQry('livres');
                        try
                          LShortAuthorsList := qry.AsBook.Authors;
                        except
                          LShortAuthorsList := nil;
                        end;
                        ListeNomTable := 'auteurs';
                        qry := GetQry(ListeNomTable);
                        qry.SelectAuthors(ADB.Authors,
                          function(AAuthors: TDelphiBooksAuthor): boolean
                          begin
                            result := assigned(LShortAuthorsList) and
                              assigned(LShortAuthorsList.GetItemByID
                              (AAuthors.id));
                          end);
                      end
                      else if Marqueur = 'liste_descriptions_par_auteur' then
                      begin
                        qry := GetQry('auteurs');
                        try
                          LDescriptionsList := qry.AsAuthor.Descriptions;
                        except
                          LDescriptionsList := nil;
                        end;
                        ListeNomTable := 'auteur_descriptions';
                        qry := GetQry(ListeNomTable);
                        qry.SelectDescriptions(LDescriptionsList);
                      end
                      else
                        raise exception.Create('Unknown tag "' + Marqueur +
                          '" in template "' + ATemplateFile + '".');
{$ENDREGION}
                      if assigned(qry) and (not ListeNomTable.IsEmpty) then
                      begin
                        Listes.tryAdd(Marqueur, ListeNomTable);
                        PremierElementListesPrecedentes.Push
                          (PremierElementListeEnCours);
                        PremierElementListeEnCours := true;
                        AfficheBlocsPrecedents.Push(AfficheBlocEnCours);
                        AfficheBlocEnCours := AfficheBlocEnCours and
                          (not qry.EOF);
                        ListePrecedenteAvaitElem.Push(not qry.EOF);
                        ListeAvaitElem := false;
                        // ListeAvaitElem ne s'alimente qu'en fin de liste
                        ListePrecedentePosListe.Push(PosListe);
                        PosListe := PosMarqueur + Marqueur.length + 4;
                        PosCurseur := PosListe;
                      end
                      else
                        // Liste non gérée ou problème
                        raise exception.Create('Unknown tag "' + Marqueur +
                          '" in template "' + ATemplateFile + '".');
                    end
                    else if Marqueur.StartsWith('/liste_') then
                    begin
                      // retourne en tête de liste ou continue si dernier enregistrement passé
                      PosCurseur := PosMarqueur + Marqueur.length + 4;
                      if Listes.TryGetValue(Marqueur.Substring(1), ListeNomTable)
                      then
                      begin
                        qry := GetQry(ListeNomTable);
                        if not qry.EOF then
                        begin
                          qry.Next;
                          if not qry.EOF then
                          begin // on boucle
                            PosCurseur := PosListe;
                            PremierElementListeEnCours := false;
                          end
                          else
                          begin
                            // liste terminée
                            PosListe := ListePrecedentePosListe.Pop;
                            PremierElementListeEnCours :=
                              PremierElementListesPrecedentes.Pop;
                            AfficheBlocEnCours := AfficheBlocsPrecedents.Pop;
                            ListeAvaitElem := ListePrecedenteAvaitElem.Pop;
                          end;
                        end
                        else
                        begin
                          // liste vide donc terminée
                          PosListe := ListePrecedentePosListe.Pop;
                          PremierElementListeEnCours :=
                            PremierElementListesPrecedentes.Pop;
                          AfficheBlocEnCours := AfficheBlocsPrecedents.Pop;
                          ListeAvaitElem := ListePrecedenteAvaitElem.Pop;
                        end;
                      end
                    end
                    else if Marqueur.StartsWith('if ') then
                    begin
                      AfficheBlocsPrecedents.Push(AfficheBlocEnCours);
{$REGION 'traitement des conditions'}
                      if (Marqueur = 'if liste_premier_element') then
                      begin
                        AfficheBlocEnCours := PremierElementListeEnCours;
                      end
                      else if (Marqueur = 'if liste_precedente_affichee') then
                      begin
                        AfficheBlocEnCours := ListeAvaitElem;
                      end
                      else if (Marqueur = 'if livre_a_isbn10') then
                      begin
                        qry := GetQry('livres');
                        AfficheBlocEnCours := (not qry.EOF) and
                          (not qry.AsBook.isbn10.IsEmpty);
                      end
                      else if (Marqueur = 'if livre_a_gencod') then
                      begin
                        qry := GetQry('livres');
                        AfficheBlocEnCours := (not qry.EOF) and
                          (not qry.AsBook.isbn13.IsEmpty);
                      end
                      else if (Marqueur = 'if livre_a_url_site') then
                      begin
                        qry := GetQry('livres');
                        AfficheBlocEnCours := (not qry.EOF) and
                          (not qry.AsBook.WebSiteURL.IsEmpty);
                      end
                      else if (Marqueur = 'if livre_a_photo') then
                      begin
                        qry := GetQry('livres');
                        AfficheBlocEnCours := (not qry.EOF) and
                          tfile.Exists(tpath.Combine(DBFolder,
                          qry.AsBook.GetImageFileName));
                      end
                      {
                        // Readers are not implemented

                        else if (Marqueur = 'if lecteur_a_url_site') then
                        begin
                        qry := GetQry('lecteurs');
                        AfficheBlocEnCours := (not qry.EOF) and
                        (not qry.FieldByName('url_site').asstring.IsEmpty);
                        end
                        else if (Marqueur = 'if lecteur_a_photo') then
                        begin
                        qry := GetQry('lecteurs');
                        AfficheBlocEnCours := (not qry.EOF) and
                        tfile.Exists(getCheminDeLaPhoto('lecteurs',
                        qry.FieldByName('code').AsInteger));
                        end
                      }
                      else if (Marqueur = 'if editeur_a_url_site') then
                      begin
                        qry := GetQry('editeurs');
                        AfficheBlocEnCours := (not qry.EOF) and
                          (not qry.AsPublisher.WebSiteURL.IsEmpty);
                      end
                      else if (Marqueur = 'if editeur_a_photo') then
                      begin
                        qry := GetQry('editeurs');
                        AfficheBlocEnCours := (not qry.EOF) and
                          tfile.Exists(tpath.Combine(DBFolder,
                          qry.AsPublisher.GetImageFileName));
                      end
                      else if (Marqueur = 'if auteur_a_url_site') then
                      begin
                        qry := GetQry('auteurs');
                        AfficheBlocEnCours := (not qry.EOF) and
                          (not qry.AsAuthor.WebSiteURL.IsEmpty);
                      end
                      else if (Marqueur = 'if auteur_a_photo') then
                      begin
                        qry := GetQry('auteurs');
                        AfficheBlocEnCours := (not qry.EOF) and
                          tfile.Exists(tpath.Combine(DBFolder,
                          qry.AsAuthor.GetImageFileName));
                      end
                      else
                        raise exception.Create('Unknown tag "' + Marqueur +
                          '" in template "' + ATemplateFile + '".');
{$ENDREGION}
                      // On n'accepte l'affichage que si le bloc précédent (donc celui dans lequel on se trouve) était déjà affichable
                      AfficheBlocEnCours := AfficheBlocsPrecedents.Peek and
                        AfficheBlocEnCours;
                      PosCurseur := PosMarqueur + Marqueur.length + 4;
                    end
                    else if Marqueur = 'else' then
                    begin
                      AfficheBlocEnCours := AfficheBlocsPrecedents.Peek and
                        (not AfficheBlocEnCours);
                      PosCurseur := PosMarqueur + Marqueur.length + 4;
                    end
                    else if Marqueur = '/if' then
                    begin
                      AfficheBlocEnCours := AfficheBlocsPrecedents.Pop;
                      PosCurseur := PosMarqueur + Marqueur.length + 4;
                    end
                    else
                    begin
                      if AfficheBlocEnCours then
                        Destination := Destination + RemplaceMarqueur(Marqueur);
                      PosCurseur := PosMarqueur + Marqueur.length + 4;
                    end;
                  end
                  else
                  begin
                    // pas de tag trouvé, on termine l'envoi du source
                    if AfficheBlocEnCours then
                      Destination := Destination + Source.Substring(PosCurseur);
                    PosCurseur := length(Source);
                  end;
                end;
              finally
                if tfile.Exists(ADestFile) then
                  PrecedentFichier := tfile.ReadAllText(ADestFile,
                    tencoding.UTF8)
                else
                  PrecedentFichier := '';
                if PrecedentFichier <> Destination then
                begin
                  tfile.WriteAllText(ADestFile, Destination, tencoding.UTF8);
                  onLog('Updated file : ' + ALang.LanguageISOCode + '/' +
                    tpath.GetFileName(ADestFile));
                end;
              end;
            finally
              ListePrecedentePosListe.free;
            end;
          finally
            AfficheBlocsPrecedents.free;
          end;
        finally
          ListePrecedenteAvaitElem.free;
        end;
      finally
        PremierElementListesPrecedentes.free;
      end;
    finally
      Listes.free;
    end;
  finally
    for var list in DelphiBooksItemsLists.Values do
      list.free;
    DelphiBooksItemsLists.free;
  end;
end;

{ TItemsList }

function TItemsList.AsAuthor: TDelphiBooksAuthor;
begin
  if (FCurrentIndex >= 0) and (FCurrentIndex < count) and
    (items[FCurrentIndex] is TDelphiBooksAuthor) then
    result := items[FCurrentIndex] as TDelphiBooksAuthor
  else
    result := nil;
end;

function TItemsList.AsBook: TDelphiBooksBook;
begin
  if (FCurrentIndex >= 0) and (FCurrentIndex < count) and
    (items[FCurrentIndex] is TDelphiBooksBook) then
    result := items[FCurrentIndex] as TDelphiBooksBook
  else
    result := nil;
end;

function TItemsList.AsDescription: TDelphiBooksDescription;
begin
  if (FCurrentIndex >= 0) and (FCurrentIndex < count) and
    (items[FCurrentIndex] is TDelphiBooksDescription) then
    result := items[FCurrentIndex] as TDelphiBooksDescription
  else
    result := nil;
end;

function TItemsList.AsKeyword: TDelphiBooksKeyword;
begin
  if (FCurrentIndex >= 0) and (FCurrentIndex < count) and
    (items[FCurrentIndex] is TDelphiBooksKeyword) then
    result := items[FCurrentIndex] as TDelphiBooksKeyword
  else
    result := nil;
end;

function TItemsList.AsLanguage: TDelphiBooksLanguage;
begin
  if (FCurrentIndex >= 0) and (FCurrentIndex < count) and
    (items[FCurrentIndex] is TDelphiBooksLanguage) then
    result := items[FCurrentIndex] as TDelphiBooksLanguage
  else
    result := nil;
end;

function TItemsList.AsPublisher: TDelphiBooksPublisher;
begin
  if (FCurrentIndex >= 0) and (FCurrentIndex < count) and
    (items[FCurrentIndex] is TDelphiBooksPublisher) then
    result := items[FCurrentIndex] as TDelphiBooksPublisher
  else
    result := nil;
end;

function TItemsList.AsTOC: TDelphiBooksTableOfContent;
begin
  if (FCurrentIndex >= 0) and (FCurrentIndex < count) and
    (items[FCurrentIndex] is TDelphiBooksTableOfContent) then
    result := items[FCurrentIndex] as TDelphiBooksTableOfContent
  else
    result := nil;
end;

constructor TItemsList.Create(AItem: TDelphiBooksItem);
begin
  inherited Create;
  if assigned(AItem) then
  begin
    Add(AItem);
    FCurrentIndex := 0;
  end
  else
    FCurrentIndex := -1;
end;

function TItemsList.EOF: boolean;
begin
  result := (count = 0) or (FCurrentIndex < 0) or (FCurrentIndex >= count);
end;

procedure TItemsList.Next;
begin
  inc(FCurrentIndex);
  if (FCurrentIndex >= count) then
    FCurrentIndex := count;
end;

procedure TItemsList.SelectAuthors(AAuthors: TDelphiBooksAuthorsObjectList;
AFilterProc: TAuthorFilterProc);
begin
  clear;
  if assigned(AAuthors) and (AAuthors.count > 0) then
    for var a in AAuthors do
      if (not assigned(AFilterProc)) or AFilterProc(a) then
        Add(a);
  FCurrentIndex := 0;
end;

procedure TItemsList.SelectBooks(ABooks: TDelphiBooksBooksObjectList;
AFilterProc: TBookFilterProc);
begin
  clear;
  if assigned(ABooks) and (ABooks.count > 0) then
    for var b in ABooks do
      if (not assigned(AFilterProc)) or AFilterProc(b) then
        Add(b);
  FCurrentIndex := 0;
end;

procedure TItemsList.SelectDescriptions(ADescriptions
  : TDelphiBooksDescriptionsObjectList; AFilterProc: TDescriptionFilterProc);
begin
  clear;
  if assigned(ADescriptions) and (ADescriptions.count > 0) then
    for var d in ADescriptions do
      if (not assigned(AFilterProc)) or AFilterProc(d) then
        Add(d);
  FCurrentIndex := 0;
end;

procedure TItemsList.SelectKeywords(AKeywords: TDelphiBooksKeywordsObjectList;
AFilterProc: TKeywordFilterProc);
begin
  clear;
  if assigned(AKeywords) and (AKeywords.count > 0) then
    for var k in AKeywords do
      if (not assigned(AFilterProc)) or AFilterProc(k) then
        Add(k);
  FCurrentIndex := 0;
end;

procedure TItemsList.SelectLanguages(ALanguages
  : TDelphiBooksLanguagesObjectList; AFilterProc: TLanguageFilterProc);
begin
  clear;
  if assigned(ALanguages) and (ALanguages.count > 0) then
    for var l in ALanguages do
      if (not assigned(AFilterProc)) or AFilterProc(l) then
        Add(l);
  FCurrentIndex := 0;
end;

procedure TItemsList.SelectPublishers(APublishers
  : TDelphiBooksPublishersObjectList; AFilterProc: TPublisherFilterProc);
begin
  clear;
  if assigned(APublishers) and (APublishers.count > 0) then
    for var p in APublishers do
      if (not assigned(AFilterProc)) or AFilterProc(p) then
        Add(p);
  FCurrentIndex := 0;
end;

procedure TItemsList.SelectTableOfContents(ATableOfContents
  : TDelphiBooksTableOfContentsObjectList;
AFilterProc: TTableOfContentFilterProc);
begin
  clear;
  if assigned(ATableOfContents) and (ATableOfContents.count > 0) then
    for var t in ATableOfContents do
      if (not assigned(AFilterProc)) or AFilterProc(t) then
        Add(t);
  FCurrentIndex := 0;
end;

end.
