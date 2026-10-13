#!/usr/bin/env bash
source './init_db.sh'
source './auth.sh'
source './logger.sh'
source './inventory.sh'

declare -r -i OPCION_ALTA=1 OPCION_BAJA=2 OPCION_EDITAR=3 OPCION_MOSTRAR=4 OPCION_REPORTE=5 OPCION_SALIR=6

bienvenida() { printf 'Bienvenido/a al sistema\n\n'; }

login() {
    local user password
    read -rp 'Ingrese usuario: ' user
    read -rsp 'Ingrese contraseña: ' password; printf '\n'
    if login_user "$user" "$password"; then printf 'Login exitoso.\n'; return 0; fi
    printf 'Usuario o contraseña incorrectos.\n'; return 1
}

register() {
    local user password confirm_password
    read -rp 'Ingrese nuevo usuario: ' user
    read -rsp 'Ingrese nueva contraseña: ' password; printf '\n'
    read -rsp 'Confirme nueva contraseña: ' confirm_password; printf '\n'
    if [[ "$password" != "$confirm_password" ]]; then printf 'Las contraseñas no coinciden.\n'; return 1; fi
    if register_user "$user" "$password"; then printf 'Usuario registrado exitosamente.\n'; return 0; fi
    printf 'El usuario ya existe o no se pudo registrar.\n'; return 1
}

alta() {
    local nombre precio
    read -rp 'Ingrese Nombre: ' nombre
    read -rp 'Ingrese Precio: ' precio
    alta_producto "$nombre" "$precio"
}

baja() {
    local id
    read -rp 'Ingrese ID a eliminar: ' id
    baja_producto "$id"
}

editar() {
    local id nombre precio
    read -rp 'Ingrese ID a editar: ' id
    read -rp 'Ingrese nuevo nombre: ' nombre
    read -rp 'Ingrese nuevo precio: ' precio
    editar_producto "$id" "$nombre" "$precio"
}

mostrar() {
    mostrar_producto
    read -rp 'Presione Enter para continuar...' _
}

reporte() {
    generar_reporte
    read -rp 'Presione Enter para continuar...' _
}

main() {
    local acceso=0 opcion=0 id=0 nombre='' precio=''
    bienvenida
    while ((acceso == 0)); do
        printf '\nACCESO AL SISTEMA\n1. Iniciar sesión\n2. Registrarse\n3. Salir\n'
        read -rp 'Opción: ' opcion
        case "$opcion" in
            1) login && acceso=1 ;; 2) register ;;
            3) printf '\nSaliendo del programa...\n'; return 0 ;;
            *) printf 'Opción inválida.\n' ;;
        esac
        if ((acceso == 0)); then read -rp 'Presione Enter para continuar...' _; fi
    done
    while [[ "$opcion" != "$OPCION_SALIR" ]]; do
        printf '\nACCIONES:\n1. Alta producto\n2. Baja producto\n3. Editar producto\n4. Mostrar inventario\n5. Generar reporte HTML\n6. Salir\n'
        read -rp 'Opcion: ' opcion
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
main
