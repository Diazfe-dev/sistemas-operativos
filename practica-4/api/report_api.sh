#!/usr/bin/env bash

html_escape() {
    local value=${1//&/&amp;}
    value=${value//</&lt;}
    printf '%s' "${value//>/&gt;}"
}

# Imprime la ruta del reporte generado.
api_report_generate() {
    local productos id nombre precio activo
    productos=$(product_all) || return
    {
        printf '%s\n' '<!DOCTYPE html>' '<html lang="es">' '<head>'
        printf '%s\n' '  <meta charset="UTF-8">' '  <title>Reporte de inventario</title>'
        printf '%s\n' '</head>' '<body>' '  <h1>Reporte de inventario</h1>' '  <table border="1">'
        printf '%s\n' '    <tr><th>ID</th><th>Nombre</th><th>Precio</th><th>Activo</th></tr>'
        while IFS=$'\t' read -r id nombre precio activo; do
            [[ -n "$id" ]] || continue
            printf '    <tr><td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>\n' "$id" "$(html_escape "$nombre")" "$precio" "$activo"
        done <<< "$productos"
        printf '%s\n' '  </table>' '</body>' '</html>'
    } > "$CONFIG_REPORT_PATH" || return "$ERR_DB"

    log_new info 'Reporte de inventario generado' "$CURRENT_USER_ID" || true
    printf '%s\n' "$CONFIG_REPORT_PATH"
}
