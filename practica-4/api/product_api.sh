#!/usr/bin/env bash

# Imprime el ID del producto creado.
api_product_new() {
    local id
    id=$(product_new "$1" "$2") || return
    log_new info "Producto creado: $id" "$CURRENT_USER_ID" || true
    printf '%s\n' "$id"
}

api_product_delete() {
    product_deactivate "$1" || return
    log_new info "Producto dado de baja: $1" "$CURRENT_USER_ID" || true
}

api_product_update() {
    product_update "$1" "$2" "$3" || return
    log_new info "Producto editado: $1" "$CURRENT_USER_ID" || true
}

# Imprime "nombre<TAB>precio" del producto activo.
api_product_get() { product_find "$1"; }

# Imprime una fila "id<TAB>nombre<TAB>precio<TAB>activo" por producto y registra la consulta.
api_product_list() {
    product_all || return
    log_new info 'Inventario consultado' "$CURRENT_USER_ID" || true
}

# Igual que api_product_list pero solo activos y sin registrar consulta
api_product_list_active() { product_all_active; }
