libname decode "/folders/myfolders/MiniProjet/sources/format";    /* endroit où se trouvent le catalogue de formats */
libname source "/folders/myfolders/MiniProjet/sources" ACCESS=READONLY;          /* endroit où se trouvent tous les datasets sources */
libname result "/folders/myfolders/MiniProjet/resultats";
options fmtsearch=(decode SOURCE WORK);
options ls=256;

