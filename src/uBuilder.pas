unit uBuilder;

interface

uses
  DelphiBooks.Classes,
  DelphiBooks.DB.Repository;

procedure BuildPageFromTemplate(ADB: TDelphiBooksDatabase;
  ALang: TDelphiBooksLanguage; ATemplateFile, ADestFile: string;
  ADataName: string = ''; AItem: TDelphiBooksItem = nil);

implementation

uses
  System.DateUtils,
  System.SysUtils,
  System.IOUtils,
  System.Generics.Collections,
  System.StrUtils,
  uOutilsCommuns;

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
    procedure SelectBooks(ADB: TDelphiBooksDatabase;
      AFilterProc: TBookFilterProc);
    procedure SelectAuthors(AAuthors: TDelphiBooksAuthorsObjectList;
      AFilterProc: TAuthorFilterProc);
    procedure SelectPublishers(APublishers: TDelphiBooksPublishersObjectList;
      AFilterProc: TPublisherFilterProc);
    procedure SelectLanguages(ALanguages: TDelphiBooksLanguagesObjectList;
      AFilterProc: TLanguageFilterProc);
    procedure SelectDescriptions(ADescriptions
      : TDelphiBooksDescriptionsObjectList;
      AFilterProc: TDescriptionFilterProc);
    procedure SelectTableOfContents(ATableOfContents
      : TDelphiBooksTableOfContentsObjectList;
      AFilterProc: TTableOfContentFilterProc);
    procedure SelectKeywords(AKeywords: TDelphiBooksKeywordsObjectList;
      AFilterProc: TKeywordFilterProc);
    Procedure Next;
    function EOF: boolean;
    constructor Create(AItem: TDelphiBooksItem = nil);
  end;

procedure BuildPageFromTemplate(ADB: TDelphiBooksDatabase;
  ALang: TDelphiBooksLanguage; ATemplateFile, ADestFile: string;
  ADataName: string; AItem: TDelphiBooksItem);
