extern printf    ; imprime texto formateado
extern scanf     ; lee entrada formateada
extern rand      ; genera numero aleatorio
extern srand     ; inicializa semilla del rng
extern time      ; obtiene tiempo (segundos)

section .data
    msg_inicio         db "serpientes y escaleras plus", 10, 0
    msg_pedir_jug      db "ingrese numero de jugadores (1-3): ", 0
    msg_turno          db "jugador %d, presione enter para tirar el dado (Enter = tirar, 0+Enter = reiniciar):", 10, 0
    msg_dado           db "valor del dado: %d", 10, 0
    msg_posicion       db "jugador %d movido a casilla %d", 10, 0
    msg_escalera       db "escalera: sube de %d a %d", 10, 0
    msg_serpiente      db "serpiente: baja de %d a %d", 10, 0
    msg_movimientos    db "movimientos jugador %d: %d", 10, 0
    msg_ganador        db "campeon jugador %d en %d movimientos", 10, 0
    msg_finales        db "estado final de los jugadores:", 10, 0
    msg_rival          db "rival %d quedo en casilla %d", 10, 0
    msg_restarted      db "partida reiniciada", 10, 0
    msg_salir          db "desea salir o volver al menu? (0=salir,1=menu): ", 0

    fmt_entero         db "%d", 0
    fmt_char           db "%c", 0
    fmt_str            db "%15s", 0
    fmt_char2          db "%c%c ", 0
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

    escaleras_ini_dd   dd 0, 0, 0
    escaleras_fin_dd   dd 0, 0, 0
    serpientes_ini_dd  dd 0, 0, 0
    serpientes_fin_dd  dd 0, 0, 0

section .bss
    jug_total          resd 1
    jug_posiciones     resd 3
    jug_movimientos    resd 3
    turno_actual       resd 1
    semilla_tick       resd 1
    bandera_reinicio   resd 1
    token_buf          resb 16
    input_char         resb 1
    tmp_char           resb 1
    tablero            resb 100
    tablero_jugadores  resb 100
    ganador_indice     resd 1
    columnas_usadas    resb 10
    gen_counter        resd 1

section .text
    global main

; generar_especiales: genera 3 escaleras y 3 serpientes evitando solapamientos
generar_especiales:
    pushad

    mov eax, [gen_counter]    ; eax: uso general para resultados/valores temporales
    test eax, eax
    jnz gen_ok
    mov dword [gen_counter], 1
; gen_ok: marca que gen_counter ya fue inicializado
gen_ok:

    mov ecx, 10               ; ecx: contador/registro de bucle
    xor edi, edi              ; edi: indice/registro auxiliar
; limpiar_columnas: limpia arreglo columnas_usadas
limpiar_columnas:
    mov byte [columnas_usadas + edi], 0
    inc edi
    loop limpiar_columnas

    xor esi, esi              ; esi: indice/registro auxiliar para bucles
; escalera_bucle: genera 3 escaleras
escalera_bucle:
    cmp esi, 3
    jge serpiente_inicio

; escalera_intentar: intenta generar una escalera valida
escalera_intentar:
    mov eax, [gen_counter]
    inc eax
    mov [gen_counter], eax

    call rand
    xor edx, edx              ; edx: usado para restos/divisiones
    mov ecx, 89
    div ecx
    mov ebx, edx              ; ebx: registro temporal para valores
    inc ebx                   ; ebx = inicio escalera (1..89)
    mov eax, ebx
    add eax, 10               ; eax = final escalera (11..99)

; ver_dup_escaleras: comprueba duplicados con escaleras previas
ver_dup_escaleras:
    cmp edi, esi
    jge guardar_escalera
    mov edx, dword [escaleras_ini_dd + edi*4]
    cmp edx, ebx
    je escalera_intentar
    mov edx, dword [escaleras_fin_dd + edi*4]
    cmp edx, eax
    je escalera_intentar
    inc edi
    jmp ver_dup_escaleras

; guardar_escalera: guarda la escalera generada
guardar_escalera:
    mov dword [escaleras_ini_dd + esi*4], ebx
    mov dword [escaleras_fin_dd + esi*4], eax
    inc esi
    jmp escalera_bucle

; serpiente_inicio: inicia generacion de serpientes
serpiente_inicio:
    xor esi, esi

; serpiente_bucle: genera 3 serpientes
serpiente_bucle:
    cmp esi, 3
    jge generacion_terminada

; serpiente_intentar: intenta generar una serpiente valida
serpiente_intentar:
    mov eax, [gen_counter]
    inc eax
    mov [gen_counter], eax

    call rand
    xor edx, edx
    mov ecx, 89
    div ecx
    mov ebx, edx
    add ebx, 11            ; ebx = cabeza (11..99)
    mov eax, ebx
    sub eax, 10            ; eax = cola (1..89)

