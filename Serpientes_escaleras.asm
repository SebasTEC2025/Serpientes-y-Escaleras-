extern printf
extern scanf
extern rand
extern srand
extern time

section .data
    mensaje_inicio        db "La Senda: Serpientes y Escalones - Tablero 10x10", 10, 0
    mensaje_pedir_jug     db "Ingrese numero de jugadores (2-5 jugadores): ", 0
    mensaje_turno         db "Jugador %d, presione ENTER para tirar el dado...", 10, 0
    mensaje_dado          db "Valor del dado: %d", 10, 0
    mensaje_posicion      db "Jugador %d movido a casilla %d", 10, 0
    mensaje_escalon       db "Escalon: sube de %d a %d", 10, 0
    mensaje_serpiente     db "Serpiente: baja de %d a %d", 10, 0
    mensaje_movimientos   db "Movimientos Jugador %d: %d", 10, 0
    mensaje_campeon       db "¡Campeon! Jugador %d en %d movimientos.", 10, 0
    mensaje_finales       db "Estados finales de los jugadores:", 10, 0
    mensaje_rival         db "Rival %d quedo en casilla %d", 10, 0
    mensaje_reiniciar     db "¿Desea reiniciar la partida? (1=Si, 0=No): ", 0
    formato_entero        db "%d", 0
    formato_enter         db "%c", 0

    simbolos_jugadores    db "ABCDE"

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

    escaleras_origen_dd dd 3, 23, 43
    escaleras_destino_dd dd 13, 33, 63
    escaleras_inicio_db db 3, 23, 43
    escaleras_fin_db db 13, 33, 63

    serpientes_origen_dd dd 59, 79, 99
    serpientes_destino_dd dd 51, 71, 91
    serpientes_inicio_db db 59, 79, 99
    serpientes_fin_db db 51, 71, 91

    nueva_linea db 10,0
    fmt_char db "%c ",0

SEBAS

section .bss
    num_jugadores     resd 1
    posiciones        resd 5
    movimientos       resd 5
    buffer_enter      resb 4
    jugador_actual    resd 1
    tick_semilla      resd 1
    flag_reiniciar    resd 1
    tablero           resb 100
    indice_ganador    resd 1

; Rutina: dibuja el tablero en pantalla
section .text
    global main

dibujar_tablero:
    push esi
    push edi
    push eax
    push ecx
    push edx

    xor esi, esi
fila_loop:
    cmp esi, 10
    jge dibujar_terminado

    xor edi, edi
columna_loop:
    cmp edi, 10
    jge salto_linea

    mov eax, esi
    imul eax, 10
    add eax, edi
    mov al, [tablero + eax]
    cmp al, 0
    jne imprimir_caracter
    mov al, '.'
imprimir_caracter:
    movzx eax, al
    push eax
    push fmt_char
    call printf
    add esp, 8
    inc edi
    jmp columna_loop

salto_linea:
    push nueva_linea
    call printf
    add esp, 4
    inc esi
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
    cmp al, 'A'
    je poner_cero
    cmp al, 'B'
    je poner_cero
    cmp al, 'C'
    je poner_cero
    cmp al, 'D'
    je poner_cero
    cmp al, 'E'
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
    movzx eax, byte [escaleras_inicio_db + esi]
    mov [tablero + eax], '^'
    movzx eax, byte [escaleras_fin_db + esi]
    mov [tablero + eax], 'U'
    inc esi
    loop marcar_escaleras

    mov ecx, 3
    xor esi, esi
marcar_serpientes:
    movzx eax, byte [serpientes_inicio_db + esi]
    mov [tablero + eax], 'S'
    movzx eax, byte [serpientes_fin_db + esi]
    mov [tablero + eax], 'D'
    inc esi
    loop marcar_serpientes

    push mensaje_inicio
    call printf
    add esp, 4

    push mensaje_pedir_jug
    call printf
    add esp, 4

    push num_jugadores
    push formato_entero
    call scanf
    add esp, 8

    mov eax, [num_jugadores]
    cmp eax, 2
    jl fin_partida
    cmp eax, 5
    jg fin_partida

    xor ecx, ecx
inicializar_jugadores:
    mov dword [posiciones + ecx*4], 0
    mov dword [movimientos + ecx*4], 0
    inc ecx
    mov eax, [num_jugadores]
    cmp ecx, eax
    jl inicializar_jugadores

    mov dword [jugador_actual], 0
    mov dword [tick_semilla], 0

; Ciclo principal del juego
ciclo_partida:
    call limpiar_marcas_jugadores
    mov ecx, [num_jugadores]
    xor esi, esi
