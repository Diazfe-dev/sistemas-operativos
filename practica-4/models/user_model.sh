#!/usr/bin/env bash

# Valida que el nombre de usuario sea no vacío y no contenga tabulaciones ni saltos de línea.
user_valid_name() { [[ -n "$1" && "$1" != *$'\t'* && "$1" != *$'\n'* ]]; }

# Valida que la contraseña no esté vacía.
user_valid_password() { [[ -n "$1" ]]; }

# Genera un hash SHA-256 de la contraseña.
user_hash_password() {
    
    # Variable local para almacenar el hash de la contraseña
    local hash

    # Verificamos que se haya proporcionado una contraseña
    [[ -n "$1" ]] || return "$ERR_INVALID"

    # Calculamos el hash de la contraseña usando SHA-256
    hash=$(printf '%s' "$1" | sha256sum) || return "$ERR_DB"

    # Imprimimos el hash calculado sin los posibles espacios adicionales que sha256sum agrega
    printf '%s' "${hash%% *}"
}

# Imprime el ID del usuario (vacio si no existe).
user_find_id() {
    local name_sql
    name_sql=$(sql_escape "$1")
    sqlite3 "$CONFIG_DB_PATH" "SELECT id FROM users WHERE name = '$name_sql';" || return "$ERR_DB"
}

# Imprime el ID del usuario creado.
user_new() {
    local name=$1 password=$2 name_sql password_hash user_id
    if ! user_valid_name "$name" || ! user_valid_password "$password"; then return "$ERR_INVALID"; fi

    user_id=$(user_find_id "$name") || return
    [[ -z "$user_id" ]] || return "$ERR_EXISTS"

    password_hash=$(user_hash_password "$password") || return
    name_sql=$(sql_escape "$name")
    sqlite3 "$CONFIG_DB_PATH" <<SQL || return "$ERR_DB"
INSERT INTO users (name, password) VALUES ('$name_sql', '$password_hash');
SELECT last_insert_rowid();
SQL
}

# Imprime el ID del usuario si las credenciales son correctas.
user_authenticate() {
    local name=$1 password=$2 name_sql password_hash user_id

    password_hash=$(user_hash_password "$password") || return
    name_sql=$(sql_escape "$name")
    user_id=$(sqlite3 "$CONFIG_DB_PATH" <<SQL
SELECT id
FROM users
WHERE name = '$name_sql'
  AND password = '$password_hash';
SQL
) || return "$ERR_DB"
    [[ -n "$user_id" ]] || return "$ERR_NOT_FOUND"
    printf '%s\n' "$user_id"
}
