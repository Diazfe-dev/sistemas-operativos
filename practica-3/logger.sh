#!/usr/bin/env bash

log_event() {
    local level=$1 trace=$2 user_id=$3
    local trace_sql

    [[ "$level" =~ ^(info|warning|error)$ ]] || return 1
    [[ "$user_id" =~ ^[1-9][0-9]*$ ]] || return 1

    trace_sql=${trace//\'/\'\'}
    sqlite3 "$DATABASE_PATH" <<SQL
INSERT INTO logs (level, trace, user_id)
VALUES ('$level', '$trace_sql', $user_id);
SQL
}
