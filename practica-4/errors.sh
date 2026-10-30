#!/usr/bin/env bash

# Codigos de retorno compartidos por modelos y API (0 = exito).
declare -g -r -i ERR_INVALID=1 ERR_NOT_FOUND=2 ERR_EXISTS=3 ERR_DB=4