var
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
  sql: string;

  function GetQry(NomTable: string): TItemsList;
  begin
    if (not DelphiBooksItemsLists.TryGetValue(NomTable, result)) then
    begin
      result := TItemsList.Create;
      DelphiBooksItemsLists.Add(NomTable, result);
    end;
  end;

  function RemplaceMarqueur(Marqueur: string): string;
  begin
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
  if not tfile.Exists(ATemplateFile) then
    raise exception.Create('Template file "' + ATemplateFile + '" not found.');
  try
    Source := tfile.ReadAllText(ATemplateFile, tencoding.UTF8);
  except
    raise exception.Create('Can''t load "' + ATemplateFile + '".');
  end;
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
                    begin // ne traite pas de listes imbriquées
{$REGION 'listes gérées par le logiciel'}
                      if Marqueur = 'liste_livres' then
                      begin
                        sql := 'select livres.*,langues.libelle as langue_libelle, langues.nom_page as langue_nom_page, langues.code_iso as langue_code_iso from livres, langues where livres.langue_code=langues.code order by titre';
                        ListeNomTable := 'livres';
                      end
                      else if Marqueur = 'liste_livres-par_date' then
                      begin
                        sql := 'select livres.*,langues.libelle as langue_libelle, langues.nom_page as langue_nom_page, langues.code_iso as langue_code_iso from livres, langues where livres.langue_code=langues.code order by datedesortie desc, titre';
                        ListeNomTable := 'livres';
                      end
                      else if Marqueur = 'liste_livres_recents' then
                      begin // que le slivres édités depuis 1 an (année glissante)
                        sql := 'select livres.*,langues.libelle as langue_libelle, langues.nom_page as langue_nom_page, langues.code_iso as langue_code_iso from livres, langues where livres.langue_code=langues.code and livres.datedesortie>"'
                          + DateToString8(incyear(now, -1)) +
                          '" order by datedesortie desc, titre';
                        ListeNomTable := 'livres';
                      end
                      else if Marqueur = 'liste_livres_derniers_ajouts' then
                      begin // que les 1' denriers (7 par ligne dans le design classique du site, donc 2 lignes)
                        sql := 'select livres.*,langues.libelle as langue_libelle, langues.nom_page as langue_nom_page, langues.code_iso as langue_code_iso from livres, langues where livres.langue_code=langues.code order by code desc limit 0,14';
                        ListeNomTable := 'livres';
                      end
                      else if Marqueur = 'liste_livres_par_editeur' then
                      begin
                        qry := GetQry('editeurs');
                        sql := 'select livres.*,langues.libelle as langue_libelle, langues.nom_page as langue_nom_page, langues.code_iso as langue_code_iso from livres, langues, livres_editeurs_lien where livres.langue_code=langues.code and '
                          + 'livres.code=livres_editeurs_lien.livre_code and livres_editeurs_lien.editeur_code='
                          + ifthen(not qry.EOF, qry.AsPublisher.id.tostring,
                          '-1') + ' order by titre';
                        ListeNomTable := 'livres';
                      end
                      else if Marqueur = 'liste_livres_par_auteur' then
                      begin
                        qry := GetQry('auteurs');
                        sql := 'select livres.*,langues.libelle as langue_libelle, langues.nom_page as langue_nom_page, langues.code_iso as langue_code_iso from livres, langues, livres_auteurs_lien where livres.langue_code=langues.code and '
                          + 'livres.code=livres_auteurs_lien.livre_code and livres_auteurs_lien.auteur_code='
                          + ifthen(not qry.EOF, qry.AsAuthor.id.tostring, '-1')
                          + ' order by titre';
                        ListeNomTable := 'livres';
                      end
                      else if Marqueur = 'liste_livres_par_motcle' then
                      begin
                        raise exception.Create
                          ('"liste_livres_par_motcle" is not available in this release');
                      end
                      else if Marqueur = 'liste_livres_par_langue' then
                      begin
                        qry := GetQry('langues');
                        sql := 'select livres.*,langues.libelle as langue_libelle, langues.nom_page as langue_nom_page, langues.code_iso as langue_code_iso from livres, langues where livres.langue_code=langues.code and '
                          + 'langues.code=' + ifthen(not qry.EOF,
                          qry.AsLanguage.id.tostring, '-1') + ' order by titre';
                        ListeNomTable := 'livres';
                      end
                      else if Marqueur = 'liste_commentaires_par_livre' then
                      begin
                        raise exception.Create
                          ('"liste_commentaires_par_livre" is not available in this release');
                      end
                      else if Marqueur = 'liste_tabledesmatieres_par_livre' then
                      begin
                        qry := GetQry('livres');
                        sql := 'select livres_tabledesmatieres.*,langues.libelle as langue_libelle, langues.nom_page as langue_nom_page, langues.code_iso as langue_code_iso '
                          + 'from livres_tabledesmatieres, langues ' +
                          'where livres_tabledesmatieres.langue_code=langues.code and '
                          + 'livres_tabledesmatieres.livre_code=' +
                          ifthen(not qry.EOF, qry.AsBook.id.tostring, '-1');
                        ListeNomTable := 'livre_tablesdesmatieres';
                      end
                      else if Marqueur = 'liste_descriptions_par_livre' then
                      begin
                        qry := GetQry('livres');
                        sql := 'select livres_description.*,langues.libelle as langue_libelle, langues.nom_page as langue_nom_page, langues.code_iso as langue_code_iso '
                          + 'from livres_description, langues ' +
                          'where livres_description.langue_code=langues.code and '
                          + 'livres_description.livre_code=' +
                          ifthen(not qry.EOF, qry.AsBook.id.tostring, '-1');
                        ListeNomTable := 'livre_descriptions';
                      end
                      else if Marqueur = 'liste_motscles' then
                      begin
                        sql := 'select * from motscles';
                        ListeNomTable := 'motscles';
                      end
                      else if Marqueur = 'liste_motscles_par_livre' then
                      begin
                        qry := GetQry('livres');
                        sql := 'select motscles.* ' +
                          'from motscles, livres_motscles_lien ' +
                          'where motscles.code=livres_motscles_lien.motcle_code and '
                          + 'livres_motscles_lien.livre_code=' +
                          ifthen(not qry.EOF, qry.AsBook.id.tostring, '-1');
                        ListeNomTable := 'motscles';
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
                        sql := 'select * from langues order by libelle';
                        ListeNomTable := 'langues';
                      end
                      else if Marqueur = 'liste_editeurs' then
                      begin
                        sql := 'select * from editeurs order by raison_sociale';
                        ListeNomTable := 'editeurs';
                      end
                      else if Marqueur = 'liste_editeurs_par_livre' then
                      begin
                        qry := GetQry('livres');
                        sql := 'select editeurs.* ' +
                          'from editeurs, livres_editeurs_lien ' +
                          'where editeurs.code=livres_editeurs_lien.editeur_code and '
                          + 'livres_editeurs_lien.livre_code=' +
                          ifthen(not qry.EOF, qry.AsBook.id.tostring, '-1');
                        ListeNomTable := 'editeurs';
                      end
                      else if Marqueur = 'liste_descriptions_par_editeur' then
                      begin
                        qry := GetQry('editeurs');
                        sql := 'select editeurs_description.*,langues.libelle as langue_libelle, langues.nom_page as langue_nom_page, langues.code_iso as langue_code_iso '
                          + 'from editeurs_description, langues ' +
                          'where editeurs_description.langue_code=langues.code and '
                          + 'editeurs_description.editeur_code=' +
                          ifthen(not qry.EOF,
                          qry.AsPublisher.id.tostring, '-1');
                        ListeNomTable := 'editeur_descriptions';
                      end
                      else if Marqueur = 'liste_auteurs' then
                      begin
                        sql := 'select * from auteurs order by nom,prenom,pseudo';
                        ListeNomTable := 'auteurs';
                      end
                      else if Marqueur = 'liste_auteurs_par_livre' then
                      begin
                        qry := GetQry('livres');
                        sql := 'select auteurs.* ' +
                          'from auteurs, livres_auteurs_lien ' +
                          'where auteurs.code=livres_auteurs_lien.auteur_code and '
                          + 'livres_auteurs_lien.livre_code=' +
                          ifthen(not qry.EOF, qry.AsBook.id.tostring, '-1');
                        ListeNomTable := 'auteurs';
                      end
                      else if Marqueur = 'liste_descriptions_par_auteur' then
                      begin
                        qry := GetQry('auteurs');
                        sql := 'select auteurs_description.*,langues.libelle as langue_libelle, langues.nom_page as langue_nom_page, langues.code_iso as langue_code_iso '
                          + 'from auteurs_description, langues ' +
                          'where auteurs_description.langue_code=langues.code and '
                          + 'auteurs_description.auteur_code=' +
                          ifthen(not qry.EOF, qry.AsAuthor.id.tostring, '-1');
                        ListeNomTable := 'auteur_descriptions';
                      end
                      else
                        raise exception.Create('Unknown tag "' + Marqueur +
                          '" in template "' + ATemplateFile + '".');
{$ENDREGION}
                      if (not sql.IsEmpty) and (not ListeNomTable.IsEmpty) then
                      begin
                        Listes.tryAdd(Marqueur, ListeNomTable);
                        qry := GetQry(ListeNomTable);
                        // TODO : à compléter
                        // if qry.Active then
                        // qry.close;
                        // qry.Open(sql);
                        // qry.First;
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
                    begin // retourne en tête de liste ou continue si dernier enregistrement passé
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
                          begin // liste terminée
                            PosListe := ListePrecedentePosListe.Pop;
                            PremierElementListeEnCours :=
                              PremierElementListesPrecedentes.Pop;
                            AfficheBlocEnCours := AfficheBlocsPrecedents.Pop;
                            ListeAvaitElem := ListePrecedenteAvaitElem.Pop;
                          end;
                        end
                        else
                        begin // liste vide donc terminée
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
                        // TODO : à compléter
                        // AfficheBlocEnCours := (not qry.EOF) and
                        // tfile.Exists(getCheminDeLaPhoto('livres',
                        // qry.FieldByName('code').AsInteger));
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
                        // TODO : à compléter
                        // AfficheBlocEnCours := (not qry.EOF) and
                        // tfile.Exists(getCheminDeLaPhoto('editeurs',
                        // qry.FieldByName('code').AsInteger));
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
                        // TODO : à compléter
                        // AfficheBlocEnCours := (not qry.EOF) and
                        // tfile.Exists(getCheminDeLaPhoto('auteurs',
                        // qry.FieldByName('code').AsInteger));
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
                  tfile.WriteAllText(ADestFile, Destination, tencoding.UTF8);
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
  Create;
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
  if AAuthors.count > 0 then
    for var a in AAuthors do
      if AFilterProc(a) then
        Add(a);
  FCurrentIndex := 0;
