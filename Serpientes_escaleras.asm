extern printf
extern scanf
extern rand
extern srand
extern time

section .data
    msg_inicio         db "la senda: serpientes y escaleras - tablero 10x10", 10, 0
    msg_pedir_jug      db "ingrese numero de jugadores (1-3): ", 0
    msg_turno          db "jugador %d, presione enter para tirar el dado...", 10, 0
    msg_dado           db "valor del dado: %d", 10, 0
    msg_posicion       db "jugador %d movido a casilla %d", 10, 0
    msg_escalera       db "escalera: sube de %d a %d", 10, 0
    msg_serpiente      db "serpiente: baja de %d a %d", 10, 0
    msg_movimientos    db "movimientos jugador %d: %d", 10, 0
    msg_ganador        db "campeon jugador %d en %d movimientos", 10, 0
    msg_finales        db "estado final de los jugadores:", 10, 0
    msg_rival          db "rival %d quedo en casilla %d", 10, 0
    msg_reiniciar      db "desea reiniciar la partida? (1=si, 0=no): ", 0

    fmt_entero         db "%d", 0
    fmt_enter          db "%c", 0
    fmt_char           db "%c ", 0
    salto_linea_texto  db 10, 0

    simbolos_jug       db "abc"

    tablero_base db \
        0,0,0,0,0,0,0,0,0,0,\
        0,0,0,0,0,0,0,0,0,0,\
        0,0,0,0,0,0,0,0,0,0,\
        0,0,0,0,0,0,0,0,0,0,\
        0,0,0,0,0,0,0,0,0,0,\
        0,0,0,0,0,0,0,0,0,0,\
        0,0,0,0,0,0,0,0,0,0,\
        0,0,0,0,0,0,0,0,0,0,\
        0,0,0,0,0,0,0,0,0,0,\
        0,0,0,0,0,0,0,0,0,0

    escaleras_ini_db   db 3, 23, 43
    escaleras_fin_db   db 13, 33, 63
    escaleras_ini_dd   dd 3, 23, 43
    escaleras_fin_dd   dd 13, 33, 63

    serpientes_ini_db  db 59, 79, 99
    serpientes_fin_db  db 51, 71, 91
    serpientes_ini_dd  dd 59, 79, 99
    serpientes_fin_dd  dd 51, 71, 91

section .bss
    jug_total          resd 1
    jug_posiciones     resd 3
    jug_movimientos    resd 3
    buffer_enter       resb 4
    turno_actual       resd 1
    semilla_tick       resd 1
    bandera_reinicio   resd 1
    tablero            resb 100
    ganador_indice     resd 1

section .text
    global main

dibujar_tablero:
    push esi
    push edi
    push eax
    push ecx
    push edx

    mov esi, 9
fila_loop:
    ; terminar cuando esi < 0 (imprime filas 9..0)
    cmp esi, 0
    jl dibujar_terminado

    mov ecx, esi
    and ecx, 1
    cmp ecx, 0
    je izquierda_a_derecha

derecha_a_izquierda:
    mov edi, 9
columna_loop_derecha:
    ; terminar cuando edi < 0 (imprime columnas 9..0)
    cmp edi, 0
    jl salto_linea
    mov eax, esi
    imul eax, 10
    add eax, edi
    mov al, [tablero + eax]
    cmp al, 0
    jne imprimir_caracter_derecha
    mov al, '.'
imprimir_caracter_derecha:
    movzx eax, al
    push eax
    push fmt_char
    call printf
    add esp, 8
    dec edi
    jmp columna_loop_derecha

izquierda_a_derecha:
    mov edi, 0
columna_loop_izquierda:
    cmp edi, 10
    jge salto_linea
    mov eax, esi
    imul eax, 10
    add eax, edi
    mov al, [tablero + eax]
    cmp al, 0
    jne imprimir_caracter_izquierda
    mov al, '.'
imprimir_caracter_izquierda:
    movzx eax, al
    push eax
    push fmt_char
    call printf
    add esp, 8
    inc edi
    jmp columna_loop_izquierda

