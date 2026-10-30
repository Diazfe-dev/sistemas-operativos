#!/usr/bin/env bash

bienvenida() { printf 'Bienvenido/a al sistema\n\n'; }

login() {
    local user password
    read -rp 'Ingrese usuario: ' user
    read -rsp 'Ingrese contraseña: ' password; printf '\n'
    if api_user_login "$user" "$password"; then printf 'Login exitoso.\n'; return 0; fi
    printf 'Usuario o contraseña incorrectos.\n'; return 1
}

register() {
    local user password confirm_password
    read -rp 'Ingrese nuevo usuario: ' user
    read -rsp 'Ingrese nueva contraseña: ' password; printf '\n'
    read -rsp 'Confirme nueva contraseña: ' confirm_password; printf '\n'
    if [[ "$password" != "$confirm_password" ]]; then printf 'Las contraseñas no coinciden.\n'; return 1; fi
    api_user_register "$user" "$password"
    case $? in
        0) printf 'Usuario registrado exitosamente.\n' ;;
        "$ERR_INVALID") printf 'Usuario y contraseña son obligatorios.\n' ;;
        "$ERR_EXISTS") printf 'El usuario ya existe.\n' ;;
        *) printf 'No se pudo registrar el usuario.\n' ;;
    esac
}

alta() {
    local nombre precio id
    read -rp 'Ingrese Nombre: ' nombre
    read -rp 'Ingrese Precio: ' precio
    if id=$(api_product_new "$nombre" "$precio"); then printf 'Producto dado de alta con ID %s.\n' "$id"
    else mensaje_error $?; fi
}

baja() {
    local id
    read -rp 'Ingrese ID a eliminar: ' id
    if api_product_delete "$id"; then printf 'Producto dado de baja.\n'; else mensaje_error $?; fi
}

editar() {
    local id nombre precio
    read -rp 'Ingrese ID a editar: ' id
    read -rp 'Ingrese nuevo nombre: ' nombre
    read -rp 'Ingrese nuevo precio: ' precio
    if api_product_update "$id" "$nombre" "$precio"; then printf 'Producto editado.\n'; else mensaje_error $?; fi
}

mostrar() {
    local inventario
    if inventario=$(api_product_list); then printf '\n'; formatear_inventario <<< "$inventario"
    else mensaje_error $?; fi
    read -rp 'Presione Enter para continuar...' _
}

reporte() {
    local archivo
    if archivo=$(api_report_generate); then printf 'Reporte generado en %s.\n' "$archivo"
    else mensaje_error $?; fi
    read -rp 'Presione Enter para continuar...' _
}

cli_main() {
    local acceso=0 opcion=0
    bienvenida
    while ((acceso == 0)); do
        printf '\nACCESO AL SISTEMA\n1. Iniciar sesión\n2. Registrarse\n3. Salir\n'
        read -rp 'Opción: ' opcion || return 0
        case "$opcion" in
            1) login && acceso=1 ;; 2) register ;;
            3) printf '\nSaliendo del programa...\n'; return 0 ;;
            *) printf 'Opción inválida.\n' ;;
        esac
        if ((acceso == 0)); then read -rp 'Presione Enter para continuar...' _; fi
    done
    while [[ "$opcion" != "$OPCION_SALIR" ]]; do
        printf '\nACCIONES:\n1. Alta producto\n2. Baja producto\n3. Editar producto\n4. Mostrar inventario\n5. Generar reporte HTML\n6. Salir\n'
        read -rp 'Opcion: ' opcion || return 0
        case "$opcion" in
            $OPCION_ALTA) alta ;;
            $OPCION_BAJA) baja ;;
            $OPCION_EDITAR) editar ;;
            $OPCION_MOSTRAR) mostrar ;;
            $OPCION_REPORTE) reporte ;;
            $OPCION_SALIR) printf '\nSaliendo del programa...\n' ;;
            *) printf '\nOpcion invalida.\n' ;;
        esac
    done
}
