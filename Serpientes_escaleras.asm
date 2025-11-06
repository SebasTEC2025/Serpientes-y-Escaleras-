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
    fmt_char2          db "%c%c ", 0
    salto_linea_texto  db 10, 0

    ; Mensajes de depuración para mostrar lo generado
    msg_gen_ladder     db "Escalera %d: inicio=%d fin=%d", 10, 0
    msg_gen_snake      db "Serpiente %d: cabeza=%d cola=%d", 10, 0

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

 

section .bss
    jug_total          resd 1
    jug_posiciones     resd 3
    jug_movimientos    resd 3
    buffer_enter       resb 4
    turno_actual       resd 1
    semilla_tick       resd 1
    bandera_reinicio   resd 1
    tablero            resb 100
    tablero_jugadores  resb 100
    ganador_indice     resd 1
    columnas_usadas    resb 10
    gen_counter        resd 1
    
    escaleras_ini_dd   resd 3
    escaleras_fin_dd  resd 3

    serpientes_ini_dd resd 3
    serpientes_fin_dd resd 3

section .text
    global main

; generar_especiales:
; - Llena únicamente los arrays dword (escaleras_ini_dd / escaleras_fin_dd / serpientes_ini_dd / serpientes_fin_dd)
; - Escaleras: start = (rand()%89) + 1 -> 1..89, end = start + 10 -> 11..99
; - Serpientes: head = (rand()%89) + 11 -> 11..99, tail = head - 10 -> 1..89
; - Evita solapamientos exactos entre inicios/fines ya guardados y evita solapamiento serpiente<->escalera
; - No escribe a arrays db (esto evitó múltiples errores de operand sizes)
generar_especiales:
    pushad

    mov eax, [gen_counter]
    test eax, eax
    jnz .gc_ok
    mov dword [gen_counter], 1
.gc_ok:

    ; limpiar columnas_usadas (opcional)
    mov ecx, 10
    xor edi, edi
.clear_cols:
    mov byte [columnas_usadas + edi], 0
    inc edi
    loop .clear_cols

    ; generar 3 escaleras (start = 1..89, end = start + 10)
    xor esi, esi            ; i = 0
.ladder_outer:
    cmp esi, 3
    jge .snake_start

.ladder_try:
    ; reseed srand con time + gen_counter (varía semilla entre intentos)
    call time
    add eax, [gen_counter]
    push eax
    call srand
    add esp, 4
    ; incrementar gen_counter
    mov eax, [gen_counter]
    inc eax
    mov [gen_counter], eax

    call rand
    xor edx, edx
    mov ecx, 89
    div ecx                ; EDX = rand % 89 (0..88)
    mov ebx, edx
    inc ebx                ; ebx = start (1..89)
    mov eax, ebx
    add eax, 10            ; eax = end (11..99)

    ; evitar solapamientos exactos con escaleras previas
    xor edi, edi
.check_ladders_dup:
    cmp edi, esi
    jge .save_ladder
    mov edx, dword [escaleras_ini_dd + edi*4]
    cmp edx, ebx
    je .ladder_try
    mov edx, dword [escaleras_fin_dd + edi*4]
    cmp edx, eax
    je .ladder_try
    inc edi
    jmp .check_ladders_dup

.save_ladder:
    mov dword [escaleras_ini_dd + esi*4], ebx
    mov dword [escaleras_fin_dd + esi*4], eax
    inc esi
    jmp .ladder_outer

; generar 3 serpientes (head = 11..99, tail = head - 10)
.snake_start:
    xor esi, esi

.snake_outer:
    cmp esi, 3
    jge .print_generated

.snake_try:
    ; reseed srand con time + gen_counter
    call time
    add eax, [gen_counter]
    push eax
    call srand
    add esp, 4
    ; incrementar gen_counter
    mov eax, [gen_counter]
    inc eax
    mov [gen_counter], eax

    call rand
    xor edx, edx
    mov ecx, 89
    div ecx                ; EDX = 0..88
    mov ebx, edx
    add ebx, 11            ; ebx = head (11..99)
    mov eax, ebx
    sub eax, 10            ; eax = tail (1..89)

    ; evitar solapamientos exactos con serpientes previas
    xor edi, edi
.check_snakes_dup:
    cmp edi, esi
    jge .check_ladders_conf
    mov edx, dword [serpientes_ini_dd + edi*4]
    cmp edx, ebx
    je .snake_try
    mov edx, dword [serpientes_fin_dd + edi*4]
    cmp edx, eax
    je .snake_try
    inc edi
    jmp .check_snakes_dup

    ; evitar coincidencia exacta con cualquier escalera (start/end)
.check_ladders_conf:
    xor edi, edi
.check_ladder_loop:
    cmp edi, 3
    jge .save_snake
    mov edx, dword [escaleras_ini_dd + edi*4]
    cmp edx, ebx
    je .snake_try
    mov edx, dword [escaleras_fin_dd + edi*4]
    cmp edx, ebx
    je .snake_try
    mov edx, dword [escaleras_ini_dd + edi*4]
    cmp edx, eax
    je .snake_try
    mov edx, dword [escaleras_fin_dd + edi*4]
    cmp edx, eax
    je .snake_try
    inc edi
    jmp .check_ladder_loop

.save_snake:
    mov dword [serpientes_ini_dd + esi*4], ebx
    mov dword [serpientes_fin_dd + esi*4], eax
    inc esi
    jmp .snake_outer

; imprimir lo generado (depuración)
.print_generated:
    xor esi, esi
