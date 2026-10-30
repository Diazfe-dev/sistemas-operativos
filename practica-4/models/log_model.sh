#!/usr/bin/env bash

log_new() {
    local level=$1 trace=$2 user_id=$3 trace_sql

    [[ "$level" =~ ^(info|warning|error)$ ]] || return "$ERR_INVALID"
    [[ "$user_id" =~ ^[1-9][0-9]*$ ]] || return "$ERR_INVALID"

    trace_sql=$(sql_escape "$trace")
    sqlite3 "$CONFIG_DB_PATH" <<SQL || return "$ERR_DB"
INSERT INTO logs (level, trace, user_id) VALUES ('$level', '$trace_sql', $user_id);
SQL
}
