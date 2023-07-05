# 20230705 - [DeveloppeurPascal](https://github.com/DeveloppeurPascal)

* updated dependencies

* fixed : wrong link for DelphiBooks.Tools unit (uOutilsCommuns.pas still used)

* use getImageFileName to generate pictures instead of naming in code
* use HasNewImage property to (force) generate thumb files and don't in other cases if the destination file already exists
* fixed : remove thumbs for removed book covers (previous generated file was removed instead of the good picture)

* added wordwrap on log 

* released v1.2 - 20230705
