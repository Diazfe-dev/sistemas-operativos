#!/usr/bin/env bash

sql_escape() {
    local value=$1
    printf '%s' "${value//\'/\'\'}"
}

validar_id() { [[ "$1" =~ ^[0-9]+$ ]]; }
validar_precio() { [[ "$1" =~ ^[0-9]+([.][0-9]{1,2})?$ ]]; }
validar_nombre() { [[ -n "$1" && "$1" != *$'\t'* && "$1" != *$'\n'* ]]; }

alta_producto() {
    local nombre=$1 precio=$2 nombre_sql
    if ! validar_nombre "$nombre" || ! validar_precio "$precio"; then
        printf 'Nombre o precio invalido.\n'; return 1
    fi
    nombre_sql=$(sql_escape "$nombre")
    if sqlite3 "$DATABASE_PATH" <<SQL
INSERT INTO products (name, price, active) VALUES ('$nombre_sql', $precio, 1);
SQL
    then
        local product_id="$(sqlite3 "$DATABASE_PATH" 'SELECT max(id) FROM products;')"
        printf 'Producto dado de alta con ID %s.\n' "$product_id"
        log_event info "Producto creado: $product_id" "$CURRENT_USER_ID" || true
    else
        printf 'No se pudo dar de alta el producto.\n'; return 1
    fi
}

baja_producto() {
    local id=$1 updated
    if ! validar_id "$id"; then printf 'ID invalido.\n'; return 1; fi
    if ! updated=$(sqlite3 "$DATABASE_PATH" <<SQL
UPDATE products SET active = 0 WHERE id = $id AND active = 1;
SELECT changes();
SQL
); then
        printf 'No se pudo dar de baja el producto.\n'; return 1
    fi
    if [[ "$updated" == '1' ]]; then
        printf 'Producto dado de baja.\n'
        log_event info "Producto dado de baja: $id" "$CURRENT_USER_ID" || true
    else
        printf 'El producto no existe.\n'; return 1
    fi
}

editar_producto() {
    local id=$1 nombre=$2 precio=$3 nombre_sql updated
    if ! validar_id "$id" || ! validar_nombre "$nombre" || ! validar_precio "$precio"; then
        printf 'ID, nombre o precio invalido.\n'; return 1
    fi
    nombre_sql=$(sql_escape "$nombre")
    if ! updated=$(sqlite3 "$DATABASE_PATH" <<SQL
UPDATE products SET name = '$nombre_sql', price = $precio WHERE id = $id AND active = 1;
SELECT changes();
SQL
); then
        printf 'No se pudo editar el producto.\n'; return 1
    fi
    if [[ "$updated" == '1' ]]; then
        printf 'Producto editado.\n'
        log_event info "Producto editado: $id" "$CURRENT_USER_ID" || true
    else
        printf 'El producto no existe.\n'; return 1
    fi
}

mostrar_producto() {
    printf '\nID\tNombre\tPrecio\tActivo\n'
    sqlite3 -separator $'\t' "$DATABASE_PATH" \
        'SELECT id, name, price, active FROM products ORDER BY id;'
    log_event info 'Inventario consultado' "$CURRENT_USER_ID" || true
}

generar_reporte() {
    local archivo='reporte_inventario.html' id nombre precio activo nombre_html
    {
        printf '%s\n' '<!DOCTYPE html>' '<html lang="es">' '<head>'
        printf '%s\n' '  <meta charset="UTF-8">' '  <title>Reporte de inventario</title>'
        printf '%s\n' '</head>' '<body>' '  <h1>Reporte de inventario</h1>' '  <table border="1">'
        printf '%s\n' '    <tr><th>ID</th><th>Nombre</th><th>Precio</th><th>Activo</th></tr>'
        while IFS=$'\t' read -r id nombre precio activo; do
            nombre_html=${nombre//&/&amp;}; nombre_html=${nombre_html//</&lt;}; nombre_html=${nombre_html//>/&gt;}
            printf '    <tr><td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>\n' "$id" "$nombre_html" "$precio" "$activo"
        done < <(sqlite3 -separator $'\t' "$DATABASE_PATH" 'SELECT id, name, price, active FROM products ORDER BY id;')
        printf '%s\n' '  </table>' '</body>' '</html>'
    } > "$archivo"
    printf 'Reporte generado en %s.\n' "$archivo"
    log_event info 'Reporte de inventario generado' "$CURRENT_USER_ID" || true
}
