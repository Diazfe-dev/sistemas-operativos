#!/usr/bin/env bash

declare -g -r TUI_TITULO='Sistema de inventario'

# whiptail dibuja la interfaz en stdout y escribe la respuesta en stderr,
# pero $(...) solo captura stdout: por eso se intercambian los descriptores.
# N>&M significa "el descriptor N apunta a donde apunta M en este momento".
# 3>&1  el descriptor auxiliar 3 guarda el destino original de stdout (la captura de $(...)).
# 1>&2  stdout pasa a apuntar a la terminal, para que whiptail dibuje en pantalla.
# 2>&3  stderr pasa a apuntar a la captura, así la respuesta queda en la variable.
tui_input() { whiptail --title "$TUI_TITULO" --inputbox "$1" 10 60 "${2:-}" 3>&1 1>&2 2>&3; }
tui_password() { whiptail --title "$TUI_TITULO" --passwordbox "$1" 10 60 3>&1 1>&2 2>&3; }
tui_mensaje() { whiptail --title "$TUI_TITULO" --msgbox "$1" 12 60; }
tui_confirmar() { whiptail --title "$TUI_TITULO" --yesno "$1" 10 60; }


# Función para el login de usuario
tui_login() {
    local user password
    # Guardamos la salida de tui input en la variable user
    user=$(tui_input 'Ingrese usuario:') || return 1

    # Guardamos la salida de tui_password en la variable password
    password=$(tui_password 'Ingrese contraseña:') || return 1

    # Llama a la API de login con el usuario y contraseña ingresados.
    if api_user_login "$user" "$password";

    # Si todo esta bien mostramos mensaje de éxito. Retornamos status code 0
    then tui_mensaje 'Login exitoso.'; return 0; fi

    # Si no mostramos un mensaje de error. Retornamos status code 1
    tui_mensaje 'Usuario o contraseña incorrectos.'; return 1
}

# Función para el registro de usuario
tui_register() {
    # Variables locales para el registro de usuario
    local user password confirm_password

    # Pedimos al usuario que ingrese los datos de registro
    user=$(tui_input 'Ingrese nuevo usuario:') || return 1

    # Guardamos la salida de tui_password en la variable password
    password=$(tui_password 'Ingrese nueva contraseña:') || return 1

    # Guardamos la salida de tui_password en la variable confirm_password
    confirm_password=$(tui_password 'Confirme nueva contraseña:') || return 1

    # Verificamos que las contraseñas coincidan antes de llamar a la API de registro
    if [[ "$password" != "$confirm_password" ]]; 
    
    # Si no, mostramos un mensaje de error y retornamos status code 1
    then tui_mensaje 'Las contraseñas no coinciden.'; return 1; fi

    # Llamamos a la API de registro con el usuario y contraseña proporcionados
    api_user_register "$user" "$password"
    case $? in
        # Dependiendo del código de error retornado por la API mostramos un mensaje adecuado
        0) tui_mensaje 'Usuario registrado exitosamente.' ;;
        # Status code = 1
        "$ERR_INVALID") tui_mensaje 'Usuario y contraseña son obligatorios.' ;;
        # Status code = 2
        "$ERR_EXISTS") tui_mensaje 'El usuario ya existe.' ;;
        # Status code = 3
        *) tui_mensaje 'No se pudo registrar el usuario.' ;;
    esac
}

# Funciones para la gestión de productos