salto_linea:
    push salto_linea_texto
    call printf
    add esp, 4
    dec esi
    jmp fila_loop

dibujar_terminado:
    pop edx
    pop ecx
    pop eax
    pop edi
    pop esi
    ret


; Rutina: quita marcas de jugadores del tablero
limpiar_marcas_jugadores:
    push esi
    push ecx
    mov ecx, 100
    xor esi, esi
limpieza_loop:
    mov al, [tablero + esi]
    cmp al, 'a'
    je poner_cero
    cmp al, 'b'
    je poner_cero
    cmp al, 'c'
    je poner_cero
    jmp siguiente_celda
poner_cero:
    mov byte [tablero + esi], 0
siguiente_celda:
    inc esi
    loop limpieza_loop
    pop ecx
    pop esi
    ret

; Inicio principal
main:
inicio_partida:
    push ebp
    mov ebp, esp

    mov ecx, 100
    xor esi, esi
copia_tablero:
    mov al, [tablero_base + esi]
    mov [tablero + esi], al
    inc esi
    loop copia_tablero

    mov ecx, 3
    xor esi, esi
marcar_escaleras:
    movzx eax, byte [escaleras_ini_db + esi]
    mov byte [tablero + eax], '^'
    movzx eax, byte [escaleras_fin_db + esi]
    mov byte [tablero + eax], 'U'
    inc esi
    loop marcar_escaleras

    mov ecx, 3
    xor esi, esi
marcar_serpientes:
    movzx eax, byte [serpientes_ini_db + esi]
    mov byte [tablero + eax], 'S'
    movzx eax, byte [serpientes_fin_db + esi]
    mov byte [tablero + eax], 'D'
    inc esi
    loop marcar_serpientes

    push msg_inicio
    call printf
    add esp, 4

    push msg_pedir_jug
    call printf
    add esp, 4

    push jug_total
    push fmt_entero
    call scanf
    add esp, 8

    mov eax, [jug_total]
    cmp eax, 1
    jl fin_partida
    cmp eax, 3
    jg fin_partida

    xor ecx, ecx
inicializar_jugadores:
    mov dword [jug_posiciones + ecx*4], 0
    mov dword [jug_movimientos + ecx*4], 0
    inc ecx
    mov eax, [jug_total]
    cmp ecx, eax
    jl inicializar_jugadores

    mov dword [turno_actual], 0
    mov dword [semilla_tick], 0

ciclo_partida:
    call limpiar_marcas_jugadores
    mov ecx, [jug_total]
    xor esi, esi
colocar_jugadores:
    mov eax, [jug_posiciones + esi*4]
    movzx edx, byte [simbolos_jug + esi]
    mov byte [tablero + eax], dl
    inc esi
    cmp esi, ecx
    jl colocar_jugadores

    call dibujar_tablero

    mov ecx, [turno_actual]
    mov eax, ecx
    inc eax
    push eax
    push msg_turno
    call printf
    add esp, 8

    lea eax, [buffer_enter]
    push eax
    push fmt_enter
    call scanf
    add esp, 8

    mov eax, [semilla_tick]
    inc eax
    mov [semilla_tick], eax

    push 0
    call time
    add esp, 4
    mov ebx, eax
    mov eax, [semilla_tick]
    add ebx, eax
    push ebx
    call srand
    add esp, 4

    call rand
    xor edx, edx
    mov ecx, 6
    div ecx
    mov eax, edx
    inc eax
    mov ebx, eax

    push ebx
    push msg_dado
    call printf
    add esp, 8

    mov ecx, [turno_actual]
    mov eax, [jug_posiciones + ecx*4]
    add eax, ebx
    cmp eax, 99
    jle sin_ganar_directo
    mov dword [jug_posiciones + ecx*4], 99
    mov eax, [turno_actual]
    mov [ganador_indice], eax
    jmp anunciar_ganador

sin_ganar_directo:
    mov dword [jug_posiciones + ecx*4], eax

    xor esi, esi
