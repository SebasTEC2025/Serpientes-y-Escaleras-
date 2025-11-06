<img width="424" height="457" alt="snake-and-laddersd" src="https://github.com/user-attachments/assets/4b978aa8-a74c-4a24-8d0e-c9a3d6adfe16" />

# Serpientes Vivas y Escaleras

## Problema:

Desarrollar una simulación del juego **Serpientes Vivas y Escaleras** utilizando lenguaje ensamblador, en la que un jugador avance sobre un tablero de 100 casillas lanzando un dado, con alguna animación especial al caer en casillas de serpientes o escaleras.

## Simbolos usados en el tablero:
'.' — casilla vacia (por defecto).
'I' — inicio de escalera (casilla que al caer sube).
'U' — fin de escalera (destino de subida).
'S' — cabeza de serpiente (cae aqui -> baja).
'D' — cola de serpiente (destino de bajar).
'a','b','c' — marcadores para jugador 1 2 y 3 respectivamente.
'4','5','6','7' — simbolos combinados para mostrar multiples jugadores en una casilla.

## Integrantes:
- Demian Wing Ugalde          | Carné: 2025106546
- Sebastián Sánchez Álvarez  | Carné: 2025108378
- Gerald Vindas              | Carné: 2024207572

## Retos Afrontados 

**Visualización**: Mostrar el tablero durante las partidas de forma que siempre sea visible para el jugador.

**Posiciones especiales**: Marcar correctamente dónde se ubican las serpientes, escaleras y jugadores, considerando también los casos en los que se comparten casillas.

**Aleatoriedad**: Generar nuevas posiciones para los elementos del juego, garantizando que cada partida sea única.

**Adaptación al lenguaje**: Comprender el funcionamiento de cada instrucción y de las distintas secciones del código (.text, .bss, etc.), además de integrar librerías del sistema para complementar el trabajo.

**Retroalimentación al usuario**: Producir mensajes claros y concretos cuando el usuario ingrese información errónea o cuando se necesite que el jugador ingrese algún dato.

## Conclusiones 

El desarrollo de Serpientes Vivas y Escaleras en lenguaje ensamblador permitió comprender en detalle cómo manejar la memoria, los registros y el flujo de control a bajo nivel.
Se logró simular un juego completo sobre un tablero de 100 casillas, incorporando generación aleatoria y validación de posiciones.
El proyecto demuestra que, incluso con recursos limitados y sin estructuras de alto nivel, es posible implementar una lógica compleja si se planifica adecuadamente el uso de registros, bucles y secciones de datos.
En conjunto, este trabajo reforzó conceptos fundamentales de programación estructurada y control de flujo, aplicados a un entorno interactivo y visual.