; ver_dup_serpientes: verifica duplicados con serpientes previas
ver_dup_serpientes:
    cmp edi, esi
    jge ver_conf_escaleras
    mov edx, dword [serpientes_ini_dd + edi*4]
    cmp edx, ebx
    je serpiente_intentar
    mov edx, dword [serpientes_fin_dd + edi*4]
    cmp edx, eax
    je serpiente_intentar
    inc edi
    jmp ver_dup_serpientes

; ver_conf_escaleras: verifica conflicto exacto con escaleras
ver_conf_escaleras:
    xor edi, edi
ver_bucle_escalera:
    cmp edi, 3
    jge guardar_serpiente
    mov edx, dword [escaleras_ini_dd + edi*4]
    cmp edx, ebx
    je serpiente_intentar
    mov edx, dword [escaleras_fin_dd + edi*4]
    cmp edx, ebx
    je serpiente_intentar
    mov edx, dword [escaleras_ini_dd + edi*4]
    cmp edx, eax
    je serpiente_intentar
    mov edx, dword [escaleras_fin_dd + edi*4]
    cmp edx, eax
    je serpiente_intentar
    inc edi
    jmp ver_bucle_escalera

; guardar_serpiente: guarda la serpiente generada
guardar_serpiente:
    mov dword [serpientes_ini_dd + esi*4], ebx
    mov dword [serpientes_fin_dd + esi*4], eax
    inc esi
    jmp serpiente_bucle

; generacion_terminada: fin rutina generar_especiales
generacion_terminada:
    popad
    ret

; dibujar_tablero: dibuja el tablero en pantalla
dibujar_tablero:
    push esi
    push edi
    push eax
    push ecx
    push edx
    push ebx
    mov esi, 9

; fila_loop: bucle de filas, controla direccion segun fila
fila_loop:
    cmp esi, 0
    jl dibujar_terminado
    mov ecx, esi
    and ecx, 1
    cmp ecx, 0
    je izquierda_a_derecha

; derecha_a_izquierda: columna derecha->izquierda
derecha_a_izquierda:
    mov edi, 9

; columna_loop_derecha: bucle columnas derecha a izquierda
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

; tile_ok_d: imprime celda cuando se itera derecha->izquierda
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

; izquierda_a_derecha: columna izquierda->derecha
izquierda_a_derecha:
    mov edi, 0

; columna_loop_izquierda: bucle columnas izquierda a derecha
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

; tile_ok_i: imprime celda cuando se itera izquierda->derecha
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

; salto_linea: imprime salto de linea al terminar fila
salto_linea:
    push salto_linea_texto
    call printf
    add esp, 4
    dec esi
    jmp fila_loop

; dibujar_terminado: termina rutina de dibujo
dibujar_terminado:
    pop ebx
    pop edx
    pop ecx
    pop eax
    pop edi
    pop esi
    ret

; limpiar_marcas_jugadores: limpia la capa de marcadores de jugadores
limpiar_marcas_jugadores:
    push esi
    push ecx
    mov ecx, 100
    xor esi, esi

; limpieza_loop: bucle para limpiar cada posicion de marcador
limpieza_loop:
    mov byte [tablero_jugadores + esi], '.'
    inc esi
    loop limpieza_loop
    pop ecx
    pop esi
    ret

; colocar_jugadores: coloca los simbolos de los jugadores en la capa de jugadores
colocar_jugadores:
    push esi
    push edi
    push eax
    push ebx
    push ecx
    push edx
    mov ecx, [jug_total]
    xor esi, esi

; colocar_loop: bucle para cada jugador
colocar_loop:
    cmp esi, ecx
    jge colocar_fin
    mov eax, [jug_posiciones + esi*4]
    mov bl, [simbolos_jug + esi]
    mov dl, [tablero_jugadores + eax]
    cmp dl, '.'
    je colocar_simple
    cmp dl, bl
    je colocar_skip
    cmp dl, 'a'
    je marcador_actual_a
    cmp dl, 'b'
    je marcador_actual_b
    cmp dl, 'c'
    je marcador_actual_c
    cmp dl, '4'
    je marcador_4
    cmp dl, '5'
    je marcador_5
    cmp dl, '6'
    je marcador_6
    cmp dl, '7'
    je colocar_skip

; marcador_actual_a: resuelve combinaciones cuando ya hay marcador 'a'
marcador_actual_a:
    cmp bl, 'b'
    je asignar_4
    cmp bl, 'c'
    je asignar_6
    jmp colocar_skip

; marcador_actual_b: resuelve combinaciones cuando ya hay marcador 'b'
marcador_actual_b:
    cmp bl, 'a'
    je asignar_4
    cmp bl, 'c'
    je asignar_5
    jmp colocar_skip