ver_escalones:
    cmp esi, 3
    jge ver_serpientes
    mov eax, [jug_posiciones + ecx*4]
    cmp eax, dword [escaleras_ini_dd + esi*4]
    jne siguiente_escalon
    mov eax, dword [escaleras_fin_dd + esi*4]
    mov [jug_posiciones + ecx*4], eax
    mov edx, [escaleras_ini_dd + esi*4]
    push eax
    push edx
    push msg_escalera
    call printf
    add esp, 12
    jmp ver_serpientes
siguiente_escalon:
    inc esi
    jmp ver_escalones

ver_serpientes:
    xor esi, esi
loop_serpientes:
    cmp esi, 3
    jge despues_eventos
    mov eax, [jug_posiciones + ecx*4]
    cmp eax, dword [serpientes_ini_dd + esi*4]
    jne siguiente_serpiente
    mov eax, dword [serpientes_fin_dd + esi*4]
    mov [jug_posiciones + ecx*4], eax
    mov edx, [serpientes_ini_dd + esi*4]
    push eax
    push edx
    push msg_serpiente
    call printf
    add esp, 12
    jmp despues_eventos
siguiente_serpiente:
    inc esi
    jmp loop_serpientes

despues_eventos:
    mov eax, [jug_movimientos + ecx*4]
    inc eax
    mov [jug_movimientos + ecx*4], eax

    mov eax, [jug_posiciones + ecx*4]
    mov edx, [turno_actual]
    inc edx
    push eax
    push edx
    push msg_posicion
    call printf
    add esp, 12

    mov eax, [jug_movimientos + ecx*4]
    mov edx, [turno_actual]
    inc edx
    push eax
    push edx
    push msg_movimientos
    call printf
    add esp, 12

    mov eax, [jug_posiciones + ecx*4]
    cmp eax, 99
    jne avanzar_turno

    mov eax, [turno_actual]
    mov [ganador_indice], eax
    jmp anunciar_ganador

avanzar_turno:
    mov eax, [turno_actual]
    inc eax
    mov ecx, [jug_total]
    cmp eax, ecx
    jl guardar_turno
    xor eax, eax
guardar_turno:
    mov [turno_actual], eax
    jmp ciclo_partida

; Mostrar resultados y preguntar reinicio
anunciar_ganador:
    call limpiar_marcas_jugadores
    mov ecx, [jug_total]
    xor esi, esi
colocar_final:
    mov eax, [jug_posiciones + esi*4]
    movzx edx, byte [simbolos_jug + esi]
    mov [tablero + eax], dl
    inc esi
    cmp esi, ecx
    jl colocar_final

    call dibujar_tablero

    mov eax, [ganador_indice]
    inc eax
    mov ebx, [ganador_indice]
    mov ebx, [jug_movimientos + ebx*4]
    push ebx
    push eax
    push msg_ganador
    call printf
    add esp, 12

    push msg_finales
    call printf
    add esp, 4

    xor esi, esi
    mov ebx, [ganador_indice]
    mov eax, [jug_total]
    cmp eax, 1
    je preguntar_reiniciar

    xor esi, esi
    mov ebx, [ganador_indice]
lista_finales:
    mov eax, esi
    cmp eax, [jug_total]
    jge preguntar_reiniciar
    cmp esi, ebx
    je omitir_ganador
    mov edx, [jug_posiciones + esi*4]
    mov eax, esi
    inc eax
    push edx
    push eax
    push msg_rival
    call printf
    add esp, 12
omitir_ganador:
    inc esi
    jmp lista_finales

preguntar_reiniciar:
    push msg_reiniciar
    call printf
    add esp, 4

    push bandera_reinicio
    push fmt_entero
    call scanf
    add esp, 8

    mov eax, [bandera_reinicio]
    cmp eax, 1
    jne fin_partida

    ; reiniciar: volver a inicio_partida (si deseas reinicializar más cosas, añadir aquí)
    jmp inicio_partida

fin_partida:
    ; Restaurar pila/registro y terminar
    mov eax, 0
    leave
    ret
