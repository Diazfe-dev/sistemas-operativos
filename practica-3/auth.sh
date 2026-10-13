#!/bin/bash

register_user() {
    local username=$1
    local password=$2
    local password_hash
    local user_exists user_id

    password_hash=$(printf '%s' "$password" | sha256sum)
    password_hash=${password_hash%% *}

    user_exists=$(sqlite3 "database.db" <<SQL
SELECT COUNT(*)
FROM users
WHERE name='$username';
SQL
)

    if [[ "$user_exists" == "1" ]]; then
        user_id=$(sqlite3 "$DATABASE_PATH" "SELECT id FROM users WHERE name='$username';")
        log_event warning "Registro rechazado, usuario existente: $username" "$user_id" || true
        return 1
    fi

    sqlite3 "database.db" <<SQL
INSERT INTO users (name, password)
VALUES ('$username', '$password_hash');
SQL
}

login_user() {
    local username=$1
    local password=$2
    local password_hash
    local user_found user_id

    password_hash=$(printf '%s' "$password" | sha256sum)
    password_hash=${password_hash%% *}

    user_found=$(sqlite3 "database.db" <<SQL
SELECT COUNT(*)
FROM users
WHERE name='$username'
  AND password='$password_hash';
SQL
)

    if [[ "$user_found" == "1" ]]; then
        user_id=$(sqlite3 "$DATABASE_PATH" "SELECT id FROM users WHERE name='$username';")
        CURRENT_USER_ID=$user_id
        log_event info "Inicio de sesión exitoso: $username" "$user_id" || true
        return 0
    fi

    user_id=$(sqlite3 "$DATABASE_PATH" "SELECT id FROM users WHERE name='$username';")
    if [[ "$user_id" =~ ^[1-9][0-9]*$ ]]; then
        log_event warning "Inicio de sesión rechazado: $username" "$user_id" || true
    fi
    return 1
}