; marcador_actual_c: resuelve combinaciones cuando ya hay marcador 'c'
marcador_actual_c:
    cmp bl, 'a'
    je asignar_6
    cmp bl, 'b'
    je asignar_5
    jmp colocar_skip

; marcador_4: resuelve combinaciones cuando ya hay marcador '4'
marcador_4:
    cmp bl, 'c'
    je asignar_7
    jmp colocar_skip

; marcador_5: resuelve combinaciones cuando ya hay marcador '5'
marcador_5:
    cmp bl, 'a'
    je asignar_7
    jmp colocar_skip

; marcador_6: resuelve combinaciones cuando ya hay marcador '6'
marcador_6:
    cmp bl, 'b'
    je asignar_7
    jmp colocar_skip

; asignar_4: asigna simbolo combinado 4
asignar_4:
    mov byte [tablero_jugadores + eax], '4'
    jmp siguiente_jugador

; asignar_5: asigna simbolo combinado 5
asignar_5:
    mov byte [tablero_jugadores + eax], '5'
    jmp siguiente_jugador

; asignar_6: asigna simbolo combinado 6
asignar_6:
    mov byte [tablero_jugadores + eax], '6'
    jmp siguiente_jugador

; asignar_7: asigna simbolo combinado 7
asignar_7:
    mov byte [tablero_jugadores + eax], '7'
    jmp siguiente_jugador

; colocar_simple: coloca marcador simple
colocar_simple:
    mov byte [tablero_jugadores + eax], bl
    jmp siguiente_jugador

; colocar_skip: salta posicion sin cambios
colocar_skip:
    jmp siguiente_jugador

; siguiente_jugador: avanza al siguiente jugador
siguiente_jugador:
    inc esi
    jmp colocar_loop

; colocar_fin: fin colocar jugadores
colocar_fin:
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop edi
    pop esi
    ret

; sin_ganar_directo: asigna posicion cuando movimiento no supera 99
sin_ganar_directo:
    mov dword [jug_posiciones + ecx*4], eax
    xor esi, esi

; ver_escalones: verifica si jugador cae en una escalera
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

; siguiente_escalon: siguiente escalera
siguiente_escalon:
    inc esi
    jmp ver_escalones

; ver_serpientes: verifica si jugador cae en una serpiente
ver_serpientes:
    xor esi, esi

; loop_serpientes: bucle verificacion serpientes
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

; siguiente_serpiente: siguiente serpiente
siguiente_serpiente:
    inc esi
    jmp loop_serpientes

; despues_eventos: despues de aplicar eventos en casilla
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

; avanzar_turno: avanza el turno al siguiente jugador
avanzar_turno:
    mov eax, [turno_actual]
    inc eax
    mov ecx, [jug_total]
    cmp eax, ecx
    jl guardar_turno
    xor eax, eax

; guardar_turno: guarda el turno calculado
guardar_turno:
    mov [turno_actual], eax
    jmp ciclo_partida

; anunciar_ganador: anuncia el ganador y muestra estado final
anunciar_ganador:
    call limpiar_marcas_jugadores
    mov ecx, [jug_total]
    xor esi, esi

; colocar_final: coloca marcadores finales en tablero
colocar_final:
    mov eax, [jug_posiciones + esi*4]
    movzx edx, byte [simbolos_jug + esi]
    mov byte [tablero + eax], dl
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
    ; despues de mostrar finales, preguntar al usuario si desea salir o volver al menu
    ; en lugar de terminar automaticamente
    jmp preguntar_salir

; lista_finales: lista de finales para cada rival excepto ganador
lista_finales:
    mov eax, esi
    cmp eax, [jug_total]
    jge preguntar_salir
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

; omitir_ganador: omitir el ganador en la lista
omitir_ganador:
    inc esi
    jmp lista_finales

; preguntar_salir: pedir al usuario 0=salir 1=menu, bucle hasta entrada valida
preguntar_salir:
    push msg_salir
    call printf
    add esp, 4

leer_opcion_final:
    ; leer token como string con scanf("%15s", token_buf)
    push token_buf
    push fmt_str
    call scanf
    add esp, 8

    mov al, [token_buf]      ; primer caracter
    mov bl, [token_buf + 1]  ; comprobar que no hay mas caracteres
    cmp bl, 0
    jne leer_opcion_final
    cmp al, '0'
    je opcion_salir
    cmp al, '1'
    je opcion_menu
    jmp leer_opcion_final

opcion_salir:
    jmp fin_partida

opcion_menu:
    jmp inicio_partida

; fin_partida: fin del programa
fin_partida:
    mov eax, 0
    leave
    ret

