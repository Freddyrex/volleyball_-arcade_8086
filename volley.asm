STACK SEGMENT PARA STACK
    DB 64 DUP (' ')
STACK ENDS

DATA SEGMENT PARA 'DATA'
    
    WINDOW_WIDTH DW 140h                 ; el ancho de la ventana (320 píxeles)
    WINDOW_HEIGHT DW 0C8h                ; la altura de la ventana (200 píxeles)
    WINDOW_BOUNDS DW 6                   ; variable utilizada para verificar colisiones tempranas
    
    TIME_AUX DB 0                        ; variable utilizada para comprobar si el tiempo ha cambiado
    GAME_ACTIVE DB 1                     ; ¿el juego está activo? (1 → sí, 0 → no [juego terminado])
    EXITING_GAME DB 0
    WINNER_INDEX DB 0                    ; el índice del ganador (1 → jugador uno, 2 → jugador dos)
    CURRENT_SCENE DB 0                   ; el índice de la escena actual (0 → menú principal, 1 → juego)
    
    TEXT_PLAYER_ONE_POINTS DB '0','$'    ; texto con los puntos del jugador uno
    TEXT_PLAYER_TWO_POINTS DB '0','$'    ; texto con los puntos del jugador dos
    TEXT_GAME_OVER_TITLE DB 'GAME OVER','$' ; texto con el título del menú de fin de juego
    TEXT_GAME_OVER_WINNER DB 'Player 0 won','$' ; texto con el ganador
    TEXT_GAME_OVER_PLAY_AGAIN DB 'Press R to play again','$' ; texto: presiona R para jugar de nuevo
    TEXT_GAME_OVER_MAIN_MENU DB 'Press E to exit to main menu','$' ; texto: presiona E para salir al menú principal
    TEXT_MAIN_MENU_TITLE DB 'VOLLEY GAME','$' ; texto con el título del menú principal
    TEXT_MAIN_MENU_CREDIT DB 'Yachay Tech','$'
    TEXT_MAIN_MENU_PLAY DB 'PLAY - P KEY','$' ; texto: JUGAR – TECLA P
    TEXT_MAIN_MENU_EXIT DB 'EXIT GAME - E KEY','$' ; texto: SALIR DEL JUEGO – TECLA E

;code by freddy


    PELOTA_ORIGINAL_X DW 0A0h              ; posición X de la pelota al inicio del juego
    PELOTA_ORIGINAL_Y DW 64h               ; posición Y de la pelota al inicio del juego
    PELOTA_X DW 0A0h                       ; posición X actual (columna) de la pelota
    PELOTA_Y DW 64h                        ; posición Y actual (fila) de la pelota
    PELOTA_SIZE DW 06h                     ; tamaño de la pelota (cantidad de píxeles en ancho y alto)
    PELOTA_VELOCITY_X DW 05h               ; velocidad horizontal (X) de la pelota
    PELOTA_VELOCITY_Y DW 02h               ; velocidad vertical (Y) de la pelota
    
    PADDLE_LEFT_X DW 50h                 ; posición X actual de la paleta izquierda
    PADDLE_LEFT_Y DW 0a0h                 ; posición Y actual de la paleta izquierda
    PLAYER_ONE_POINTS DB 0              ; puntos actuales del jugador uno
    
    PADDLE_RIGHT_X DW 0c0h               ; posición X actual de la paleta derecha
    PADDLE_RIGHT_Y DW 0a0h               ; posición Y actual de la paleta derecha
    PLAYER_TWO_POINTS DB 0             ; puntos actuales del jugador dos
    
    PADDLE_WIDTH DW 25h                  ; ancho predeterminado de la paleta
    PADDLE_HEIGHT DW 06h                 ; alto predeterminado de la paleta
    PADDLE_VELOCITY DW 0Fh               ; velocidad predeterminada de la paleta
    
    ; variables del piso 
    FLOOR_WIDTH_HALF DW 0A0h       ; 160 píxeles
    FLOOR_HEIGHT     DW 14h        ; 20 píxeles
    FLOOR_Y          DW 0B4h       ; 180 píxeles
    FLOOR_LEFT_X     DW 00h        ; centro – mitad izquierda
    FLOOR_RIGHT_X    DW 0A0h       ; centro – mitad derecha

    ; Variables de la red 
    RED_X DW 0A0h              ; centro horizontal de la red
    RED_Y DW 07Ah              ; posición Y donde empieza la red (cerca del fondo)
    RED_WIDTH DW 08h           ; cantidad de píxeles que se extiende horizontalmente la red
    RED_HEIGHT DW 50h          ; altura de la red (~48 píxeles)
    ; limitador de colisiones con la red
    PELOTA_HIT_NET DB 0        ; 0 = no ha chocado con la red, 1 = sí ha chocado con la red
    
DATA ENDS

CODE SEGMENT PARA 'CODE'

    MAIN PROC FAR
    ASSUME CS:CODE,DS:DATA,SS:STACK      ; asumir que CS, DS y SS corresponden a los segmentos de código, datos y pila
    PUSH DS                              ; guardar el segmento DS en la pila
    SUB AX,AX                            ; limpiar el registro AX
    PUSH AX                              ; guardar AX en la pila
    MOV AX,DATA                          ; cargar en AX la dirección del segmento DATA
    MOV DS,AX                            ; asignar DS al valor de AX
    POP AX                               ; recuperar el valor de AX desde la pila
    POP AX                               ; recuperar otro valor desde la pila
        
        CALL CLEAR_SCREEN                ; establecer configuraciones iniciales del modo de video
        
    CHECK_TIME:                      ; bucle de verificación del tiempo
            
            CMP EXITING_GAME,01h
            JE START_EXIT_PROCESS
            
            CMP CURRENT_SCENE,00h
            JE SHOW_MAIN_MENU
            
            CMP GAME_ACTIVE,00h
            JE SHOW_GAME_OVER
            
            MOV AH,2Ch 					 ; obtener la hora del sistema
            INT 21h    					 ; CH = hora, CL = minuto, DH = segundo, DL = centésimas de segundo
            
            CMP DL,TIME_AUX  			 ; comparar el tiempo actual con el anterior (TIME_AUX)
            JE CHECK_TIME    		     ; si es igual, volver a verificar
            
            ; Si se alcanza este punto, es porque ha pasado el tiempo
  
            MOV TIME_AUX,DL              ; actualizar el tiempo
            ; eliminamos la llamada a CLEAR_SCREEN en cada ciclo para evitar parpadeos
            ; sin embargo, los objetos con colisiones siempre deben refrescarse
            ; CALL CLEAR_SCREEN            ; limpiar la pantalla reiniciando el modo de video
                
            CALL DRAW_PELOTA_NEGRO   ; borrar la pelota anterior
            CALL MOVE_PELOTA         ; mover la pelota
            CALL DRAW_PELOTA         ; dibujar la nueva pelota

            CALL DRAW_PADDLES_NEGRO   ; borrar las paletas anteriores
            CALL MOVE_PADDLES         ; mover las paletas
            CALL DRAW_PADDLES         ; dibujar las nuevas paletas

            ; llamadas adicionales
            CALL DRAW_FLOORS
            CALL DRAW_NET
            CALL DRAW_UI                 ; dibujar la interfaz de usuario del juego
            JMP CHECK_TIME               ; volver a verificar el tiempo
            
        SHOW_GAME_OVER:
            CALL DRAW_GAME_OVER_MENU
            JMP CHECK_TIME
                
        SHOW_MAIN_MENU:
            CALL DRAW_MAIN_MENU
            JMP CHECK_TIME
                
        START_EXIT_PROCESS:
            CALL CONCLUDE_EXIT_GAME
                
        RET		
    MAIN ENDP

    ; Dibuja un bloque rectangular usando valores en memoria
    ; CX = columna inicial, DX = fila inicial, AL = color
    ; Usa FLOOR_WIDTH_HALF y FLOOR_HEIGHT desde DATA
    ;(LÓGICA DE LOS PISOS)
    DRAW_FLOORS PROC NEAR
    ; Piso izquierdo (rojo) 
    MOV CX, FLOOR_LEFT_X       ; columna inicial = 0
    MOV DX, FLOOR_Y            ; fila inicial = 180
    MOV SI, 0                  ; contador horizontal
; bucle para dibujar la anchura del piso izquierdo
DRAW_FLOOR_LEFT_WIDTH_LOOP:
    MOV DI, 0                  ; contador vertical

DRAW_FLOOR_LEFT_HEIGHT_LOOP:
    MOV AH, 0Ch
    MOV AL, 04h                ; color rojo
    MOV BH, 00h
    INT 10h

    INC DX
    INC DI
    CMP DI, FLOOR_HEIGHT
    JB DRAW_FLOOR_LEFT_HEIGHT_LOOP

    INC SI
    INC CX
    MOV DX, FLOOR_Y
    CMP SI, FLOOR_WIDTH_HALF   ; 160 columnas
    JB DRAW_FLOOR_LEFT_WIDTH_LOOP

    ; === Piso derecho (azul) ===
    MOV CX, FLOOR_RIGHT_X      ; columna inicial = 160
    MOV DX, FLOOR_Y
    MOV SI, 0

DRAW_FLOOR_RIGHT_WIDTH_LOOP:
    MOV DI, 0

DRAW_FLOOR_RIGHT_HEIGHT_LOOP:
    MOV AH, 0Ch
    MOV AL, 01h                ; color azul
    MOV BH, 00h
    INT 10h

    INC DX
    INC DI
    CMP DI, FLOOR_HEIGHT
    JB DRAW_FLOOR_RIGHT_HEIGHT_LOOP

    INC SI
    INC CX
    MOV DX, FLOOR_Y
    CMP SI, FLOOR_WIDTH_HALF
    JB DRAW_FLOOR_RIGHT_WIDTH_LOOP

    RET
    DRAW_FLOORS ENDP

    ; LÓGICA DE LA RED (NET)	
    DRAW_NET PROC NEAR
        MOV SI, 0              ; contador horizontal

DRAW_NET_WIDTH_LOOP:
        ; Calcular columna inicial: RED_X - (RED_WIDTH / 2) + SI
        MOV AX, RED_WIDTH
        SHR AX, 1              ; AX = RED_WIDTH / 2
        MOV BX, RED_X
        SUB BX, AX             ; inicio de la red
        ADD BX, SI             ; columna actual en la red
        MOV CX, BX             ; CX = columna

        MOV DX, RED_Y          ; DX = fila inicial (RED_Y)