.print_ladders_loop:
    cmp esi, 3
    jge .print_snakes
    mov eax, [escaleras_ini_dd + esi*4]
    mov edx, [escaleras_fin_dd + esi*4]
    mov ecx, esi
    inc ecx
    push edx
    push eax
    push ecx
    push msg_gen_ladder
    call printf
    add esp, 16
    inc esi
    jmp .print_ladders_loop

.print_snakes:
    xor esi, esi
.print_snakes_loop:
    cmp esi, 3
    jge .gen_done
    mov eax, [serpientes_ini_dd + esi*4]
    mov edx, [serpientes_fin_dd + esi*4]
    mov ecx, esi
    inc ecx
    push edx
    push eax
    push ecx
    push msg_gen_snake
    call printf
    add esp, 16
    inc esi
    jmp .print_snakes_loop

.gen_done:
    popad
    ret

; ------------------ resto del programa ------------------

dibujar_tablero:
    push esi
    push edi
    push eax
    push ecx
    push edx
    push ebx

    mov esi, 9
fila_loop:
    cmp esi, 0
    jl dibujar_terminado

    mov ecx, esi
    and ecx, 1
    cmp ecx, 0
    je izquierda_a_derecha

derecha_a_izquierda:
    mov edi, 9
columna_loop_derecha:
    cmp edi, 0
    jl salto_linea

    mov eax, esi
    imul eax, 10
    add eax, edi

    mov bl, [tablero + eax]
    cmp bl, 0
    jne tile_ok_d
    mov bl, '.'
tile_ok_d:
    mov dl, [tablero_jugadores + eax]
    cmp dl, 0
    jne have_marker_d
    mov dl, '.'
have_marker_d:
    movzx eax, dl
    push eax
    movzx eax, bl
    push eax
    push fmt_char2
    call printf
    add esp, 12

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

    mov bl, [tablero + eax]
    cmp bl, 0
    jne tile_ok_i
    mov bl, '.'
tile_ok_i:
    mov dl, [tablero_jugadores + eax]
    cmp dl, 0
    jne have_marker_i
    mov dl, '.'
have_marker_i:
    movzx eax, dl
    push eax
    movzx eax, bl
    push eax
    push fmt_char2
    call printf
    add esp, 12

    inc edi
    jmp columna_loop_izquierda

salto_linea:
    push salto_linea_texto
    call printf
    add esp, 4
    dec esi
    jmp fila_loop

dibujar_terminado:
    pop ebx
    pop edx
    pop ecx
    pop eax
    pop edi
    pop esi
    ret

limpiar_marcas_jugadores:
    push esi
    push ecx
    mov ecx, 100
    xor esi, esi
limpieza_loop:
    mov byte [tablero_jugadores + esi], '.'
    inc esi
    loop limpieza_loop
    pop ecx
    pop esi
    ret

colocar_jugadores:
    push esi
    push edi
    push eax
    push ebx
    push ecx
    push edx

    mov ecx, [jug_total]
    xor esi, esi
colocar_loop:
    cmp esi, ecx
    jge colocar_fin

    mov eax, [jug_posiciones + esi*4]   ; pos
    mov bl, [simbolos_jug + esi]       ; player char 'a'/'b'/'c'
    mov dl, [tablero_jugadores + eax]  ; current marker
    cmp dl, '.'
    je colocar_simple
    cmp dl, bl
    je colocar_skip

    cmp dl, 'a'
    je cur_a
    cmp dl, 'b'
    je cur_b
    cmp dl, 'c'
    je cur_c
    cmp dl, '4'
    je cur_4
    cmp dl, '5'
    je cur_5
    cmp dl, '6'
    je cur_6
    cmp dl, '7'
    je colocar_skip

cur_a:
    cmp bl, 'b'
    je set_4
    cmp bl, 'c'
    je set_6
    jmp colocar_skip

cur_b:
    cmp bl, 'a'
    je set_4
    cmp bl, 'c'
    je set_5
    jmp colocar_skip

cur_c:
    cmp bl, 'a'
    je set_6
    cmp bl, 'b'
    je set_5
    jmp colocar_skip

cur_4:
    cmp bl, 'c'
    je set_7
    jmp colocar_skip

cur_5:
    cmp bl, 'a'
    je set_7
    jmp colocar_skip

cur_6:
    cmp bl, 'b'
    je set_7
    jmp colocar_skip

set_4:
    mov byte [tablero_jugadores + eax], '4'
    jmp colocar_next
set_5:
    mov byte [tablero_jugadores + eax], '5'
    jmp colocar_next
set_6:
    mov byte [tablero_jugadores + eax], '6'
    jmp colocar_next
set_7:
    mov byte [tablero_jugadores + eax], '7'
    jmp colocar_next

colocar_simple:
    mov [tablero_jugadores + eax], bl
    jmp colocar_next

colocar_skip:
    jmp colocar_next

colocar_next:
    inc esi
    jmp colocar_loop

colocar_fin:
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop edi
    pop esi
    ret

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

    call generar_especiales

    mov ecx, 3
    xor esi, esi
marcar_escaleras:
    mov eax, [escaleras_ini_dd + esi*4]
    mov byte [tablero + eax], 'I'    ; inicio escalera = 'I'
    mov eax, [escaleras_fin_dd + esi*4]
    mov byte [tablero + eax], 'U'
    inc esi
    loop marcar_escaleras

    mov ecx, 3
    xor esi, esi
marcar_serpientes:
    mov eax, [serpientes_ini_dd + esi*4]
    mov byte [tablero + eax], 'S'
    mov eax, [serpientes_fin_dd + esi*4]
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
    call colocar_jugadores
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

    jmp inicio_partida

fin_partida:
    mov eax, 0
    leave
    ret