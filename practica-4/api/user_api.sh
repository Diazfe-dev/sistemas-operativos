#!/usr/bin/env bash

api_user_register() {
    local name=$1 password=$2 user_id status
    user_id=$(user_new "$name" "$password"); status=$?

    if ((status == ERR_EXISTS)) && user_id=$(user_find_id "$name"); then
        log_new warning "Registro rechazado, usuario existente: $name" "$user_id" || true
    fi
    return "$status"
}

# Debe llamarse fuera de una subshell: define CURRENT_USER_ID para el resto de la sesion.
api_user_login() {
    local name=$1 password=$2 user_id status
    user_id=$(user_authenticate "$name" "$password"); status=$?

    if ((status == 0)); then
        CURRENT_USER_ID=$user_id
        log_new info "Inicio de sesión exitoso: $name" "$user_id" || true
        return 0
    fi
    if ((status == ERR_NOT_FOUND)) && user_id=$(user_find_id "$name") && [[ -n "$user_id" ]]; then
        log_new warning "Inicio de sesión rechazado: $name" "$user_id" || true
    fi
    return "$status"
}