DRAW_NET_HEIGHT_LOOP:
        MOV AH, 0Ch
        MOV AL, 07h            ; gris claro
        MOV BH, 00h
        INT 10h

        INC DX
        MOV AX, DX
        SUB AX, RED_Y
        CMP AX, RED_HEIGHT
        JB DRAW_NET_HEIGHT_LOOP

        INC SI
        MOV AX, SI
        CMP AX, RED_WIDTH
        JB DRAW_NET_WIDTH_LOOP

        RET
    DRAW_NET ENDP

    MOVE_PELOTA PROC NEAR                  ; procesa el movimiento de la pelota
        
        ; Mover la pelota horizontalmente
        MOV AX, PELOTA_VELOCITY_X    
        ADD PELOTA_X, AX   
         
        ; Verificar si la pelota ha pasado el límite izquierdo (PELOTA_X < 0 + WINDOW_BOUNDS)
        ; De ser así, reiniciar su posición
        MOV AX, WINDOW_BOUNDS
        CMP PELOTA_X, AX                    ; comparar PELOTA_X con el límite izquierdo (0 + WINDOW_BOUNDS)
        JL HANDLE_POINT_P2                  ; si es menor, saltar a la etiqueta correspondiente
        
        ; Verificar si la pelota ha pasado el límite derecho (PELOTA_X > WINDOW_WIDTH - PELOTA_SIZE - WINDOW_BOUNDS)
        ; De ser así, reiniciar su posición
        MOV AX, WINDOW_WIDTH
        SUB AX, PELOTA_SIZE
        SUB AX, WINDOW_BOUNDS
        CMP PELOTA_X, AX	                ; comparar PELOTA_X con el límite derecho
        JG GIVE_POINT_TO_PLAYER_ONE  		; si es mayor, otorgar un punto al jugador uno y reiniciar la posición
        
        ; Verificar colisión con la red
        ; Condición: (PELOTA_X + PELOTA_SIZE > RED_X - RED_WIDTH/2) y (PELOTA_X < RED_X + RED_WIDTH/2)
        ;            y (PELOTA_Y + PELOTA_SIZE > RED_Y) y (PELOTA_Y < RED_Y + RED_HEIGHT)
        MOV AX, PELOTA_X
        ADD AX, PELOTA_SIZE
        MOV BX, RED_WIDTH
        SHR BX, 1
        MOV CX, RED_X
        SUB CX, BX            ; CX = RED_X - RED_WIDTH/2
        CMP AX, CX
        JLE NO_NET_COLLISION

        MOV AX, PELOTA_X
        MOV BX, RED_WIDTH
        SHR BX, 1
        MOV CX, RED_X
        ADD CX, BX            ; CX = RED_X + RED_WIDTH/2
        CMP AX, CX
        JGE NO_NET_COLLISION

        MOV AX, PELOTA_Y
        ADD AX, PELOTA_SIZE
        CMP AX, RED_Y
        JLE NO_NET_COLLISION

        MOV AX, PELOTA_Y
        MOV CX, RED_Y
        ADD CX, RED_HEIGHT
        CMP AX, CX
        JGE NO_NET_COLLISION

        ; Si se llega hasta aquí, hay colisión con la red → invertir la dirección en X
        ; Si ya había colisionado previamente, no realizar acción
        CMP PELOTA_HIT_NET, 1
        JE MOVE_PELOTA_VERTICALLY

        ; Si no había colisionado, marcar colisión y se ajustar velocidades
        MOV PELOTA_HIT_NET, 1
        CALL NEG_VELOCITY_XYN
        JMP MOVE_PELOTA_VERTICALLY

    HANDLE_POINT_P2:
        CALL GIVE_POINT_TO_PLAYER_TWO
        RET

    NO_NET_COLLISION:
        MOV PELOTA_HIT_NET, 0         ; ya no está colisionando con la red
        JMP MOVE_PELOTA_VERTICALLY
        
    GIVE_POINT_TO_PLAYER_ONE:		 ; otorgar un punto al jugador uno y reiniciar la posición de la pelota
        INC PLAYER_ONE_POINTS         ; incrementar puntos del jugador uno
        CALL RESET_PELOTA_POSITION    ; reiniciar la posición de la pelota al centro de la pantalla
        CALL UPDATE_TEXT_PLAYER_ONE_POINTS  ; actualizar el texto de los puntos del jugador uno
        CMP PLAYER_ONE_POINTS,05h      ; verificar si el jugador alcanza 5 puntos
        JGE GAME_OVER                 ; si tiene 5 o más puntos, finalizar el juego
        RET
        
    GIVE_POINT_TO_PLAYER_TWO:        ; otorgar un punto al jugador dos y reiniciar la posición de la pelota
        INC PLAYER_TWO_POINTS         ; incrementar puntos del jugador dos
        CALL RESET_PELOTA_POSITION    ; reiniciar la posición de la pelota al centro de la pantalla
        CALL UPDATE_TEXT_PLAYER_TWO_POINTS  ; actualizar el texto de los puntos del jugador dos
        CMP PLAYER_TWO_POINTS,05h      ; verificar si el jugador alcanza 5 puntos
        JGE GAME_OVER                 ; si tiene 5 o más puntos, finalizar el juego
        RET
            
    GAME_OVER:                       ; algún jugador ha alcanzado 5 puntos
        CMP PLAYER_ONE_POINTS,05h      ; verificar cuál jugador tiene 5 o más puntos
        JNL WINNER_IS_PLAYER_ONE      ; si el jugador uno tiene 5 o más, es el ganador
        JMP WINNER_IS_PLAYER_TWO      ; de lo contrario, el jugador dos es el ganador
            
        WINNER_IS_PLAYER_ONE:
            MOV WINNER_INDEX,01h      ; actualizar el índice del ganador al jugador uno
            JMP CONTINUE_GAME_OVER
        WINNER_IS_PLAYER_TWO:
            MOV WINNER_INDEX,02h      ; actualizar el índice del ganador al jugador dos
            JMP CONTINUE_GAME_OVER
                
        CONTINUE_GAME_OVER:
            MOV PLAYER_ONE_POINTS,00h   ; reiniciar los puntos del jugador uno
            MOV PLAYER_TWO_POINTS,00h   ; reiniciar los puntos del jugador dos
            CALL UPDATE_TEXT_PLAYER_ONE_POINTS
            CALL UPDATE_TEXT_PLAYER_TWO_POINTS
            MOV GAME_ACTIVE,00h         ; detener el juego
            RET	

    ; Movimiento vertical de la pelota (aplicando "gravedad")
    MOVE_PELOTA_VERTICALLY:
        ; Intento de aplicar gravedad: incrementar la velocidad vertical cada fotograma
        MOV AX, 01h
        ADD PELOTA_VELOCITY_Y, AX

        ; Actualizar la posición vertical según la velocidad
        MOV AX, PELOTA_VELOCITY_Y
        ADD PELOTA_Y, AX
        ; Comprobar colisión con el piso: si (PELOTA_Y + PELOTA_SIZE) >= FLOOR_Y
        MOV AX, PELOTA_Y
        ADD AX, PELOTA_SIZE
        CMP AX, FLOOR_Y
        JL CONTINUAR_SIN_COLISION_FLOOR

        ; Hubo colisión con el piso: determinar si es del lado derecho o izquierdo
        MOV AX, PELOTA_X
        ADD AX, PELOTA_SIZE
        CMP AX, FLOOR_RIGHT_X      ; FLOOR_RIGHT_X = 160
        JL COLISION_CON_FLOOR_IZQUIERDO ; si está a la izquierda
        ; Sino, está a la derecha
    COLISION_CON_FLOOR_DERECHO:
        JMP DAR_PUNTO_JUGADOR_1

    COLISION_CON_FLOOR_IZQUIERDO:
        JMP DAR_PUNTO_JUGADOR_2

    DAR_PUNTO_JUGADOR_1:
        JMP GIVE_POINT_TO_PLAYER_ONE

    DAR_PUNTO_JUGADOR_2:
        JMP GIVE_POINT_TO_PLAYER_TWO

    CONTINUAR_SIN_COLISION_FLOOR:

        ; Verificar si la pelota ha pasado el límite superior (PELOTA_Y < 0 + WINDOW_BOUNDS)
        MOV AX, WINDOW_BOUNDS
        CMP PELOTA_Y, AX            ; comparar PELOTA_Y con el límite superior
        JL NEG_VELOCITY_Y           ; si es menor, invertir la velocidad vertical

        ; Verificar si la pelota ha pasado el límite inferior (PELOTA_Y > WINDOW_HEIGHT - PELOTA_SIZE - WINDOW_BOUNDS)
        MOV AX, WINDOW_HEIGHT	
        SUB AX, PELOTA_SIZE
        SUB AX, WINDOW_BOUNDS
        CMP PELOTA_Y, AX            ; comparar PELOTA_Y con el límite inferior
        JG NEG_VELOCITY_Y           ; si es mayor, invertir la velocidad vertical
        
        ; LA LÓGICA DE LA COLISIÓN DE LA PELOTA CON LAS PALETAS	
        ; Verificar colisión con la paleta derecha:
        ; (PELOTA_X + PELOTA_SIZE > PADDLE_RIGHT_X) y (PELOTA_X < PADDLE_RIGHT_X + PADDLE_WIDTH)
        ; y (PELOTA_Y + PELOTA_SIZE > PADDLE_RIGHT_Y) y (PELOTA_Y < PADDLE_RIGHT_Y + PADDLE_HEIGHT)
        MOV AX, PELOTA_X
        ADD AX, PELOTA_SIZE
        CMP AX, PADDLE_RIGHT_X
        JNG CHECK_COLLISION_WITH_LEFT_PADDLE   ; si no colisiona, verificar paleta izquierda
        
        MOV AX, PADDLE_RIGHT_X
        ADD AX, PADDLE_WIDTH
        CMP PELOTA_X, AX
        JNL CHECK_COLLISION_WITH_LEFT_PADDLE   ; si no colisiona, verificar paleta izquierda
        
        MOV AX, PELOTA_Y
        ADD AX, PELOTA_SIZE
        CMP AX, PADDLE_RIGHT_Y
        JNG CHECK_COLLISION_WITH_LEFT_PADDLE   ; si no colisiona, verificar paleta izquierda
        
        MOV AX, PADDLE_RIGHT_Y
        ADD AX, PADDLE_HEIGHT
        CMP PELOTA_Y, AX
        JNL CHECK_COLLISION_WITH_LEFT_PADDLE   ; si no colisiona, verificar paleta izquierda
        
        ; Si se llega hasta aquí, la pelota colisiona con la paleta derecha
        JMP NEG_VELOCITY_XY

        ; Verificar colisión con la paleta izquierda:
    CHECK_COLLISION_WITH_LEFT_PADDLE:
        ; (PELOTA_Y + PELOTA_SIZE > PADDLE_LEFT_Y) y (PELOTA_Y < PADDLE_LEFT_Y + PADDLE_HEIGHT)
        ; y (PELOTA_X + PELOTA_SIZE > PADDLE_LEFT_X) y (PELOTA_X < PADDLE_LEFT_X + PADDLE_WIDTH)
        MOV AX, PELOTA_Y
        ADD AX, PELOTA_SIZE
        CMP AX, PADDLE_LEFT_Y
        JNG EXIT_COLLISION_CHECK         ; si no colisiona, salir del chequeo
        
        MOV AX, PADDLE_LEFT_Y
        ADD AX, PADDLE_HEIGHT
        CMP PELOTA_Y, AX
        JNL EXIT_COLLISION_CHECK         ; si no colisiona, salir del chequeo
        
        MOV AX, PELOTA_X
        ADD AX, PELOTA_SIZE
        CMP AX, PADDLE_LEFT_X
        JNG EXIT_COLLISION_CHECK         ; si no colisiona, salir del chequeo
        
        MOV AX, PADDLE_LEFT_X
        ADD AX, PADDLE_WIDTH
        CMP PELOTA_X, AX
        JNL EXIT_COLLISION_CHECK         ; si no colisiona, salir del chequeo
        
        ; Si se llega aquí, la pelota colisiona con la paleta izquierda
        JMP NEG_VELOCITY_XY
        
        NEG_VELOCITY_Y:
            NEG PELOTA_VELOCITY_Y    ; invertir la velocidad vertical de la pelota
            RET
        NEG_VELOCITY_X:
            NEG PELOTA_VELOCITY_X    ; invertir la velocidad horizontal de la pelota
            RET
                    
        EXIT_COLLISION_CHECK:
            RET
        NEG_VELOCITY_XYN:
            ; Invertir la velocidad en X
            NEG PELOTA_VELOCITY_X
            MOV AX, PELOTA_VELOCITY_X
            CMP AX, 0
            JNS CONTINUE_X
                NEG AX
        CONTINUE_X:
            CMP AX, 2               ; evitar que sea 0 o demasiado lento
            JBE SKIP_REDUCE_X
            SUB AX, 1
            CMP PELOTA_VELOCITY_X, 0
            JL NEGATE_BACK_X
            MOV PELOTA_VELOCITY_X, AX
            JMP DONE_X
        NEGATE_BACK_X:
            NEG AX
            MOV PELOTA_VELOCITY_X, AX
        DONE_X:
            ; Invertir la velocidad en Y
            NEG PELOTA_VELOCITY_Y
            MOV AX, PELOTA_VELOCITY_Y
            CMP AX, 0
            JNS CONTINUE_Y
                NEG AX
        CONTINUE_Y:
            CMP AX, 2
            JBE SKIP_REDUCE_Y
            SUB AX, 1
            CMP PELOTA_VELOCITY_Y, 0
            JL NEGATE_BACK_Y
            MOV PELOTA_VELOCITY_Y, AX
            JMP DONE_Y
        NEGATE_BACK_Y:
            NEG AX
            MOV PELOTA_VELOCITY_Y, AX
        DONE_Y:
            RET

        SKIP_REDUCE_X:
        SKIP_REDUCE_Y:
            RET

        ; Lógica de gravedad y rebote en dirección contraria
        NEG_VELOCITY_XY:
            ; Obtener el signo original de X
            MOV AX, PELOTA_VELOCITY_X
            CMP AX, 0
            JGE ORIGINAL_WAS_POSITIVE_X
            MOV BL, 1              ; originalmente era negativo
            JMP GENERATE_X
        ORIGINAL_WAS_POSITIVE_X:
            MOV BL, 0              ; originalmente era positivo
        ; Generador de aleatoriedad
        GENERATE_X:
            ; Generar número aleatorio entre 4 y 6 para X
            MOV AH, 00h
            INT 1Ah
            MOV AX, DX
            AND AX, 0007h
            CMP AX, 02
            JBE RANDOM_X_OK
            MOV AX, 02             ; limitar a 2
        ; Estos bloques hacen que las velocidades en X e Y varíen
        RANDOM_X_OK:
            ADD AX, 4             ; resultado: 4, 5 o 6
            MOV CX, AX            ; guardar el valor absoluto de la nueva velocidad en X

            ; Aplicar dirección contraria
            CMP BL, 0
            JE SET_X_NEGATIVE     ; si originalmente era positivo, ahora se vuelve negativo
            JMP SET_X_POSITIVE    ; si originalmente era negativo, ahora se vuelve positivo

        SET_X_NEGATIVE:
            NEG CX
            MOV PELOTA_VELOCITY_X, CX
            JMP SET_Y

        SET_X_POSITIVE:
            MOV PELOTA_VELOCITY_X, CX

        SET_Y:
            ; Obtener número aleatorio entre 0 y 2 para impulso en Y
            MOV AH, 00h
            INT 1Ah
            MOV AX, DX
            AND AX, 0005h         ; sin movimiento
            CMP AX, 03            ; límite inferior de la velocidad
            JBE RANDOM_Y_OK
            MOV AX, 03
        RANDOM_Y_OK:
            NEG AX                ; invertir
            SUB AX, 12            ; establecer límite de velocidad hacia arriba
            MOV PELOTA_VELOCITY_Y, AX

            RET

    MOVE_PELOTA ENDP
    
    MOVE_PADDLES PROC NEAR               ; procesa el movimiento de las paletas
        
        ; Movimiento de la paleta izquierda
        ; Verificar si se presiona alguna tecla (si no, revisar la paleta derecha)
        MOV AH, 01h
        INT 16h
        JZ CHECK_RIGHT_PADDLE_MOVEMENT   ; si no se presionó tecla, saltar a la verificación de la paleta derecha
        
        ; Determinar la tecla presionada (AL = carácter ASCII)
        MOV AH, 00h
        INT 16h
        
        ; Si es 'a' o 'A', mover hacia arriba
        CMP AL, 61h            ; 'a'
        JE MOVE_LEFT_PADDLE_UP
        CMP AL, 41h            ; 'A'
        JE MOVE_LEFT_PADDLE_UP
        
        ; Si es 'd' o 'D', mover hacia abajo
        CMP AL, 64h            ; 'd'
        JE MOVE_LEFT_PADDLE_DOWN
        CMP AL, 44h            ; 'D'
        JE MOVE_LEFT_PADDLE_DOWN
        JMP CHECK_RIGHT_PADDLE_MOVEMENT
        
    MOVE_LEFT_PADDLE_UP:
        MOV AX, PADDLE_VELOCITY
        SUB PADDLE_LEFT_X, AX
        
        MOV AX, WINDOW_BOUNDS
        CMP PADDLE_LEFT_X, AX
        JL FIX_PADDLE_LEFT_TOP_POSITION
        JMP CHECK_RIGHT_PADDLE_MOVEMENT
        
    FIX_PADDLE_LEFT_TOP_POSITION:
        MOV PADDLE_LEFT_X, AX
        JMP CHECK_RIGHT_PADDLE_MOVEMENT
        
    MOVE_LEFT_PADDLE_DOWN:
        MOV AX, PADDLE_VELOCITY
        ADD PADDLE_LEFT_X, AX

        ; Limitar movimiento por la red
        MOV AX, RED_X
        SUB AX, PADDLE_WIDTH
        CMP PADDLE_LEFT_X, AX
        JG FIX_LEFT_PADDLE_NET
        JMP CONTINUE_LEFT_PADDLE_DOWN

    FIX_LEFT_PADDLE_NET:
        MOV PADDLE_LEFT_X, AX

        CONTINUE_LEFT_PADDLE_DOWN:
            ; Límite por borde derecho
            MOV AX, WINDOW_WIDTH
            SUB AX, WINDOW_BOUNDS
            SUB AX, PADDLE_WIDTH
            CMP PADDLE_LEFT_X, AX
            JG FIX_PADDLE_LEFT_BOTTOM_POSITION
            JMP CHECK_RIGHT_PADDLE_MOVEMENT

            MOV AX, WINDOW_WIDTH
            SUB AX, WINDOW_BOUNDS
            SUB AX, PADDLE_WIDTH
            CMP PADDLE_LEFT_X, AX
            JG FIX_PADDLE_LEFT_BOTTOM_POSITION
            JMP CHECK_RIGHT_PADDLE_MOVEMENT
            
    FIX_PADDLE_LEFT_BOTTOM_POSITION:
        MOV PADDLE_LEFT_X, AX
        JMP CHECK_RIGHT_PADDLE_MOVEMENT
        
        ; Movimiento de la paleta derecha
    CHECK_RIGHT_PADDLE_MOVEMENT:
        ; Si es 'j' o 'J', mover hacia arriba
        CMP AL, 6Ah           ; 'j'
        JE MOVE_RIGHT_PADDLE_UP
        CMP AL, 4Ah           ; 'J'
        JE MOVE_RIGHT_PADDLE_UP
        
        ; Si es 'l' o 'L', mover hacia abajo
        CMP AL, 6Ch           ; 'l'
        JE MOVE_RIGHT_PADDLE_DOWN
        CMP AL, 4Ch           ; 'L'
        JE MOVE_RIGHT_PADDLE_DOWN
        JMP EXIT_PADDLE_MOVEMENT
                
    MOVE_RIGHT_PADDLE_UP:
        MOV AX, PADDLE_VELOCITY
        SUB PADDLE_RIGHT_X, AX

        ; Limitar por la red
        MOV AX, RED_X
        CMP PADDLE_RIGHT_X, AX
        JL FIX_RIGHT_PADDLE_NET
        JMP CONTINUE_RIGHT_PADDLE_UP

    FIX_RIGHT_PADDLE_NET:
        MOV PADDLE_RIGHT_X, AX

        CONTINUE_RIGHT_PADDLE_UP:
            MOV AX, WINDOW_BOUNDS
            CMP PADDLE_RIGHT_X, AX
            JL FIX_PADDLE_RIGHT_TOP_POSITION
            JMP EXIT_PADDLE_MOVEMENT

            MOV AX, WINDOW_BOUNDS
            CMP PADDLE_RIGHT_X, AX
            JL FIX_PADDLE_RIGHT_TOP_POSITION
            JMP EXIT_PADDLE_MOVEMENT
            
    FIX_PADDLE_RIGHT_TOP_POSITION:
        MOV PADDLE_RIGHT_X, AX
        JMP EXIT_PADDLE_MOVEMENT
            
    MOVE_RIGHT_PADDLE_DOWN:
        MOV AX, PADDLE_VELOCITY
        ADD PADDLE_RIGHT_X, AX
        MOV AX, WINDOW_WIDTH
        SUB AX, WINDOW_BOUNDS
        SUB AX, PADDLE_WIDTH
        CMP PADDLE_RIGHT_X, AX
        JG FIX_PADDLE_RIGHT_BOTTOM_POSITION
        JMP EXIT_PADDLE_MOVEMENT
                
    FIX_PADDLE_RIGHT_BOTTOM_POSITION:
        MOV PADDLE_RIGHT_X, AX
        JMP EXIT_PADDLE_MOVEMENT
        
    EXIT_PADDLE_MOVEMENT:
        RET
        
    MOVE_PADDLES ENDP
    
    RESET_PELOTA_POSITION PROC NEAR
        ; Restaurar posición original de la pelota
        MOV AX, PELOTA_ORIGINAL_X
        MOV PELOTA_X, AX
    
        MOV AX, PELOTA_ORIGINAL_Y
        MOV PELOTA_Y, AX

        ; Restaurar velocidades originales
        MOV PELOTA_VELOCITY_Y, -07   ; velocidad vertical negativa para comenzar hacia arriba
        ; Se omite la asignación de PELOTA_VELOCITY_X para que el que anote tenga el "saque"
        RET
    RESET_PELOTA_POSITION ENDP
    
    DRAW_PELOTA PROC NEAR
        MOV CX, PELOTA_X         ; establecer la columna inicial (X)
        MOV DX, PELOTA_Y         ; establecer la fila inicial (Y)
        
    DRAW_PELOTA_HORIZONTAL:
        MOV AH, 0Ch            ; configuración para escribir un píxel
        MOV AL, 0Fh            ; elegir blanco como color
        MOV BH, 00h            ; establecer número de página 
        INT 10h               ; ejecutar la rutina de video
            
        INC CX                ; incrementar la columna
        MOV AX, CX
        SUB AX, PELOTA_X      ; calcular la diferencia: CX - PELOTA_X
        CMP AX, PELOTA_SIZE
        JNG DRAW_PELOTA_HORIZONTAL
            
        MOV CX, PELOTA_X      ; regresar a la columna inicial
        INC DX              ; avanzar una fila
            
        MOV AX, DX
        SUB AX, PELOTA_Y      ; calcular la diferencia: DX - PELOTA_Y
        CMP AX, PELOTA_SIZE
        JNG DRAW_PELOTA_HORIZONTAL
        
        RET
    DRAW_PELOTA ENDP

    ; Dibuja la pelota en color negro (para borrarla)
    DRAW_PELOTA_NEGRO PROC NEAR
        MOV CX, PELOTA_X
        MOV DX, PELOTA_Y

    DRAW_PELOTA_NEGRO_HORIZONTAL:
        MOV AH, 0Ch
        MOV AL, 00h           ; color negro (fondo)
        MOV BH, 00h
        INT 10h

        INC CX
        MOV AX, CX
        SUB AX, PELOTA_X
        CMP AX, PELOTA_SIZE
        JNG DRAW_PELOTA_NEGRO_HORIZONTAL

        MOV CX, PELOTA_X
        INC DX

        MOV AX, DX
        SUB AX, PELOTA_Y
        CMP AX, PELOTA_SIZE
        JNG DRAW_PELOTA_NEGRO_HORIZONTAL

        RET
    DRAW_PELOTA_NEGRO ENDP
    
    DRAW_PADDLES PROC NEAR
        MOV CX, PADDLE_LEFT_X   ; establecer columna inicial de la paleta izquierda
        MOV DX, PADDLE_LEFT_Y   ; establecer fila inicial de la paleta izquierda
        
    DRAW_PADDLE_LEFT_HORIZONTAL:
        MOV AH, 0Ch           ; configuración para escribir un píxel
        MOV AL, 0Fh           ; elegir blanco como color
        MOV BH, 00h           ; establecer número de página 
        INT 10h              ; ejecutar la configuración
            
        INC CX              ; incrementar la columna
        MOV AX, CX
        SUB AX, PADDLE_LEFT_X ; calcular diferencia: CX - PADDLE_LEFT_X
        CMP AX, PADDLE_WIDTH
        JNG DRAW_PADDLE_LEFT_HORIZONTAL
            
        MOV CX, PADDLE_LEFT_X ; regresar a la columna inicial
        INC DX              ; avanzar una fila
            
        MOV AX, DX
        SUB AX, PADDLE_LEFT_Y ; calcular diferencia: DX - PADDLE_LEFT_Y
        CMP AX, PADDLE_HEIGHT
        JNG DRAW_PADDLE_LEFT_HORIZONTAL
            
        ; Dibujar paleta derecha
        MOV CX, PADDLE_RIGHT_X   ; establecer columna inicial de la paleta derecha
        MOV DX, PADDLE_RIGHT_Y   ; establecer fila inicial de la paleta derecha
        
    DRAW_PADDLE_RIGHT_HORIZONTAL:
        MOV AH, 0Ch           ; configuración para escribir un píxel
        MOV AL, 0Fh           ; elegir blanco como color
        MOV BH, 00h           ; establecer número de página 
        INT 10h              ; ejecutar la configuración
            
        INC CX              ; incrementar la columna
        MOV AX, CX
        SUB AX, PADDLE_RIGHT_X ; calcular diferencia: CX - PADDLE_RIGHT_X
        CMP AX, PADDLE_WIDTH
        JNG DRAW_PADDLE_RIGHT_HORIZONTAL
            
        MOV CX, PADDLE_RIGHT_X ; regresar a la columna inicial
        INC DX              ; avanzar una fila
            
        MOV AX, DX
        SUB AX, PADDLE_RIGHT_Y ; calcular diferencia: DX - PADDLE_RIGHT_Y
        CMP AX, PADDLE_HEIGHT
        JNG DRAW_PADDLE_RIGHT_HORIZONTAL
            
        RET
    DRAW_PADDLES ENDP
    
    DRAW_PADDLES_NEGRO PROC NEAR
        ; Borrar paleta izquierda
        MOV CX, PADDLE_LEFT_X
        MOV DX, PADDLE_LEFT_Y

    BORRAR_PADDLE_LEFT_H:
        MOV AH, 0Ch
        MOV AL, 00h         ; color negro
        MOV BH, 00h
        INT 10h

        INC CX
        MOV AX, CX
        SUB AX, PADDLE_LEFT_X
        CMP AX, PADDLE_WIDTH
        JNG BORRAR_PADDLE_LEFT_H

        MOV CX, PADDLE_LEFT_X
        INC DX
        MOV AX, DX
        SUB AX, PADDLE_LEFT_Y
        CMP AX, PADDLE_HEIGHT
        JNG BORRAR_PADDLE_LEFT_H

        ; === Borrar paleta derecha ===
        MOV CX, PADDLE_RIGHT_X
        MOV DX, PADDLE_RIGHT_Y

    BORRAR_PADDLE_RIGHT_H:
        MOV AH, 0Ch
        MOV AL, 00h         ; color negro
        MOV BH, 00h
        INT 10h

        INC CX
        MOV AX, CX
        SUB AX, PADDLE_RIGHT_X
        CMP AX, PADDLE_WIDTH
        JNG BORRAR_PADDLE_RIGHT_H

        MOV CX, PADDLE_RIGHT_X
        INC DX
        MOV AX, DX
        SUB AX, PADDLE_RIGHT_Y
        CMP AX, PADDLE_HEIGHT
        JNG BORRAR_PADDLE_RIGHT_H

        RET
    DRAW_PADDLES_NEGRO ENDP
    
    DRAW_UI PROC NEAR
        ; Dibujar los puntos del jugador uno
        MOV AH, 02h             ; establecer posición del cursor
        MOV BH, 00h             ; número de página
        MOV DH, 04h             ; fila
        MOV DL, 06h             ; columna
        INT 10h
            
        MOV AH, 09h             ; escribir cadena en salida estándar
        LEA DX, TEXT_PLAYER_ONE_POINTS   ; cargar dirección del texto de puntos del jugador uno
        INT 21h             ; imprimir la cadena
            
        ; Dibujar los puntos del jugador dos
        MOV AH, 02h             ; establecer posición del cursor
        MOV BH, 00h             ; número de página
        MOV DH, 04h             ; fila
        MOV DL, 1Fh            ; columna
        INT 10h
            
        MOV AH, 09h             ; escribir cadena en salida estándar
        LEA DX, TEXT_PLAYER_TWO_POINTS   ; cargar dirección del texto de puntos del jugador dos
        INT 21h             ; imprimir la cadena
            
        RET
    DRAW_UI ENDP