end;

procedure TItemsList.SelectBooks(ADB: TDelphiBooksDatabase;
  AFilterProc: TBookFilterProc);
begin
  clear;
  if ADB.Books.count > 0 then
    for var b in ADB.Books do
      if AFilterProc(b) then
        Add(b);
  FCurrentIndex := 0;
end;

procedure TItemsList.SelectDescriptions(ADescriptions
  : TDelphiBooksDescriptionsObjectList; AFilterProc: TDescriptionFilterProc);
begin
  clear;
  if ADescriptions.count > 0 then
    for var d in ADescriptions do
      if AFilterProc(d) then
        Add(d);
  FCurrentIndex := 0;
end;

procedure TItemsList.SelectKeywords(AKeywords: TDelphiBooksKeywordsObjectList;
  AFilterProc: TKeywordFilterProc);
begin
  clear;
  if AKeywords.count > 0 then
    for var k in AKeywords do
      if AFilterProc(k) then
        Add(k);
  FCurrentIndex := 0;
end;

procedure TItemsList.SelectLanguages(ALanguages
  : TDelphiBooksLanguagesObjectList; AFilterProc: TLanguageFilterProc);
begin
  clear;
  if ALanguages.count > 0 then
    for var l in ALanguages do
      if AFilterProc(l) then
        Add(l);
  FCurrentIndex := 0;
end;

procedure TItemsList.SelectPublishers(APublishers
  : TDelphiBooksPublishersObjectList; AFilterProc: TPublisherFilterProc);
begin
  clear;
  if APublishers.count > 0 then
    for var p in APublishers do
      if AFilterProc(p) then
        Add(p);
  FCurrentIndex := 0;
end;

procedure TItemsList.SelectTableOfContents(ATableOfContents
  : TDelphiBooksTableOfContentsObjectList;
  AFilterProc: TTableOfContentFilterProc);
begin
  clear;
  if ATableOfContents.count > 0 then
    for var t in ATableOfContents do
      if AFilterProc(t) then
        Add(t);
  FCurrentIndex := 0;
end;

end.
