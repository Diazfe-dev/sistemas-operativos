#! /bin/bash

archivos=$(find . -maxdepth 1 -type f | wc -l)
directorios=$(find . -maxdepth 1 -type d | wc -l)
echo "Hay $archivos archivos y $directorios directorios"


listado=$(ls)
echo $listado