;code by freddy
    
    UPDATE_TEXT_PLAYER_ONE_POINTS PROC NEAR
        XOR AX, AX
        MOV AL, PLAYER_ONE_POINTS    ; por ejemplo, si P1 tiene 2 puntos, AL = 2
        ; Convertir el valor decimal a código ASCII sumando 30h
        ADD AL, 30h              ; AL se convierte en '2'
        MOV [TEXT_PLAYER_ONE_POINTS], AL
        RET
    UPDATE_TEXT_PLAYER_ONE_POINTS ENDP
    
    UPDATE_TEXT_PLAYER_TWO_POINTS PROC NEAR
        XOR AX, AX
        MOV AL, PLAYER_TWO_POINTS    ; por ejemplo, si P2 tiene 2 puntos, AL = 2
        ADD AL, 30h              ; AL se convierte en '2'
        MOV [TEXT_PLAYER_TWO_POINTS], AL
        RET
    UPDATE_TEXT_PLAYER_TWO_POINTS ENDP
    
    DRAW_GAME_OVER_MENU PROC NEAR      ; dibujar el menú de fin de juego
        CALL CLEAR_SCREEN      ; limpiar la pantalla antes de mostrar el menú

        ; Mostrar el título del menú
        MOV AH, 02h             ; establecer posición del cursor
        MOV BH, 00h             ; número de página
        MOV DH, 04h             ; fila
        MOV DL, 0Eh            ; columna
        INT 10h
        MOV AH, 09h             ; escribir cadena en salida estándar
        LEA DX, TEXT_GAME_OVER_TITLE   ; cargar dirección del título del menú de fin de juego
        INT 21h             ; imprimir la cadena

        ; Mostrar el ganador
        MOV AH, 02h             ; establecer posición del cursor
        MOV BH, 00h             ; número de página
        MOV DH, 06h             ; fila
        MOV DL, 0Dh            ; columna
        INT 10h
        CALL UPDATE_WINNER_TEXT
        MOV AH, 09h             ; escribir cadena en salida estándar
        LEA DX, TEXT_GAME_OVER_WINNER   ; cargar dirección del texto del ganador
        INT 21h             ; imprimir la cadena

        ; Mostrar el mensaje: presiona R para jugar de nuevo
        MOV AH, 02h             ; establecer posición del cursor
        MOV BH, 00h             ; número de página
        MOV DH, 08h             ; fila
        MOV DL, 09h            ; columna
        INT 10h
        MOV AH, 09h             ; escribir cadena en salida estándar
        LEA DX, TEXT_GAME_OVER_PLAY_AGAIN   ; cargar dirección del mensaje para volver a jugar
        INT 21h             ; imprimir la cadena

        ; Mostrar el mensaje: presiona E para ir al menú principal
        MOV AH, 02h             ; establecer posición del cursor
        MOV BH, 00h             ; número de página
        MOV DH, 0Ah             ; fila
        MOV DL, 05h            ; columna
        INT 10h
        MOV AH, 09h             ; escribir cadena en salida estándar
        LEA DX, TEXT_GAME_OVER_MAIN_MENU   ; cargar dirección del mensaje para ir al menú principal
        INT 21h             ; imprimir la cadena

        ; Esperar a que se presione una tecla
        MOV AH, 00h
        INT 16h

        ; Si se presiona 'R' o 'r', reiniciar el juego		
        CMP AL, 'R'
        JE RESTART_GAME
        CMP AL, 'r'
        JE RESTART_GAME
        ; Si se presiona 'E' o 'e', ir al menú principal
        CMP AL, 'E'
        JE EXIT_TO_MAIN_MENU
        CMP AL, 'e'
        JE EXIT_TO_MAIN_MENU
        RET
        
    RESTART_GAME:
        CALL CLEAR_SCREEN
        MOV GAME_ACTIVE, 01h
        RET
        
    EXIT_TO_MAIN_MENU:
        MOV GAME_ACTIVE, 00h
        MOV CURRENT_SCENE, 00h
        RET
            
    DRAW_GAME_OVER_MENU ENDP
    