# Esta funcion nos permite seleccionar un producto activo de la lista mediante un menú interactivo.
tui_elegir_producto() {
    
    # Variables locales para la selección de producto
    local id nombre precio activo opciones=()
    
    # Obtenemos la lista de productos activos y construimos las opciones para el menú
    while IFS=$'\t' read -r id nombre precio activo; do
        opciones+=("$id" "$nombre (\$$precio)")
    done < <(api_product_list_active)
    
    # Si no hay productos activos mostramos un mensaje y retornamos status code 1
    if ((${#opciones[@]} == 0)); then tui_mensaje 'No hay productos activos.'; return 1; fi

    # Mostramos el menú interactivo para seleccionar un producto activo
    whiptail --title "$TUI_TITULO" --menu "$1" 20 60 10 "${opciones[@]}" 3>&1 1>&2 2>&3
}


# Esta funcion nos permite dar de alta un nuevo producto.
tui_alta() {
    
    # Variables locales para el nuevo producto
    local nombre precio id

    # Solicitamos al usuario el nombre y precio del nuevo producto
    nombre=$(tui_input 'Ingrese nombre:') || return 1
    precio=$(tui_input 'Ingrese precio:') || return 1

    # Llamamos a la API para crear el nuevo producto y mostramos un mensaje según el resultado
    if id=$(api_product_new "$nombre" "$precio"); then tui_mensaje "Producto dado de alta con ID $id."
    
    # Si la creación del producto falla mostramos un mensaje de error
    else tui_mensaje "$(mensaje_error $?)"; fi
}

# Esta funcion nos permite dar de baja un producto activo.
tui_baja() {

    # Solicitamos al usuario seleccionar un producto activo para dar de baja
    local id

    # Variables locales para la selección de producto a dar de baja
    id=$(tui_elegir_producto 'Seleccione el producto a dar de baja:') || return 1

    # Confirmamos la baja del producto seleccionado
    tui_confirmar "¿Confirma la baja del producto $id?" || return 1

    # Llamamos a la API para dar de baja el producto y mostramos un mensaje según el resultado
    if api_product_delete "$id"; then tui_mensaje 'Producto dado de baja.'

    # Si la baja del producto falla mostramos un mensaje de error
    else tui_mensaje "$(mensaje_error $?)"; fi
}

# Esta funcion nos permite editar un producto activo.
tui_editar() {

    # Variables locales para la edición del producto
    local id producto nombre precio

    # Solicitamos al usuario seleccionar un producto activo para editar
    id=$(tui_elegir_producto 'Seleccione el producto a editar:') || return 1

    # Obtenemos los datos del producto seleccionado mediante la API
    producto=$(api_product_get "$id") || { tui_mensaje "$(mensaje_error $?)"; return 1; }

    # Obtenemos el nombre y precio actuales del producto seleccionado
    IFS=$'\t' read -r nombre precio <<< "$producto"

    # Solicitamos al usuario ingresar el nuevo nombre y precio del producto
    nombre=$(tui_input 'Ingrese nuevo nombre:' "$nombre") || return 1
    precio=$(tui_input 'Ingrese nuevo precio:' "$precio") || return 1

    # Llamamos a la API para actualizar el producto con los nuevos datos y mostramos un mensaje según el resultado
    if api_product_update "$id" "$nombre" "$precio"; then tui_mensaje 'Producto editado.'

    # Si la actualización del producto falla mostramos un mensaje de error
    else tui_mensaje "$(mensaje_error $?)"; fi
}

# Esta funcion nos permite mostrar el inventario de productos.
tui_mostrar() {
    # Variables locales para almacenar el inventario
    local inventario

    # Obtenemos el inventario mediante la API
    inventario=$(api_product_list) || { tui_mensaje "$(mensaje_error $?)"; return 1; }

    # Mostramos el inventario en un cuadro de mensaje con scroll
    whiptail --title "$TUI_TITULO" --scrolltext --msgbox "$(formatear_inventario <<< "$inventario")" 20 70
}

# Esta funcion nos permite generar un reporte HTML del inventario.
tui_reporte() {
    # Variable local para almacenar el nombre del archivo del reporte
    local archivo

    # Generamos el reporte mediante la API y mostramos un mensaje según el resultado
    if archivo=$(api_report_generate); then tui_mensaje "Reporte generado en $archivo."

    # Si la generación del reporte falla mostramos un mensaje de error
    else tui_mensaje "$(mensaje_error $?)"; fi
}

# Esta funcion es el punto de entrada principal de la interfaz TUI.
tui_main() {
    # Variable local para almacenar la opción seleccionada por el usuario
    local opcion
    # Verificamos si whiptail está instalado, si no mostramos un mensaje de error y salimos
    if ! command -v whiptail >/dev/null; then
        printf 'whiptail no está instalado. Use --cli o instale el paquete whiptail.\n' >&2; return 1
    fi

    # Mostramos el menú de acceso al sistema hasta que el usuario inicie sesión o salga
    while :; do
        opcion=$(whiptail --title "$TUI_TITULO" --menu 'Acceso al sistema' 15 50 3 \
            1 'Iniciar sesión' 2 'Registrarse' 3 'Salir' 3>&1 1>&2 2>&3) || { clear; return 0; }
        case "$opcion" in
            1) tui_login && break ;;
            2) tui_register ;;
            3) clear; return 0 ;;
        esac
    done
    
    # Mostramos el menú de acciones hasta que el usuario decida salir
    while :; do
        opcion=$(whiptail --title "$TUI_TITULO" --menu 'Acciones' 18 50 6 \
            "$OPCION_ALTA" 'Alta producto' \
            "$OPCION_BAJA" 'Baja producto' \
            "$OPCION_EDITAR" 'Editar producto' \
            "$OPCION_MOSTRAR" 'Mostrar inventario' \
            "$OPCION_REPORTE" 'Generar reporte HTML' \
            "$OPCION_SALIR" 'Salir' 3>&1 1>&2 2>&3) || { clear; return 0; }
        case "$opcion" in
            "$OPCION_ALTA") tui_alta ;;
            "$OPCION_BAJA") tui_baja ;;
            "$OPCION_EDITAR") tui_editar ;;
            "$OPCION_MOSTRAR") tui_mostrar ;;
            "$OPCION_REPORTE") tui_reporte ;;
            "$OPCION_SALIR") clear; return 0 ;;
        esac
    done
}