colocar_jugadores:
    mov eax, [posiciones + esi*4]
    movzx edx, byte [simbolos_jugadores + esi]
    mov [tablero + eax], dl
    inc esi
    cmp esi, ecx
    jl colocar_jugadores

    call dibujar_tablero

    mov ecx, [jugador_actual]
    mov eax, ecx
    inc eax
    push eax
    push mensaje_turno
    call printf
    add esp, 8

    lea eax, [buffer_enter]
    push eax
    push formato_enter
    call scanf
    add esp, 8

    mov eax, [tick_semilla]
    inc eax
    mov [tick_semilla], eax

    push 0
    call time
    add esp, 4
    mov ebx, eax
    mov eax, [tick_semilla]
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
    push mensaje_dado
    call printf
    add esp, 8

    mov ecx, [jugador_actual]
    mov eax, [posiciones + ecx*4]
    add eax, ebx
    cmp eax, 99
    jle sin_ganar_directo
    mov dword [posiciones + ecx*4], 99
    mov eax, [jugador_actual]
    mov [indice_ganador], eax
    jmp anunciar_ganador

sin_ganar_directo:
    mov dword [posiciones + ecx*4], eax

    xor esi, esi
ver_escalones:
    cmp esi, 3
    jge ver_serpientes
    mov eax, [posiciones + ecx*4]
    cmp eax, dword [escaler as_origen_dd + esi*4] ; ajustar si su ensamblador requiere nombre exacto
    jne siguiente_escalon
    mov eax, dword [escaler as_destino_dd + esi*4]
    mov [posiciones + ecx*4], eax
    mov edx, [escaler as_origen_dd + esi*4]
    push eax
    push edx
    push mensaje_escalon
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
    mov eax, [posiciones + ecx*4]
    cmp eax, dword [serpientes_origen_dd + esi*4]
    jne siguiente_serpiente
    mov eax, dword [serpientes_destino_dd + esi*4]
    mov [posiciones + ecx*4], eax
    mov edx, [serpientes_origen_dd + esi*4]
    push eax
    push edx
    push mensaje_serpiente
    call printf
    add esp, 12
    jmp despues_eventos
siguiente_serpiente:
    inc esi
    jmp loop_serpientes

despues_eventos:
    mov eax, [movimientos + ecx*4]
    inc eax
    mov [movimientos + ecx*4], eax

    mov eax, [posiciones + ecx*4]
    mov edx, [jugador_actual]
    inc edx
    push eax
    push edx
    push mensaje_posicion
    call printf
    add esp, 12

    mov eax, [movimientos + ecx*4]
    mov edx, [jugador_actual]
    inc edx
    push eax
    push edx
    push mensaje_movimientos
    call printf
    add esp, 12

    mov eax, [posiciones + ecx*4]
    cmp eax, 99
    jne avanzar_turno

    mov eax, [jugador_actual]
    mov [indice_ganador], eax
    jmp anunciar_ganador

avanzar_turno:
    mov eax, [jugador_actual]
    inc eax
    mov ecx, [num_jugadores]
    cmp eax, ecx
    jl guardar_turno
    xor eax, eax
guardar_turno:
    mov [jugador_actual], eax
    jmp ciclo_partida

; Mostrar resultados y preguntar reinicio
anunciar_ganador:
    call limpiar_marcas_jugadores
    mov ecx, [num_jugadores]
    xor esi, esi
colocar_final:
    mov eax, [posiciones + esi*4]
    movzx edx, byte [simbolos_jugadores + esi]
    mov [tablero + eax], dl
    inc esi
    cmp esi, ecx
    jl colocar_final

    call dibujar_tablero

    mov eax, [indice_ganador]
    inc eax
    mov ebx, [indice_ganador]
    mov ebx, [movimientos + ebx*4]
    push ebx
    push eax
    push mensaje_campeon
    call printf
    add esp, 12

    push mensaje_finales
    call printf
    add esp, 4

    xor esi, esi
    mov ebx, [indice_ganador]
lista_finales:
    mov eax, esi
    cmp eax, [num_jugadores]
    jge preguntar_reiniciar
    cmp esi, ebx
    je omitir_ganador
    mov edx, [posiciones + esi*4]
    mov eax, esi
    inc eax
    push edx
    push eax
    push mensaje_rival
    call printf
    add esp, 12
omitir_ganador:
    inc esi
    jmp lista_finales

preguntar_reiniciar:
    push mensaje_reiniciar
    call printf
    add esp, 4
    push flag_reiniciar
    push formato_entero
    call scanf
    add esp, 8
    mov eax, [flag_reiniciar]
    cmp eax, 1
    je inicio_partida

fin_partida:
    mov esp, ebp
    pop ebp
    ret