;code by freddy

    DRAW_MAIN_MENU PROC NEAR
        CALL CLEAR_SCREEN

        ; Título centrado
        MOV AH, 02h
        MOV BH, 00h
        MOV DH, 04h          ; fila
        MOV DL, 0Eh         ; columna
        INT 10h

        MOV AH, 09h
        LEA DX, TEXT_MAIN_MENU_TITLE
        INT 21h

        ; Opción de JUGAR centrada
        MOV AH, 02h
        MOV BH, 00h
        MOV DH, 08h
        MOV DL, 0Eh
        INT 10h

        MOV AH, 09h
        LEA DX, TEXT_MAIN_MENU_PLAY
        INT 21h

        ; Opción de SALIR centrada
        MOV AH, 02h
        MOV BH, 00h
        MOV DH, 0Ah
        MOV DL, 0Bh
        INT 10h

        MOV AH, 09h
        LEA DX, TEXT_MAIN_MENU_EXIT
        INT 21h

        ; Crédito "Yachay Tech" centrado
        MOV AH, 02h
        MOV BH, 00h
        MOV DH, 0Ch
        MOV DL, 0Fh
        INT 10h

        MOV AH, 09h
        LEA DX, TEXT_MAIN_MENU_CREDIT
        INT 21h

        ; Esperar entrada del usuario
    MAIN_MENU_WAIT_FOR_KEY:
        MOV AH, 00h
        INT 16h

        CMP AL, 'P'
        JE START_PLAY
        CMP AL, 'p'
        JE START_PLAY
        CMP AL, 'E'
        JE EXIT_GAME
        CMP AL, 'e'
        JE EXIT_GAME
        JMP MAIN_MENU_WAIT_FOR_KEY

    START_PLAY:
        CALL CLEAR_SCREEN
        MOV CURRENT_SCENE, 01h
        MOV GAME_ACTIVE, 01h
        RET

    EXIT_GAME:
        MOV EXITING_GAME, 01h
        RET
    DRAW_MAIN_MENU ENDP
    
    UPDATE_WINNER_TEXT PROC NEAR
        MOV AL, WINNER_INDEX    ; si el índice es 1, AL = 1
        ADD AL, 30h             ; convertir a ASCII ('1')
        MOV [TEXT_GAME_OVER_WINNER+7], AL   ; actualizar el índice en el mensaje del ganador
        RET
    UPDATE_WINNER_TEXT ENDP
    
    CLEAR_SCREEN PROC NEAR               ; limpiar la pantalla reiniciando el modo de video
        MOV AH, 00h           ; establecer modo de video
        MOV AL, 13h           ; elegir modo de video 13h
        INT 10h             ; ejecutar la configuración
        
        MOV AH, 0Bh           ; establecer configuración para el color de fondo
        MOV BH, 00h
        MOV BL, 00h           ; elegir negro como color de fondo
        INT 10h             ; ejecutar la configuración
        
        RET
    CLEAR_SCREEN ENDP
    
    CONCLUDE_EXIT_GAME PROC NEAR       ; volver al modo de texto
        MOV AH, 00h           ; establecer modo de video
        MOV AL, 02h           ; elegir modo de video 2h
        INT 10h             ; ejecutar la configuración
        
        MOV AH, 4Ch           ; terminar el programa
        INT 21h
    CONCLUDE_EXIT_GAME ENDP

