#!/usr/bin/env bash

mensaje_error() {
    case "$1" in
        "$ERR_INVALID") printf 'Datos invalidos (ID, nombre o precio).\n' ;;
        "$ERR_NOT_FOUND") printf 'El producto no existe.\n' ;;
        "$ERR_EXISTS") printf 'El registro ya existe.\n' ;;
        *) printf 'Error al acceder a la base de datos.\n' ;;
    esac
}

# Lee filas "id<TAB>nombre<TAB>precio<TAB>activo" por stdin y las imprime alineadas.
formatear_inventario() {
    # Variables locales para almacenar los datos de cada fila del inventario
    local id nombre precio activo
    
    # Imprimimos la cabecera de la tabla del inventario
    printf '%-5s %-25s %10s %s\n' 'ID' 'Nombre' 'Precio' 'Activo'

    # Leemos cada fila del inventario y la imprimimos alineada
    while IFS=$'\t' read -r id nombre precio activo; do
        [[ -n "$id" ]] && printf '%-5s %-25s %10s %s\n' "$id" "$nombre" "$precio" "$activo"
    done
    return 0
}
