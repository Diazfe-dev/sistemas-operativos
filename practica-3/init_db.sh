#!/bin/bash
set -e

DATABASE_PATH="database.db"

if [[ ! -f "$DATABASE_PATH" ]]; then
    touch "$DATABASE_PATH"
fi

sqlite3 "$DATABASE_PATH" <<'SQL'
CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    password TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS products (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    price NUMERIC NOT NULL,
    active INTEGER NOT NULL DEFAULT 1 CHECK (active IN (0, 1))
);

CREATE TABLE IF NOT EXISTS logs (
    id INTEGER PRIMARY KEY,
    level TEXT NOT NULL CHECK (level IN ('info', 'warning', 'error')),
    trace TEXT NOT NULL,
    user_id INTEGER NOT NULL,
    timestamp DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

SQL

echo "Base de datos inicializada en $DATABASE_PATH"