; main / inicio_partida
main:
inicio_partida:
    push ebp
    mov ebp, esp

    ; seed unico para RNG (usar srand una vez al inicio)
    push 0
    call time
    add esp, 4
    push eax
    call srand
    add esp, 4

    ; copiar tablero_base -> tablero
    mov ecx, 100
    xor esi, esi
copia_tablero:
    mov al, [tablero_base + esi]
    mov [tablero + esi], al
    inc esi
    loop copia_tablero

    call generar_especiales

    ; marcar especiales en el tablero
    mov ecx, 3
    xor esi, esi
marcar_escaleras:
    mov eax, [escaleras_ini_dd + esi*4]
    mov byte [tablero + eax], 'I'
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

; pedir_jugadores: validar menu inicial (1..3)
pedir_jugadores:
    push msg_pedir_jug
    call printf
    add esp, 4

    ; leer token como string con scanf("%15s", token_buf)
    push token_buf
    push fmt_str
    call scanf
    add esp, 8

    ; comprobar que el token es exactamente "1", "2" o "3"
    mov al, [token_buf]      ; primer caracter
    cmp al, '1'
    je es1
    cmp al, '2'
    je es2
    cmp al, '3'
    je es3
    jmp pedir_jugadores

es1:
    mov bl, [token_buf + 1]
    cmp bl, 0
    jne pedir_jugadores
    mov eax, 1
    mov [jug_total], eax
    jmp menu_listo

es2:
    mov bl, [token_buf + 1]
    cmp bl, 0
    jne pedir_jugadores
    mov eax, 2
    mov [jug_total], eax
    jmp menu_listo

es3:
    mov bl, [token_buf + 1]
    cmp bl, 0
    jne pedir_jugadores
    mov eax, 3
    mov [jug_total], eax
    jmp menu_listo

; menu_listo: inicializa estructuras de jugadores
menu_listo:
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

    ; consumir la nueva linea sobrante de la entrada del menu (hay una newline tras scanf %s)
    push tmp_char
    push fmt_char
    call scanf
    add esp, 8

    ; exigir otro enter para iniciar el juego
esperar_enter:
    push tmp_char
    push fmt_char
    call scanf
    add esp, 8
    mov al, [tmp_char]
    cmp al, 10
    jne esperar_enter

; ciclo_partida: bucle principal del juego
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

    ; lectura por caracter: scanf("%c", input_char)
    ; depende si el jugaador pone enter solo o con 0
    push input_char
    push fmt_char
    call scanf
    add esp, 8

    mov al, [input_char]
    cmp al, 10             ; newline
    je continuar_juego
    cmp al, '0'
    je reiniciar_partida

    ; descartar hasta newline
descartar_hasta_nl:
    push tmp_char
    push fmt_char
    call scanf
    add esp, 8
    mov bl, [tmp_char]
    cmp bl, 10
    jne descartar_hasta_nl

    jmp continuar_juego

; continuar_juego: generar tirada y aplicar movimiento
continuar_juego:
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

; reiniciar_partida: reinicio por presionar '0' + Enter
reiniciar_partida:
    mov ecx, [jug_total]
    xor esi, esi
reset_players_loop:
    cmp esi, ecx
    jge copiar_tablero_restart
    mov dword [jug_posiciones + esi*4], 0
    mov dword [jug_movimientos + esi*4], 0
    inc esi
    jmp reset_players_loop

copiar_tablero_restart:
    mov ecx, 100
    xor esi, esi
copy_tablero_loop:
    mov al, [tablero_base + esi]
    mov [tablero + esi], al
    inc esi
    dec ecx
    jnz copy_tablero_loop

    mov ecx, 100
    xor esi, esi
clear_tablero_jug:
    mov byte [tablero_jugadores + esi], '.'
    inc esi
    dec ecx
    jnz clear_tablero_jug

    call generar_especiales

    mov ecx, 3
    xor esi, esi
marcar_escaleras_restart:
    mov eax, [escaleras_ini_dd + esi*4]
    mov byte [tablero + eax], 'I'
    mov eax, [escaleras_fin_dd + esi*4]
    mov byte [tablero + eax], 'U'
    inc esi
    loop marcar_escaleras_restart

    mov ecx, 3
    xor esi, esi
marcar_serpientes_restart:
    mov eax, [serpientes_ini_dd + esi*4]
    mov byte [tablero + eax], 'S'
    mov eax, [serpientes_fin_dd + esi*4]
    mov byte [tablero + eax], 'D'
    inc esi
    loop marcar_serpientes_restart

    push msg_restarted
    call printf
    add esp, 4

    mov dword [turno_actual], 0
    mov dword [semilla_tick], 0
    jmp ciclo_partida
