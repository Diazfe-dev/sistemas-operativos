#!/usr/bin/env bash

declare -A inventario

declare -r -i OPCION_ALTA=1
declare -r -i OPCION_BAJA=2
declare -r -i OPCION_EDITAR=3
declare -r -i OPCION_MOSTRAR=4
declare -r -i OPCION_REPORTE=5
declare -r -i OPCION_SALIR=6

bienvenida() {
    printf "Bienvenido/a al sistema\n\n"
}

login() {
    local user=""
    local password=""
    local linea usuario clave encontrado=0

    read -rp "Ingrese usuario: " user
    read -rsp "Ingrese contraseña: " password
    printf "\n"

    if [[ -f "usuarios.tsv" ]]; then
        while IFS= read -r linea; do
            usuario=${linea%%:*}
            clave=${linea#*:}
            if [[ "$usuario" == "$user" && "$clave" == "$password" ]]; then
                encontrado=1
                break
            fi
        done < "usuarios.tsv"

        if ((encontrado)); then
            printf "Login exitoso.\n"
            return 0
        fi

        printf "Usuario o contraseña incorrectos.\n"
        return 1
    else
        printf "Archivo de usuarios no encontrado.\n"
        return 1
    fi
}

register() {
    declare local user=""
    declare local password=""
    declare local confirm_password=""
    declare local linea usuario=""

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
        while IFS= read -r linea; do
            usuario=${linea%%:*}
            if [[ "$usuario" == "$user" ]]; then
                printf "El usuario ya existe.\n"
                return 1
            fi
        done < "usuarios.tsv"
    fi

    echo "$user:$password" >> "usuarios.tsv"
    printf "Usuario registrado exitosamente.\n"
    return 0
}

cargar_inventario() {
    local id nombre precio activo

    [[ -f "inventario.tsv" ]] || return 0

    while IFS=$'\t' read -r id nombre precio activo; do
        [[ "$id" =~ ^[0-9]+$ ]] || continue
        # Compatibilidad con el formato anterior: id, precio, activo.
        if [[ -z "$activo" && "$precio" =~ ^[01]$ ]]; then
            activo=$precio
            precio=$nombre
            nombre=""
        fi
        inventario[$id,nombre]=$nombre
        inventario[$id,precio]=$precio
        inventario[$id,activo]=$activo
    done < "inventario.tsv"
}

guardar_inventario() {
    local archivo_temporal="inventario.tsv.tmp"
    local id

    : > "$archivo_temporal" || return 1
    for id in $(printf '%s\n' "${!inventario[@]}" | cut -d, -f1 | sort -nu); do
        printf "%d\t%s\t%s\t%d\n" "$id" "${inventario[$id,nombre]}" "${inventario[$id,precio]}" "${inventario[$id,activo]}" >> "$archivo_temporal"
    done
    mv "$archivo_temporal" "inventario.tsv"
}

mostrar() {
    local id
    printf "\nID\tNombre\tPrecio\tActivo\n"
    for id in $(printf '%s\n' "${!inventario[@]}" | cut -d, -f1 | sort -nu); do
        printf "%d\t%s\t%s\t%d\n" "$id" "${inventario[$id,nombre]}" "${inventario[$id,precio]}" "${inventario[$id,activo]}"
    done
}

generar_reporte() {
    local id
    local archivo="reporte_inventario.html"

    {
        printf '%s\n' '<!DOCTYPE html>'
        printf '%s\n' '<html lang="es">'
        printf '%s\n' '<head>'
        printf '%s\n' '  <meta charset="UTF-8">'
        printf '%s\n' '  <title>Reporte de inventario</title>'
        printf '%s\n' '</head>'
        printf '%s\n' '<body>'
        printf '%s\n' '  <h1>Reporte de inventario</h1>'
        printf '%s\n' '  <table border="1">'
        printf '%s\n' '    <tr><th>ID</th><th>Nombre</th><th>Precio</th><th>Activo</th></tr>'
        for id in $(printf '%s\n' "${!inventario[@]}" | cut -d, -f1 | sort -nu); do
            printf '    <tr><td>%d</td><td>%s</td><td>%s</td><td>%d</td></tr>\n' \
                "$id" "${inventario[$id,nombre]}" "${inventario[$id,precio]}" "${inventario[$id,activo]}"
        done
        printf '%s\n' '  </table>'
        printf '%s\n' '</body>'
        printf '%s\n' '</html>'
    } > "$archivo"

    printf "Reporte generado en %s.\n" "$archivo"
}

validar_id() {
    [[ "$1" =~ ^[0-9]+$ ]]
}

validar_precio() {
    [[ "$1" =~ ^[0-9]+([.][0-9]{1,2})?$ ]]
}

validar_nombre() {
    [[ -n "$1" && "$1" != *$'\t'* ]]
}

alta() {
    local nombre=$1 precio=$2
    local id=0 clave registro_id

    if ! validar_nombre "$nombre" || ! validar_precio "$precio"; then
        printf "Nombre o precio invalido.\n"
        return 1
    fi

    if ((${#inventario[@]} > 0)); then
        for clave in "${!inventario[@]}"; do
            [[ "$clave" == *,precio ]] || continue
            registro_id=${clave%,precio}
            ((registro_id >= id)) && id=$((registro_id + 1))
        done
    fi

    inventario[$id,nombre]=$nombre
    inventario[$id,precio]=$precio
    inventario[$id,activo]=1
    guardar_inventario
    printf "Producto dado de alta con ID %d.\n" "$id"
}

baja() {
    local id=$1
    if ! validar_id "$id"; then
        printf "ID invalido.\n"
        return 1
    fi
    if [[ "${inventario[$id,activo]}" -ne 1 ]]; then
        printf "El producto no existe.\n"
        return 1
    fi
    inventario[$id,activo]=0
    guardar_inventario
    printf "Producto dado de baja.\n"
}

editar() {
    local id=$1 nombre=$2 precio=$3
    if ! validar_id "$id" || ! validar_nombre "$nombre" || ! validar_precio "$precio"; then
        printf "ID, nombre o precio invalido.\n"
        return 1
    fi
    if [[ "${inventario[$id,activo]}" -ne 1 ]]; then
        printf "El producto no existe.\n"
        return 1
    fi
    inventario[$id,nombre]=$nombre
    inventario[$id,precio]=$precio
    guardar_inventario
    printf "Producto editado.\n"
}

main() {
    declare -i i=0

    cargar_inventario

    bienvenida

    local acceso=0
    while ((acceso == 0)); do
        clear
        printf "\nACCESO AL SISTEMA\n"
        printf "1. Iniciar sesión\n"
        printf "2. Registrarse\n"
        printf "3. Salir\n"
        read -rp "Opción: " opcion

        case "$opcion" in
            1)
                if login; then
                    acceso=1
                fi
                ;;
            2)
                register
                ;;
            3)
                printf "\nSaliendo del programa...\n"
                return 0
                ;;
            *)
                printf "Opción inválida.\n"
                ;;
        esac

        if ((acceso == 0)); then
            read -rp "Presione Enter para continuar..." _
        fi
    done

    declare opcion=0
    declare -i id=0
    declare -A p_temp

    while [[ "$opcion" != "$OPCION_SALIR" ]]; do
        clear
        printf "\nACCIONES:\n"
        printf "1. Alta producto\n"
        printf "2. Baja producto\n"
	printf "3. Editar producto \n"
        printf "4. Mostrar inventario\n"
        printf "5. Generar reporte HTML\n"
        printf "6. Salir\n"
        read -rp "Opcion: " opcion

        case $opcion in
            $OPCION_ALTA)
                read -rp "Ingrese Nombre: " nombre
                read -rp "Ingrese Precio: " precio
                alta "$nombre" "$precio"
                ;;
            $OPCION_BAJA)
                read -rp "Ingrese ID a eliminar: " id
                baja "$id"
                ;;
            $OPCION_EDITAR)
                read -rp "Ingrese ID a editar: " id
                read -rp "Ingrese nuevo nombre: " nombre
                read -rp "Ingrese nuevo precio: " precio
                editar "$id" "$nombre" "$precio"
                ;;
            $OPCION_MOSTRAR)
                mostrar
                read -rp "Presione Enter para continuar..." _
                ;;
            $OPCION_REPORTE)
                generar_reporte
                read -rp "Presione Enter para continuar..." _
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
