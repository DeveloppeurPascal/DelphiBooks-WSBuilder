# 20230630 - [DeveloppeurPascal](https://github.com/DeveloppeurPascal)

* removed the TODO.md file, ise GitHub issues to ask new features or submit bugs
* updated FR/EN docs
* added project [DeveloppeurPascal/AboutDialog-Delphi-Component](https://github.com/DeveloppeurPascal/AboutDialog-Delphi-Component) as a submodule in lib_externes subfolder
* added project [DeveloppeurPascal/DelphiBooks-Common](https://github.com/DeveloppeurPascal/DelphiBooks-Common) as a submodule in lib_externes subfolder
* added project [DeveloppeurPascal/DelphiBooks-WebSite](https://github.com/DeveloppeurPascal/DelphiBooks-WebSite) as a submodule in lib_externes subfolder
* added project [DeveloppeurPascal/librairies](https://github.com/DeveloppeurPascal/librairies) as a submodule in lib_externes subfolder
* added the DBAdmin icon for the WSBuilder program
* added a new empty Delphi FireMonkey project for the WSBuilder
* linked the project icons in the project options
* added the about box dialog and its image (from a new data module)
* finished the frmMain form with 3 buttons (about dialog, build, close)
* fixed frmMain form name (previous was "fmrMain")
* implemented the build button click event
* added the report memory leaks alert in debug
* added the builder form with a log layout and thread structure
* added common Delphi Books units (classes en DB.repository)
* added the needed procedures for the builder algorithm in the builder form
* added log(), logTitle(), logError() and DebugLog() methods in the builder form
* implemented getFolders() method in the builder form
* implemented LoadRepositoryDatabase() method in the builder form
* implemented SaveRepositoryDatabase() method in the builder form
* implemented UpdateNewObjectsProperties() method in the builder form
* added a thumb creation method (CreateAndSaveThumb)
* implemented BuildWebSiteImages() method in the builder form