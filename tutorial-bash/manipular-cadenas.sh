#!/bin/bash

texto="Hola mundo"
echo ${texto:0:4}
echo ${texto:5:10}


echo =============

cadena="test@dominio.com"

# Corta todo lo que esta antes del arroba inclusive
echo "${cadena#*@}"

# Corta todo lo que esta despues del arroba inclusive

echo "${cadena%@*}"

# Corta todo lo que este despues del punto
echo "${cadena%.*}"
