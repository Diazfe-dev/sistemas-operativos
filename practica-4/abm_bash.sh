#!/usr/bin/env bash

BASE_DIR=${BASH_SOURCE[0]%/*}
[[ "$BASE_DIR" == "${BASH_SOURCE[0]}" ]] && BASE_DIR=.
BASE_DIR=$(cd "$BASE_DIR" && pwd)

declare -r -i OPCION_ALTA=1 
declare -r -i OPCION_BAJA=2 
declare -r -i OPCION_EDITAR=3 
declare -r -i OPCION_MOSTRAR=4 
declare -r -i OPCION_REPORTE=5 
declare -r -i OPCION_SALIR=6

uso() { printf 'Uso: %s [--cli | --tui]\n  --cli  Interfaz de linea de comandos (por defecto)\n  --tui  Interfaz grafica con whiptail\n' "$0"; }

# Capas: config → models (SQL, validaciones) → api (orquesta modelos) → ui (solo habla con la api).
app_init() {
    local modulo
    for modulo in config errors \
        models/db models/user_model models/product_model models/log_model \
        api/user_api api/product_api api/report_api \
        ui/common ui/cli ui/tui; do
        source "$BASE_DIR/$modulo.sh" || return 1
    done
    db_init || { printf 'No se pudo inicializar la base de datos.\n' >&2; return 1; }
}

main() {
    local ui
    case "${1:---cli}" in
        --cli) ui=cli ;;
        --tui) ui=tui ;;
        -h|--help) uso; return 0 ;;
        *) uso >&2; return 1 ;;
    esac
    app_init || return 1
    "${ui}_main"
}

main "$@"
