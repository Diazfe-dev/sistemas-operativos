#!/usr/bin/env bash

product_valid_id() { [[ "$1" =~ ^[0-9]+$ ]]; }
product_valid_price() { [[ "$1" =~ ^[0-9]+([.][0-9]{1,2})?$ ]]; }
product_valid_name() { [[ -n "$1" && "$1" != *$'\t'* && "$1" != *$'\n'* ]]; }

# Imprime el ID del producto creado.
product_new() {
    local name=$1 price=$2 name_sql
    if ! product_valid_name "$name" || ! product_valid_price "$price"; then return "$ERR_INVALID"; fi

    name_sql=$(sql_escape "$name")
    sqlite3 "$CONFIG_DB_PATH" <<SQL || return "$ERR_DB"
INSERT INTO products (name, price, active) VALUES ('$name_sql', $price, 1);
SELECT last_insert_rowid();
SQL
}

product_deactivate() {
    local id=$1 updated
    product_valid_id "$id" || return "$ERR_INVALID"

    updated=$(sqlite3 "$CONFIG_DB_PATH" <<SQL
UPDATE products SET active = 0 WHERE id = $id AND active = 1;
SELECT changes();
SQL
) || return "$ERR_DB"
    [[ "$updated" == '1' ]] || return "$ERR_NOT_FOUND"
}

product_update() {
    local id=$1 name=$2 price=$3 name_sql updated
    if ! product_valid_id "$id" || ! product_valid_name "$name" || ! product_valid_price "$price"; then
        return "$ERR_INVALID"
    fi

    name_sql=$(sql_escape "$name")
    updated=$(sqlite3 "$CONFIG_DB_PATH" <<SQL
UPDATE products SET name = '$name_sql', price = $price WHERE id = $id AND active = 1;
SELECT changes();
SQL
) || return "$ERR_DB"
    [[ "$updated" == '1' ]] || return "$ERR_NOT_FOUND"
}

# Imprime "nombre<TAB>precio" del producto activo.
product_find() {
    local id=$1 row
    product_valid_id "$id" || return "$ERR_INVALID"

    row=$(sqlite3 -separator $'\t' "$CONFIG_DB_PATH" \
        "SELECT name, price FROM products WHERE id = $id AND active = 1;") || return "$ERR_DB"
    [[ -n "$row" ]] || return "$ERR_NOT_FOUND"
    printf '%s\n' "$row"
}

# Imprime una fila "id<TAB>nombre<TAB>precio<TAB>activo" por producto.
product_all() {
    sqlite3 -separator $'\t' "$CONFIG_DB_PATH" \
        'SELECT id, name, price, active FROM products ORDER BY id;' || return "$ERR_DB"
}

# Imprime una fila "id<TAB>nombre<TAB>precio<TAB>activo" por producto activo.
product_all_active() {
    sqlite3 -separator $'\t' "$CONFIG_DB_PATH" \
        'SELECT id, name, price, active FROM products WHERE active = 1 ORDER BY id;' || return "$ERR_DB"
}


# Nota: sqlite3 recibe el parametro -separator que nos permite reemplazar el separador | por una tabulacion (\t)