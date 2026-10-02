#!/usr/bin/env bash

declare -r -i MAX=3
declare -A inventario

declare -r -i OPCION_ALTA=1
declare -r -i OPCION_BAJA=2
declare -r -i OPCION_EDITAR=3
declare -r -i OPCION_MOSTRAR=4
declare -r -i OPCION_SALIR=5

bienvenida() {
    printf "Bienvenido/a al sistema\n\n"
}

login() {
    local user=""
    local password=""

    read -rp "Ingrese usuario: " user
    read -rsp "Ingrese contraseña: " password
    printf "\n"

    if [[ -f "usuarios.tsv" ]]; then
        if grep -q "^$user:$password$" "usuarios.tsv"; then
            printf "Login exitoso.\n"
            return 0
        else
            printf "Usuario o contraseña incorrectos.\n"
            return 1
        fi
    else
        printf "Archivo de usuarios no encontrado.\n"
        return 1
    fi
}

register() {
    declare local user=""
    declare local password=""
    declare local confirm_password=""

    read -rp "Ingrese nuevo usuario: " user
    read -rsp "Ingrese nueva contraseña: " password
    printf "\n"
    read -rsp "Confirme nueva contraseña: " confirm_password
    printf "\n"

    if [[ "$password" != "$confirm_password" ]]; then
        printf "Las contraseñas no coinciden.\n"
        return 1
    fi

    if [[ -f "usuarios.tsv" ]]; then
        if grep -q "^$user:" "usuarios.tsv"; then
            printf "El usuario ya existe.\n"
            return 1
        fi
    fi

    echo "$user:$password" >> "usuarios.tsv"
    printf "Usuario registrado exitosamente.\n"
    return 0
}

mostrar() {
    if [[ -f "inventario.tsv" ]]; then
        while IFS=$'\t' read -r id precio activo; do
            inventario[$id,precio]=$precio
            inventario[$id,activo]=$activo
        done < "inventario.tsv"
    fi
}

alta() {
    {
        for ((i=0; i<MAX; i++)); do
            printf "%d\t%.2f\t%d\n" "$i" "${inventario[$i,precio]}" "${inventario[$i,activo]}"
        done
    } >> "inventario.tsv"
}

baja() {
}

editar(){

}

main() {
    declare -i i=0

    for ((i=0; i<MAX; i++)); do
        inventario[$i,activo]=0
        inventario[$i,precio]=0
    done

    bienvenida

    while [[ ! -f "usuarios.tsv" ]]; do
        printf "Archivo de usuarios no encontrado. Por favor registre un usuario.\n"
        register
    done

    while ! login; do
        printf "Intento de login fallido. Por favor intente nuevamente.\n"
    done

    declare opcion=0
    declare -i id=0
    declare -A p_temp

    while [[ "$opcion" != "$OPCION_SALIR" ]]; do
        printf "\nACCIONES:\n"
        printf "1. Alta producto (ID 0 a %d)\n" $((MAX - 1))
        printf "2. Baja producto\n"
	printf "3. Editar producto \n"
        printf "4. Mostrar inventario\n"
        printf "5. Salir\n"
        read -rp "Opcion: " opcion

        case $opcion in
            $OPCION_ALTA)
                read -rp "Ingrese ID (0-$((MAX - 1))): " id
                read -rp "Ingrese Precio: " p_temp[precio]
                p_temp[activo]=1
                alta "$id" p_temp
                ;;
            $OPCION_BAJA)
                read -rp "Ingrese ID a eliminar (0-$((MAX - 1))): " id
                baja "$id"
                ;;
	    $OPCION_EDITAR)
                read -rp "Ingrese ID a editar (0-$((MAX - 1))): " id
                read -rp "Ingrese nuevo precio: " 'p_temp[precio]'
                p_temp[activo]=1
                editar "$id" p_temp
                ;;
            $OPCION_MOSTRAR)
                mostrar
                ;;
            $OPCION_SALIR)
                printf "\nSaliendo del programa...\n"
                ;;
            *)
                printf "\nOpcion invalida.\n"
                ;;
        esac
    done

    return 0
}

main