CODE ENDS
END
```// filepath: c:\Users\Freddy\Desktop\game\volley.asm
STACK SEGMENT PARA STACK
    DB 64 DUP (' ')
STACK ENDS

DATA SEGMENT PARA 'DATA'
    
    WINDOW_WIDTH DW 140h                 ; el ancho de la ventana (320 píxeles)
    WINDOW_HEIGHT DW 0C8h                ; la altura de la ventana (200 píxeles)
    WINDOW_BOUNDS DW 6                   ; variable utilizada para verificar colisiones tempranas
    
    TIME_AUX DB 0                        ; variable utilizada para comprobar si el tiempo ha cambiado
    GAME_ACTIVE DB 1                     ; ¿el juego está activo? (1 → sí, 0 → no [juego terminado])
    EXITING_GAME DB 0
    WINNER_INDEX DB 0                    ; el índice del ganador (1 → jugador uno, 2 → jugador dos)
    CURRENT_SCENE DB 0                   ; el índice de la escena actual (0 → menú principal, 1 → juego)
    
    TEXT_PLAYER_ONE_POINTS DB '0','$'    ; texto con los puntos del jugador uno
    TEXT_PLAYER_TWO_POINTS DB '0','$'    ; texto con los puntos del jugador dos
    TEXT_GAME_OVER_TITLE DB 'GAME OVER','$' ; texto con el título del menú de fin de juego
    TEXT_GAME_OVER_WINNER DB 'Player 0 won','$' ; texto con el ganador
    TEXT_GAME_OVER_PLAY_AGAIN DB 'Press R to play again','$' ; texto: presiona R para jugar de nuevo
    TEXT_GAME_OVER_MAIN_MENU DB 'Press E to exit to main menu','$' ; texto: presiona E para salir al menú principal
    TEXT_MAIN_MENU_TITLE DB 'VOLLEY GAME','$' ; texto con el título del menú principal
    TEXT_MAIN_MENU_CREDIT DB 'Yachay Tech','$'
    TEXT_MAIN_MENU_PLAY DB 'PLAY - P KEY','$' ; texto: JUGAR – TECLA P
    TEXT_MAIN_MENU_EXIT DB 'EXIT GAME - E KEY','$' ; texto: SALIR DEL JUEGO – TECLA E
    
    PELOTA_ORIGINAL_X DW 0A0h              ; posición X de la pelota al inicio del juego
    PELOTA_ORIGINAL_Y DW 64h               ; posición Y de la pelota al inicio del juego
    PELOTA_X DW 0A0h                       ; posición X actual (columna) de la pelota
    PELOTA_Y DW 64h                        ; posición Y actual (fila) de la pelota
    PELOTA_SIZE DW 06h                     ; tamaño de la pelota (cantidad de píxeles en ancho y alto)
    PELOTA_VELOCITY_X DW 05h               ; velocidad horizontal (X) de la pelota
    PELOTA_VELOCITY_Y DW 02h               ; velocidad vertical (Y) de la pelota
    
    PADDLE_LEFT_X DW 50h                 ; posición X actual de la paleta izquierda
    PADDLE_LEFT_Y DW 0a0h                 ; posición Y actual de la paleta izquierda
    PLAYER_ONE_POINTS DB 0              ; puntos actuales del jugador uno
    
    PADDLE_RIGHT_X DW 0c0h               ; posición X actual de la paleta derecha
    PADDLE_RIGHT_Y DW 0a0h               ; posición Y actual de la paleta derecha
    PLAYER_TWO_POINTS DB 0             ; puntos actuales del jugador dos
    
    PADDLE_WIDTH DW 25h                  ; ancho predeterminado de la paleta
    PADDLE_HEIGHT DW 06h                 ; alto predeterminado de la paleta
    PADDLE_VELOCITY DW 0Fh               ; velocidad predeterminada de la paleta
    
    ; variables del piso 
    FLOOR_WIDTH_HALF DW 0A0h       ; 160 píxeles
    FLOOR_HEIGHT     DW 14h        ; 20 píxeles
    FLOOR_Y          DW 0B4h       ; 180 píxeles
    FLOOR_LEFT_X     DW 00h        ; centro – mitad izquierda
    FLOOR_RIGHT_X    DW 0A0h       ; centro – mitad derecha

    ; Variables de la red 
    RED_X DW 0A0h              ; centro horizontal de la red
    RED_Y DW 07Ah              ; posición Y donde empieza la red (cerca del fondo)
    RED_WIDTH DW 08h           ; cantidad de píxeles que se extiende horizontalmente la red
    RED_HEIGHT DW 50h          ; altura de la red (~48 píxeles)
    ; limitador de colisiones con la red
    PELOTA_HIT_NET DB 0        ; 0 = no ha chocado con la red, 1 = sí ha chocado con la red
    
DATA ENDS

;code by freddy

CODE SEGMENT PARA 'CODE'

    MAIN PROC FAR
    ASSUME CS:CODE,DS:DATA,SS:STACK      ; asumir que CS, DS y SS corresponden a los segmentos de código, datos y pila
    PUSH DS                              ; guardar el segmento DS en la pila
    SUB AX,AX                            ; limpiar el registro AX
    PUSH AX                              ; guardar AX en la pila
    MOV AX,DATA                          ; cargar en AX la dirección del segmento DATA
    MOV DS,AX                            ; asignar DS al valor de AX
    POP AX                               ; recuperar el valor de AX desde la pila
    POP AX                               ; recuperar otro valor desde la pila
        
        CALL CLEAR_SCREEN                ; establecer configuraciones iniciales del modo de video
        
    CHECK_TIME:                      ; bucle de verificación del tiempo
            
            CMP EXITING_GAME,01h
            JE START_EXIT_PROCESS
            
            CMP CURRENT_SCENE,00h
            JE SHOW_MAIN_MENU
            
            CMP GAME_ACTIVE,00h
            JE SHOW_GAME_OVER
            
            MOV AH,2Ch 					 ; obtener la hora del sistema
            INT 21h    					 ; CH = hora, CL = minuto, DH = segundo, DL = centésimas de segundo
            
            CMP DL,TIME_AUX  			 ; comparar el tiempo actual con el anterior (TIME_AUX)
            JE CHECK_TIME    		     ; si es igual, volver a verificar
            
            ; Si se alcanza este punto, es porque ha pasado el tiempo
  
            MOV TIME_AUX,DL              ; actualizar el tiempo
            ; eliminamos la llamada a CLEAR_SCREEN en cada ciclo para evitar parpadeos
            ; sin embargo, los objetos con colisiones siempre deben refrescarse
            ; CALL CLEAR_SCREEN            ; limpiar la pantalla reiniciando el modo de video
                
            CALL DRAW_PELOTA_NEGRO   ; borrar la pelota anterior
            CALL MOVE_PELOTA         ; mover la pelota
            CALL DRAW_PELOTA         ; dibujar la nueva pelota

            CALL DRAW_PADDLES_NEGRO   ; borrar las paletas anteriores
            CALL MOVE_PADDLES         ; mover las paletas
            CALL DRAW_PADDLES         ; dibujar las nuevas paletas

            ; llamadas adicionales
            CALL DRAW_FLOORS
            CALL DRAW_NET
            CALL DRAW_UI                 ; dibujar la interfaz de usuario del juego
            JMP CHECK_TIME               ; volver a verificar el tiempo
            
        SHOW_GAME_OVER:
            CALL DRAW_GAME_OVER_MENU
            JMP CHECK_TIME
                
        SHOW_MAIN_MENU:
            CALL DRAW_MAIN_MENU
            JMP CHECK_TIME
                
        START_EXIT_PROCESS:
            CALL CONCLUDE_EXIT_GAME
                
        RET		
    MAIN ENDP

    ; Dibuja un bloque rectangular usando valores en memoria
    ; CX = columna inicial, DX = fila inicial, AL = color
    ; Usa FLOOR_WIDTH_HALF y FLOOR_HEIGHT desde DATA
    ;(LÓGICA DE LOS PISOS)
    DRAW_FLOORS PROC NEAR
    ; Piso izquierdo (rojo) 
    MOV CX, FLOOR_LEFT_X       ; columna inicial = 0
    MOV DX, FLOOR_Y            ; fila inicial = 180
    MOV SI, 0                  ; contador horizontal
; bucle para dibujar la anchura del piso izquierdo
DRAW_FLOOR_LEFT_WIDTH_LOOP:
    MOV DI, 0                  ; contador vertical

DRAW_FLOOR_LEFT_HEIGHT_LOOP:
    MOV AH, 0Ch
    MOV AL, 04h                ; color rojo
    MOV BH, 00h
    INT 10h

    INC DX
    INC DI
    CMP DI, FLOOR_HEIGHT
    JB DRAW_FLOOR_LEFT_HEIGHT_LOOP

    INC SI
    INC CX
    MOV DX, FLOOR_Y
    CMP SI, FLOOR_WIDTH_HALF   ; 160 columnas
    JB DRAW_FLOOR_LEFT_WIDTH_LOOP

    ; === Piso derecho (azul) ===
    MOV CX, FLOOR_RIGHT_X      ; columna inicial = 160
    MOV DX, FLOOR_Y
    MOV SI, 0

DRAW_FLOOR_RIGHT_WIDTH_LOOP:
    MOV DI, 0

DRAW_FLOOR_RIGHT_HEIGHT_LOOP:
    MOV AH, 0Ch
    MOV AL, 01h                ; color azul
    MOV BH, 00h
    INT 10h

    INC DX
    INC DI
    CMP DI, FLOOR_HEIGHT
    JB DRAW_FLOOR_RIGHT_HEIGHT_LOOP

    INC SI
    INC CX
    MOV DX, FLOOR_Y
    CMP SI, FLOOR_WIDTH_HALF
    JB DRAW_FLOOR_RIGHT_WIDTH_LOOP

    RET
    DRAW_FLOORS ENDP

    ; LÓGICA DE LA RED (NET)	
    DRAW_NET PROC NEAR
        MOV SI, 0              ; contador horizontal

DRAW_NET_WIDTH_LOOP:
        ; Calcular columna inicial: RED_X - (RED_WIDTH / 2) + SI
        MOV AX, RED_WIDTH
        SHR AX, 1              ; AX = RED_WIDTH / 2
        MOV BX, RED_X
        SUB BX, AX             ; inicio de la red
        ADD BX, SI             ; columna actual en la red
        MOV CX, BX             ; CX = columna

        MOV DX, RED_Y          ; DX = fila inicial (RED_Y)

DRAW_NET_HEIGHT_LOOP:
        MOV AH, 0Ch
        MOV AL, 07h            ; gris claro
        MOV BH, 00h
        INT 10h

        INC DX
        MOV AX, DX
        SUB AX, RED_Y
        CMP AX, RED_HEIGHT
        JB DRAW_NET_HEIGHT_LOOP

        INC SI
        MOV AX, SI
        CMP AX, RED_WIDTH
        JB DRAW_NET_WIDTH_LOOP

        RET
    DRAW_NET ENDP

    MOVE_PELOTA PROC NEAR                  ; procesa el movimiento de la pelota
        
        ; Mover la pelota horizontalmente
        MOV AX, PELOTA_VELOCITY_X    
        ADD PELOTA_X, AX   
         
        ; Verificar si la pelota ha pasado el límite izquierdo (PELOTA_X < 0 + WINDOW_BOUNDS)
        ; De ser así, reiniciar su posición
        MOV AX, WINDOW_BOUNDS
        CMP PELOTA_X, AX                    ; comparar PELOTA_X con el límite izquierdo (0 + WINDOW_BOUNDS)
        JL HANDLE_POINT_P2                  ; si es menor, saltar a la etiqueta correspondiente
        
        ; Verificar si la pelota ha pasado el límite derecho (PELOTA_X > WINDOW_WIDTH - PELOTA_SIZE - WINDOW_BOUNDS)
        ; De ser así, reiniciar su posición
        MOV AX, WINDOW_WIDTH
        SUB AX, PELOTA_SIZE
        SUB AX, WINDOW_BOUNDS
        CMP PELOTA_X, AX	                ; comparar PELOTA_X con el límite derecho
        JG GIVE_POINT_TO_PLAYER_ONE  		; si es mayor, otorgar un punto al jugador uno y reiniciar la posición
        
        ; Verificar colisión con la red
        ; Condición: (PELOTA_X + PELOTA_SIZE > RED_X - RED_WIDTH/2) y (PELOTA_X < RED_X + RED_WIDTH/2)
        ;            y (PELOTA_Y + PELOTA_SIZE > RED_Y) y (PELOTA_Y < RED_Y + RED_HEIGHT)
        MOV AX, PELOTA_X
        ADD AX, PELOTA_SIZE
        MOV BX, RED_WIDTH
        SHR BX, 1
        MOV CX, RED_X
        SUB CX, BX            ; CX = RED_X - RED_WIDTH/2
        CMP AX, CX
        JLE NO_NET_COLLISION

        MOV AX, PELOTA_X
        MOV BX, RED_WIDTH
        SHR BX, 1
        MOV CX, RED_X
        ADD CX, BX            ; CX = RED_X + RED_WIDTH/2
        CMP AX, CX
        JGE NO_NET_COLLISION

        MOV AX, PELOTA_Y
        ADD AX, PELOTA_SIZE
        CMP AX, RED_Y
        JLE NO_NET_COLLISION

        MOV AX, PELOTA_Y
        MOV CX, RED_Y
        ADD CX, RED_HEIGHT
        CMP AX, CX
        JGE NO_NET_COLLISION

        ; Si se llega hasta aquí, hay colisión con la red → invertir la dirección en X
        ; Si ya había colisionado previamente, no realizar acción
        CMP PELOTA_HIT_NET, 1
        JE MOVE_PELOTA_VERTICALLY

        ; Si no había colisionado, marcar colisión y ajustar velocidades
        MOV PELOTA_HIT_NET, 1
        CALL NEG_VELOCITY_XYN
        JMP MOVE_PELOTA_VERTICALLY

    HANDLE_POINT_P2:
        CALL GIVE_POINT_TO_PLAYER_TWO
        RET

    NO_NET_COLLISION:
        MOV PELOTA_HIT_NET, 0         ; ya no está colisionando con la red
        JMP MOVE_PELOTA_VERTICALLY
        
    GIVE_POINT_TO_PLAYER_ONE:		 ; otorgar un punto al jugador uno y reiniciar la posición de la pelota
        INC PLAYER_ONE_POINTS         ; incrementar puntos del jugador uno
        CALL RESET_PELOTA_POSITION    ; reiniciar la posición de la pelota al centro de la pantalla
        CALL UPDATE_TEXT_PLAYER_ONE_POINTS  ; actualizar el texto de los puntos del jugador uno
        CMP PLAYER_ONE_POINTS,05h      ; verificar si el jugador alcanza 5 puntos
        JGE GAME_OVER                 ; si tiene 5 o más puntos, finalizar el juego
        RET
        
    GIVE_POINT_TO_PLAYER_TWO:        ; otorgar un punto al jugador dos y reiniciar la posición de la pelota
        INC PLAYER_TWO_POINTS         ; incrementar puntos del jugador dos
        CALL RESET_PELOTA_POSITION    ; reiniciar la posición de la pelota al centro de la pantalla
        CALL UPDATE_TEXT_PLAYER_TWO_POINTS  ; actualizar el texto de los puntos del jugador dos
        CMP PLAYER_TWO_POINTS,05h      ; verificar si el jugador alcanza 5 puntos
        JGE GAME_OVER                 ; si tiene 5 o más puntos, finalizar el juego
        RET
            
    GAME_OVER:                       ; algún jugador ha alcanzado 5 puntos
        CMP PLAYER_ONE_POINTS,05h      ; verificar cuál jugador tiene 5 o más puntos
        JNL WINNER_IS_PLAYER_ONE      ; si el jugador uno tiene 5 o más, es el ganador
        JMP WINNER_IS_PLAYER_TWO      ; de lo contrario, el jugador dos es el ganador
            
        WINNER_IS_PLAYER_ONE:
            MOV WINNER_INDEX,01h      ; actualizar el índice del ganador al jugador uno
            JMP CONTINUE_GAME_OVER
        WINNER_IS_PLAYER_TWO:
            MOV WINNER_INDEX,02h      ; actualizar el índice del ganador al jugador dos
            JMP CONTINUE_GAME_OVER
                
        CONTINUE_GAME_OVER:
            MOV PLAYER_ONE_POINTS,00h   ; reiniciar los puntos del jugador uno
            MOV PLAYER_TWO_POINTS,00h   ; reiniciar los puntos del jugador dos
            CALL UPDATE_TEXT_PLAYER_ONE_POINTS
            CALL UPDATE_TEXT_PLAYER_TWO_POINTS
            MOV GAME_ACTIVE,00h         ; detener el juego
            RET	

    ; Movimiento vertical de la pelota (aplicando "gravedad")
    MOVE_PELOTA_VERTICALLY:
        ; Intento de aplicar gravedad: incrementar la velocidad vertical cada fotograma
        MOV AX, 01h
        ADD PELOTA_VELOCITY_Y, AX

        ; Actualizar la posición vertical según la velocidad
        MOV AX, PELOTA_VELOCITY_Y
        ADD PELOTA_Y, AX
        ; Comprobar colisión con el piso: si (PELOTA_Y + PELOTA_SIZE) >= FLOOR_Y
        MOV AX, PELOTA_Y
        ADD AX, PELOTA_SIZE
        CMP AX, FLOOR_Y
        JL CONTINUAR_SIN_COLISION_FLOOR

        ; Hubo colisión con el piso: determinar si es del lado derecho o izquierdo
        MOV AX, PELOTA_X
        ADD AX, PELOTA_SIZE
        CMP AX, FLOOR_RIGHT_X      ; FLOOR_RIGHT_X = 160
        JL COLISION_CON_FLOOR_IZQUIERDO ; si está a la izquierda
        ; Sino, está a la derecha
    COLISION_CON_FLOOR_DERECHO:
        JMP DAR_PUNTO_JUGADOR_1

    COLISION_CON_FLOOR_IZQUIERDO:
        JMP DAR_PUNTO_JUGADOR_2

    DAR_PUNTO_JUGADOR_1:
        JMP GIVE_POINT_TO_PLAYER_ONE

    DAR_PUNTO_JUGADOR_2:
        JMP GIVE_POINT_TO_PLAYER_TWO

    CONTINUAR_SIN_COLISION_FLOOR:

        ; Verificar si la pelota ha pasado el límite superior (PELOTA_Y < 0 + WINDOW_BOUNDS)
        MOV AX, WINDOW_BOUNDS
        CMP PELOTA_Y, AX            ; comparar PELOTA_Y con el límite superior
        JL NEG_VELOCITY_Y           ; si es menor, invertir la velocidad vertical

        ; Verificar si la pelota ha pasado el límite inferior (PELOTA_Y > WINDOW_HEIGHT - PELOTA_SIZE - WINDOW_BOUNDS)
        MOV AX, WINDOW_HEIGHT	
        SUB AX, PELOTA_SIZE
        SUB AX, WINDOW_BOUNDS
        CMP PELOTA_Y, AX            ; comparar PELOTA_Y con el límite inferior
        JG NEG_VELOCITY_Y           ; si es mayor, invertir la velocidad vertical
        
        ; AQUI COMIENZA LA LÓGICA DE LA COLISIÓN DE LA PELOTA CON LAS PALETAS	
        ; Verificar colisión con la paleta derecha:
        ; (PELOTA_X + PELOTA_SIZE > PADDLE_RIGHT_X) y (PELOTA_X < PADDLE_RIGHT_X + PADDLE_WIDTH)
        ; y (PELOTA_Y + PELOTA_SIZE > PADDLE_RIGHT_Y) y (PELOTA_Y < PADDLE_RIGHT_Y + PADDLE_HEIGHT)
        MOV AX, PELOTA_X
        ADD AX, PELOTA_SIZE
        CMP AX, PADDLE_RIGHT_X
        JNG CHECK_COLLISION_WITH_LEFT_PADDLE   ; si no colisiona, verificar paleta izquierda
        
        MOV AX, PADDLE_RIGHT_X
        ADD AX, PADDLE_WIDTH
        CMP PELOTA_X, AX
        JNL CHECK_COLLISION_WITH_LEFT_PADDLE   ; si no colisiona, verificar paleta izquierda
        
        MOV AX, PELOTA_Y
        ADD AX, PELOTA_SIZE
        CMP AX, PADDLE_RIGHT_Y
        JNG CHECK_COLLISION_WITH_LEFT_PADDLE   ; si no colisiona, verificar paleta izquierda
        
        MOV AX, PADDLE_RIGHT_Y
        ADD AX, PADDLE_HEIGHT
        CMP PELOTA_Y, AX
        JNL CHECK_COLLISION_WITH_LEFT_PADDLE   ; si no colisiona, verificar paleta izquierda
        
        ; Si se llega hasta aquí, la pelota colisiona con la paleta derecha
        JMP NEG_VELOCITY_XY

        ; Verificar colisión con la paleta izquierda:
    CHECK_COLLISION_WITH_LEFT_PADDLE:
        ; (PELOTA_Y + PELOTA_SIZE > PADDLE_LEFT_Y) y (PELOTA_Y < PADDLE_LEFT_Y + PADDLE_HEIGHT)
        ; y (PELOTA_X + PELOTA_SIZE > PADDLE_LEFT_X) y (PELOTA_X < PADDLE_LEFT_X + PADDLE_WIDTH)
        MOV AX, PELOTA_Y
        ADD AX, PELOTA_SIZE
        CMP AX, PADDLE_LEFT_Y
        JNG EXIT_COLLISION_CHECK         ; si no colisiona, salir del chequeo
        
        MOV AX, PADDLE_LEFT_Y
        ADD AX, PADDLE_HEIGHT
        CMP PELOTA_Y, AX
        JNL EXIT_COLLISION_CHECK         ; si no colisiona, salir del chequeo
        
        MOV AX, PELOTA_X
        ADD AX, PELOTA_SIZE
        CMP AX, PADDLE_LEFT_X
        JNG EXIT_COLLISION_CHECK         ; si no colisiona, salir del chequeo
        
        MOV AX, PADDLE_LEFT_X
        ADD AX, PADDLE_WIDTH
        CMP PELOTA_X, AX
        JNL EXIT_COLLISION_CHECK         ; si no colisiona, salir del chequeo
        
        ; Si se llega aquí, la pelota colisiona con la paleta izquierda
        JMP NEG_VELOCITY_XY
        
        NEG_VELOCITY_Y:
            NEG PELOTA_VELOCITY_Y    ; invertir la velocidad vertical de la pelota
            RET
        NEG_VELOCITY_X:
            NEG PELOTA_VELOCITY_X    ; invertir la velocidad horizontal de la pelota
            RET
                    
        EXIT_COLLISION_CHECK:
            RET
        NEG_VELOCITY_XYN:
            ; Invertir la velocidad en X
            NEG PELOTA_VELOCITY_X
            MOV AX, PELOTA_VELOCITY_X
            CMP AX, 0
            JNS CONTINUE_X
                NEG AX
        CONTINUE_X:
            CMP AX, 2               ; evitar que sea 0 o demasiado lento
            JBE SKIP_REDUCE_X
            SUB AX, 1
            CMP PELOTA_VELOCITY_X, 0
            JL NEGATE_BACK_X
            MOV PELOTA_VELOCITY_X, AX
            JMP DONE_X
        NEGATE_BACK_X:
            NEG AX
            MOV PELOTA_VELOCITY_X, AX
        DONE_X:
            ; Invertir la velocidad en Y
            NEG PELOTA_VELOCITY_Y
            MOV AX, PELOTA_VELOCITY_Y
            CMP AX, 0
            JNS CONTINUE_Y
                NEG AX
        CONTINUE_Y:
            CMP AX, 2
            JBE SKIP_REDUCE_Y
            SUB AX, 1
            CMP PELOTA_VELOCITY_Y, 0
            JL NEGATE_BACK_Y
            MOV PELOTA_VELOCITY_Y, AX
            JMP DONE_Y
        NEGATE_BACK_Y:
            NEG AX
            MOV PELOTA_VELOCITY_Y, AX
        DONE_Y:
            RET

        SKIP_REDUCE_X:
        SKIP_REDUCE_Y:
            RET

        ; Lógica de gravedad y rebote en dirección contraria
        NEG_VELOCITY_XY:
            ; Obtener el signo original de X
            MOV AX, PELOTA_VELOCITY_X
            CMP AX, 0
            JGE ORIGINAL_WAS_POSITIVE_X
            MOV BL, 1              ; originalmente era negativo
            JMP GENERATE_X
        ORIGINAL_WAS_POSITIVE_X:
            MOV BL, 0              ; originalmente era positivo
        ; Generador de aleatoriedad
        GENERATE_X:
            ; Generar número aleatorio entre 4 y 6 para X
            MOV AH, 00h
            INT 1Ah
            MOV AX, DX
            AND AX, 0007h
            CMP AX, 02
            JBE RANDOM_X_OK
            MOV AX, 02             ; limitar a 2
        ; Estos bloques hacen que las velocidades en X e Y varíen
        RANDOM_X_OK:
            ADD AX, 4             ; resultado: 4, 5 o 6
            MOV CX, AX            ; guardar el valor absoluto de la nueva velocidad en X

            ; Aplicar dirección contraria
            CMP BL, 0
            JE SET_X_NEGATIVE     ; si originalmente era positivo, ahora se vuelve negativo
            JMP SET_X_POSITIVE    ; si originalmente era negativo, ahora se vuelve positivo

        SET_X_NEGATIVE:
            NEG CX
            MOV PELOTA_VELOCITY_X, CX
            JMP SET_Y

        SET_X_POSITIVE:
            MOV PELOTA_VELOCITY_X, CX

        SET_Y:
            ; Obtener número aleatorio entre 0 y 2 para impulso en Y
            MOV AH, 00h
            INT 1Ah
            MOV AX, DX
            AND AX, 0005h         ; sin movimiento
            CMP AX, 03            ; límite inferior de la velocidad
            JBE RANDOM_Y_OK
            MOV AX, 03
        RANDOM_Y_OK:
            NEG AX                ; invertir
            SUB AX, 12            ; establecer límite de velocidad hacia arriba
            MOV PELOTA_VELOCITY_Y, AX

            RET

    MOVE_PELOTA ENDP
    
;code by freddy

    MOVE_PADDLES PROC NEAR               ; procesa el movimiento de las paletas
        
        ; Movimiento de la paleta izquierda
        ; Verificar si se presiona alguna tecla (si no, revisar la paleta derecha)
        MOV AH, 01h
        INT 16h
        JZ CHECK_RIGHT_PADDLE_MOVEMENT   ; si no se presionó tecla, saltar a la verificación de la paleta derecha
        
        ; Determinar la tecla presionada (AL = carácter ASCII)
        MOV AH, 00h
        INT 16h
        
        ; Si es 'a' o 'A', mover hacia arriba
        CMP AL, 61h            ; 'a'
        JE MOVE_LEFT_PADDLE_UP
        CMP AL, 41h            ; 'A'
        JE MOVE_LEFT_PADDLE_UP
        
        ; Si es 'd' o 'D', mover hacia abajo
        CMP AL, 64h            ; 'd'
        JE MOVE_LEFT_PADDLE_DOWN
        CMP AL, 44h            ; 'D'
        JE MOVE_LEFT_PADDLE_DOWN
        JMP CHECK_RIGHT_PADDLE_MOVEMENT
        
    MOVE_LEFT_PADDLE_UP:
        MOV AX, PADDLE_VELOCITY
        SUB PADDLE_LEFT_X, AX
        
        MOV AX, WINDOW_BOUNDS
        CMP PADDLE_LEFT_X, AX
        JL FIX_PADDLE_LEFT_TOP_POSITION
        JMP CHECK_RIGHT_PADDLE_MOVEMENT
        
    FIX_PADDLE_LEFT_TOP_POSITION:
        MOV PADDLE_LEFT_X, AX
        JMP CHECK_RIGHT_PADDLE_MOVEMENT
        
    MOVE_LEFT_PADDLE_DOWN:
        MOV AX, PADDLE_VELOCITY
        ADD PADDLE_LEFT_X, AX

        ; Limitar movimiento por la red
        MOV AX, RED_X
        SUB AX, PADDLE_WIDTH
        CMP PADDLE_LEFT_X, AX
        JG FIX_LEFT_PADDLE_NET
        JMP CONTINUE_LEFT_PADDLE_DOWN

    FIX_LEFT_PADDLE_NET:
        MOV PADDLE_LEFT_X, AX

        CONTINUE_LEFT_PADDLE_DOWN:
            ; Límite por borde derecho
            MOV AX, WINDOW_WIDTH
            SUB AX, WINDOW_BOUNDS
            SUB AX, PADDLE_WIDTH
            CMP PADDLE_LEFT_X, AX
            JG FIX_PADDLE_LEFT_BOTTOM_POSITION
            JMP CHECK_RIGHT_PADDLE_MOVEMENT

            MOV AX, WINDOW_WIDTH
            SUB AX, WINDOW_BOUNDS
            SUB AX, PADDLE_WIDTH
            CMP PADDLE_LEFT_X, AX
            JG FIX_PADDLE_LEFT_BOTTOM_POSITION
            JMP CHECK_RIGHT_PADDLE_MOVEMENT
            
    FIX_PADDLE_LEFT_BOTTOM_POSITION:
        MOV PADDLE_LEFT_X, AX
        JMP CHECK_RIGHT_PADDLE_MOVEMENT
        
        ; Movimiento de la paleta derecha
    CHECK_RIGHT_PADDLE_MOVEMENT:
        ; Si es 'j' o 'J', mover hacia arriba
        CMP AL, 6Ah           ; 'j'
        JE MOVE_RIGHT_PADDLE_UP
        CMP AL, 4Ah           ; 'J'
        JE MOVE_RIGHT_PADDLE_UP
        
        ; Si es 'l' o 'L', mover hacia abajo
        CMP AL, 6Ch           ; 'l'
        JE MOVE_RIGHT_PADDLE_DOWN
        CMP AL, 4Ch           ; 'L'
        JE MOVE_RIGHT_PADDLE_DOWN
        JMP EXIT_PADDLE_MOVEMENT
                
    MOVE_RIGHT_PADDLE_UP:
        MOV AX, PADDLE_VELOCITY
        SUB PADDLE_RIGHT_X, AX

        ; Limitar por la red
        MOV AX, RED_X
        CMP PADDLE_RIGHT_X, AX
        JL FIX_RIGHT_PADDLE_NET
        JMP CONTINUE_RIGHT_PADDLE_UP

    FIX_RIGHT_PADDLE_NET:
        MOV PADDLE_RIGHT_X, AX

        CONTINUE_RIGHT_PADDLE_UP:
            MOV AX, WINDOW_BOUNDS
            CMP PADDLE_RIGHT_X, AX
            JL FIX_PADDLE_RIGHT_TOP_POSITION
            JMP EXIT_PADDLE_MOVEMENT

            MOV AX, WINDOW_BOUNDS
            CMP PADDLE_RIGHT_X, AX
            JL FIX_PADDLE_RIGHT_TOP_POSITION
            JMP EXIT_PADDLE_MOVEMENT
            
    FIX_PADDLE_RIGHT_TOP_POSITION:
        MOV PADDLE_RIGHT_X, AX
        JMP EXIT_PADDLE_MOVEMENT
            
    MOVE_RIGHT_PADDLE_DOWN:
        MOV AX, PADDLE_VELOCITY
        ADD PADDLE_RIGHT_X, AX
        MOV AX, WINDOW_WIDTH
        SUB AX, WINDOW_BOUNDS
        SUB AX, PADDLE_WIDTH
        CMP PADDLE_RIGHT_X, AX
        JG FIX_PADDLE_RIGHT_BOTTOM_POSITION
        JMP EXIT_PADDLE_MOVEMENT
                
    FIX_PADDLE_RIGHT_BOTTOM_POSITION:
        MOV PADDLE_RIGHT_X, AX
        JMP EXIT_PADDLE_MOVEMENT
        
    EXIT_PADDLE_MOVEMENT:
        RET
        
    MOVE_PADDLES ENDP
    
    RESET_PELOTA_POSITION PROC NEAR
        ; Restaurar posición original de la pelota
        MOV AX, PELOTA_ORIGINAL_X
        MOV PELOTA_X, AX
    
        MOV AX, PELOTA_ORIGINAL_Y
        MOV PELOTA_Y, AX

        ; Restaurar velocidades originales
        MOV PELOTA_VELOCITY_Y, -07   ; velocidad vertical negativa para comenzar hacia arriba
        ; Se omite la asignación de PELOTA_VELOCITY_X para que el que anote tenga el "saque"
        RET
    RESET_PELOTA_POSITION ENDP
    
    DRAW_PELOTA PROC NEAR
        MOV CX, PELOTA_X         ; establecer la columna inicial (X)
        MOV DX, PELOTA_Y         ; establecer la fila inicial (Y)
        
    DRAW_PELOTA_HORIZONTAL:
        MOV AH, 0Ch            ; configuración para escribir un píxel
        MOV AL, 0Fh            ; elegir blanco como color
        MOV BH, 00h            ; establecer número de página 
        INT 10h               ; ejecutar la rutina de video
            
        INC CX                ; incrementar la columna
        MOV AX, CX
        SUB AX, PELOTA_X      ; calcular la diferencia: CX - PELOTA_X
        CMP AX, PELOTA_SIZE
        JNG DRAW_PELOTA_HORIZONTAL
            
        MOV CX, PELOTA_X      ; regresar a la columna inicial
        INC DX              ; avanzar una fila
            
        MOV AX, DX
        SUB AX, PELOTA_Y      ; calcular la diferencia: DX - PELOTA_Y
        CMP AX, PELOTA_SIZE
        JNG DRAW_PELOTA_HORIZONTAL
        
        RET
    DRAW_PELOTA ENDP

    ; Dibuja la pelota en color negro (para borrarla)
    DRAW_PELOTA_NEGRO PROC NEAR
        MOV CX, PELOTA_X
        MOV DX, PELOTA_Y

    DRAW_PELOTA_NEGRO_HORIZONTAL:
        MOV AH, 0Ch
        MOV AL, 00h           ; color negro (fondo)
        MOV BH, 00h
        INT 10h

        INC CX
        MOV AX, CX
        SUB AX, PELOTA_X
        CMP AX, PELOTA_SIZE
        JNG DRAW_PELOTA_NEGRO_HORIZONTAL

        MOV CX, PELOTA_X
        INC DX

        MOV AX, DX
        SUB AX, PELOTA_Y
        CMP AX, PELOTA_SIZE
        JNG DRAW_PELOTA_NEGRO_HORIZONTAL

        RET
    DRAW_PELOTA_NEGRO ENDP
    
    DRAW_PADDLES PROC NEAR
        MOV CX, PADDLE_LEFT_X   ; establecer columna inicial de la paleta izquierda
        MOV DX, PADDLE_LEFT_Y   ; establecer fila inicial de la paleta izquierda
        
    DRAW_PADDLE_LEFT_HORIZONTAL:
        MOV AH, 0Ch           ; configuración para escribir un píxel
        MOV AL, 0Fh           ; elegir blanco como color
        MOV BH, 00h           ; establecer número de página 
        INT 10h              ; ejecutar la configuración
            
        INC CX              ; incrementar la columna
        MOV AX, CX
        SUB AX, PADDLE_LEFT_X ; calcular diferencia: CX - PADDLE_LEFT_X
        CMP AX, PADDLE_WIDTH
        JNG DRAW_PADDLE_LEFT_HORIZONTAL
            
        MOV CX, PADDLE_LEFT_X ; regresar a la columna inicial
        INC DX              ; avanzar una fila
            
        MOV AX, DX
        SUB AX, PADDLE_LEFT_Y ; calcular diferencia: DX - PADDLE_LEFT_Y
        CMP AX, PADDLE_HEIGHT
        JNG DRAW_PADDLE_LEFT_HORIZONTAL
            
        ; Dibujar paleta derecha
        MOV CX, PADDLE_RIGHT_X   ; establecer columna inicial de la paleta derecha
        MOV DX, PADDLE_RIGHT_Y   ; establecer fila inicial de la paleta derecha
        
    DRAW_PADDLE_RIGHT_HORIZONTAL:
        MOV AH, 0Ch           ; configuración para escribir un píxel
        MOV AL, 0Fh           ; elegir blanco como color
        MOV BH, 00h           ; establecer número de página 
        INT 10h              ; ejecutar la configuración
            
        INC CX              ; incrementar la columna
        MOV AX, CX
        SUB AX, PADDLE_RIGHT_X ; calcular diferencia: CX - PADDLE_RIGHT_X
        CMP AX, PADDLE_WIDTH
        JNG DRAW_PADDLE_RIGHT_HORIZONTAL
            
        MOV CX, PADDLE_RIGHT_X ; regresar a la columna inicial
        INC DX              ; avanzar una fila
            
        MOV AX, DX
        SUB AX, PADDLE_RIGHT_Y ; calcular diferencia: DX - PADDLE_RIGHT_Y
        CMP AX, PADDLE_HEIGHT
        JNG DRAW_PADDLE_RIGHT_HORIZONTAL
            
        RET
    DRAW_PADDLES ENDP
    
    DRAW_PADDLES_NEGRO PROC NEAR
        ; Borrar paleta izquierda
        MOV CX, PADDLE_LEFT_X
        MOV DX, PADDLE_LEFT_Y

    BORRAR_PADDLE_LEFT_H:
        MOV AH, 0Ch
        MOV AL, 00h         ; color negro
        MOV BH, 00h
        INT 10h

        INC CX
        MOV AX, CX
        SUB AX, PADDLE_LEFT_X
        CMP AX, PADDLE_WIDTH
        JNG BORRAR_PADDLE_LEFT_H

        MOV CX, PADDLE_LEFT_X
        INC DX
        MOV AX, DX
        SUB AX, PADDLE_LEFT_Y
        CMP AX, PADDLE_HEIGHT
        JNG BORRAR_PADDLE_LEFT_H

        ; === Borrar paleta derecha ===
        MOV CX, PADDLE_RIGHT_X
        MOV DX, PADDLE_RIGHT_Y

    BORRAR_PADDLE_RIGHT_H:
        MOV AH, 0Ch
        MOV AL, 00h         ; color negro
        MOV BH, 00h
        INT 10h

        INC CX
        MOV AX, CX
        SUB AX, PADDLE_RIGHT_X
        CMP AX, PADDLE_WIDTH
        JNG BORRAR_PADDLE_RIGHT_H

        MOV CX, PADDLE_RIGHT_X
        INC DX
        MOV AX, DX
        SUB AX, PADDLE_RIGHT_Y
        CMP AX, PADDLE_HEIGHT
        JNG BORRAR_PADDLE_RIGHT_H

        RET
    DRAW_PADDLES_NEGRO ENDP

;code by freddy
    
    DRAW_UI PROC NEAR
        ; Dibujar los puntos del jugador uno
        MOV AH, 02h             ; establecer posición del cursor
        MOV BH, 00h             ; número de página
        MOV DH, 04h             ; fila
        MOV DL, 06h             ; columna
        INT 10h
            
        MOV AH, 09h             ; escribir cadena en salida estándar
        LEA DX, TEXT_PLAYER_ONE_POINTS   ; cargar dirección del texto de puntos del jugador uno
        INT 21h             ; imprimir la cadena
            
        ; Dibujar los puntos del jugador dos
        MOV AH, 02h             ; establecer posición del cursor
        MOV BH, 00h             ; número de página
        MOV DH, 04h             ; fila
        MOV DL, 1Fh            ; columna
        INT 10h
            
        MOV AH, 09h             ; escribir cadena en salida estándar
        LEA DX, TEXT_PLAYER_TWO_POINTS   ; cargar dirección del texto de puntos del jugador dos
        INT 21h             ; imprimir la cadena
            
        RET
    DRAW_UI ENDP
    
    UPDATE_TEXT_PLAYER_ONE_POINTS PROC NEAR
        XOR AX, AX
        MOV AL, PLAYER_ONE_POINTS    ; por ejemplo, si P1 tiene 2 puntos, AL = 2
        ; Convertir el valor decimal a código ASCII sumando 30h
        ADD AL, 30h              ; AL se convierte en '2'
        MOV [TEXT_PLAYER_ONE_POINTS], AL
        RET
    UPDATE_TEXT_PLAYER_ONE_POINTS ENDP
    
    UPDATE_TEXT_PLAYER_TWO_POINTS PROC NEAR
        XOR AX, AX
        MOV AL, PLAYER_TWO_POINTS    ; por ejemplo, si P2 tiene 2 puntos, AL = 2
        ADD AL, 30h              ; AL se convierte en '2'
        MOV [TEXT_PLAYER_TWO_POINTS], AL
        RET
    UPDATE_TEXT_PLAYER_TWO_POINTS ENDP
    
    DRAW_GAME_OVER_MENU PROC NEAR      ; dibujar el menú de fin de juego
        CALL CLEAR_SCREEN      ; limpiar la pantalla antes de mostrar el menú

        ; Mostrar el título del menú
        MOV AH, 02h             ; establecer posición del cursor
        MOV BH, 00h             ; número de página
        MOV DH, 04h             ; fila
        MOV DL, 0Eh            ; columna
        INT 10h
        MOV AH, 09h             ; escribir cadena en salida estándar
        LEA DX, TEXT_GAME_OVER_TITLE   ; cargar dirección del título del menú de fin de juego
        INT 21h             ; imprimir la cadena

        ; Mostrar el ganador
        MOV AH, 02h             ; establecer posición del cursor
        MOV BH, 00h             ; número de página
        MOV DH, 06h             ; fila
        MOV DL, 0Dh            ; columna
        INT 10h
        CALL UPDATE_WINNER_TEXT
        MOV AH, 09h             ; escribir cadena en salida estándar
        LEA DX, TEXT_GAME_OVER_WINNER   ; cargar dirección del texto del ganador
        INT 21h             ; imprimir la cadena

        ; Mostrar el mensaje: presiona R para jugar de nuevo
        MOV AH, 02h             ; establecer posición del cursor
        MOV BH, 00h             ; número de página
        MOV DH, 08h             ; fila
        MOV DL, 09h            ; columna
        INT 10h
        MOV AH, 09h             ; escribir cadena en salida estándar
        LEA DX, TEXT_GAME_OVER_PLAY_AGAIN   ; cargar dirección del mensaje para volver a jugar
        INT 21h             ; imprimir la cadena

        ; Mostrar el mensaje: presiona E para ir al menú principal
        MOV AH, 02h             ; establecer posición del cursor
        MOV BH, 00h             ; número de página
        MOV DH, 0Ah             ; fila
        MOV DL, 05h            ; columna
        INT 10h
        MOV AH, 09h             ; escribir cadena en salida estándar
        LEA DX, TEXT_GAME_OVER_MAIN_MENU   ; cargar dirección del mensaje para ir al menú principal
        INT 21h             ; imprimir la cadena

        ; Esperar a que se presione una tecla
        MOV AH, 00h
        INT 16h

        ; Si se presiona 'R' o 'r', reiniciar el juego		
        CMP AL, 'R'
        JE RESTART_GAME
        CMP AL, 'r'
        JE RESTART_GAME
        ; Si se presiona 'E' o 'e', ir al menú principal
        CMP AL, 'E'
        JE EXIT_TO_MAIN_MENU
        CMP AL, 'e'
        JE EXIT_TO_MAIN_MENU
        RET
        
    RESTART_GAME:
        CALL CLEAR_SCREEN
        MOV GAME_ACTIVE, 01h
        RET
        
    EXIT_TO_MAIN_MENU:
        MOV GAME_ACTIVE, 00h
        MOV CURRENT_SCENE, 00h
        RET
            
    DRAW_GAME_OVER_MENU ENDP
    
    DRAW_MAIN_MENU PROC NEAR
        CALL CLEAR_SCREEN

        ; Título centrado
        MOV AH, 02h
        MOV BH, 00h
        MOV DH, 04h          ; fila
        MOV DL, 0Eh         ; columna
        INT 10h

        MOV AH, 09h
        LEA DX, TEXT_MAIN_MENU_TITLE
        INT 21h

        ; Opción de JUGAR centrada
        MOV AH, 02h
        MOV BH, 00h
        MOV DH, 08h
        MOV DL, 0Eh
        INT 10h

        MOV AH, 09h
        LEA DX, TEXT_MAIN_MENU_PLAY
        INT 21h

        ; Opción de SALIR centrada
        MOV AH, 02h
        MOV BH, 00h
        MOV DH, 0Ah
        MOV DL, 0Bh
        INT 10h

        MOV AH, 09h
        LEA DX, TEXT_MAIN_MENU_EXIT
        INT 21h

        ; Crédito "Yachay Tech" centrado
        MOV AH, 02h
        MOV BH, 00h
        MOV DH, 0Ch
        MOV DL, 0Fh
        INT 10h

        MOV AH, 09h
        LEA DX, TEXT_MAIN_MENU_CREDIT
        INT 21h

        ; Esperar entrada del usuario
    MAIN_MENU_WAIT_FOR_KEY:
        MOV AH, 00h
        INT 16h

        CMP AL, 'P'
        JE START_PLAY
        CMP AL, 'p'
        JE START_PLAY
        CMP AL, 'E'
        JE EXIT_GAME
        CMP AL, 'e'
        JE EXIT_GAME
        JMP MAIN_MENU_WAIT_FOR_KEY

    START_PLAY:
        CALL CLEAR_SCREEN
        MOV CURRENT_SCENE, 01h
        MOV GAME_ACTIVE, 01h
        RET

    EXIT_GAME:
        MOV EXITING_GAME, 01h
        RET
    DRAW_MAIN_MENU ENDP
    
    UPDATE_WINNER_TEXT PROC NEAR
        MOV AL, WINNER_INDEX    ; si el índice es 1, AL = 1
        ADD AL, 30h             ; convertir a ASCII ('1')
        MOV [TEXT_GAME_OVER_WINNER+7], AL   ; actualizar el índice en el mensaje del ganador
        RET
    UPDATE_WINNER_TEXT ENDP
    
    CLEAR_SCREEN PROC NEAR               ; limpiar la pantalla reiniciando el modo de video
        MOV AH, 00h           ; establecer modo de video
        MOV AL, 13h           ; elegir modo de video 13h
        INT 10h             ; ejecutar la configuración
        
        MOV AH, 0Bh           ; establecer configuración para el color de fondo
        MOV BH, 00h
        MOV BL, 00h           ; elegir negro como color de fondo
        INT 10h             ; ejecutar la configuración
        
        RET
    CLEAR_SCREEN ENDP
    
    CONCLUDE_EXIT_GAME PROC NEAR       ; volver al modo de texto
        MOV AH, 00h           ; establecer modo de video
        MOV AL, 02h           ; elegir modo de video 2h
        INT 10h             ; ejecutar la configuración
        
        MOV AH, 4Ch           ; terminar el programa
        INT 21h
    CONCLUDE_EXIT_GAME ENDP

;code by freddy

CODE ENDS
END