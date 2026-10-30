#!/usr/bin/env bash

db_init() { sqlite3 "$CONFIG_DB_PATH" < "$CONFIG_SCHEMA_PATH"; }

sql_escape() { local q="'"; printf '%s' "${1//$q/$q$q}"; }
