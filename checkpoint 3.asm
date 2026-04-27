;========================================================
; CHECKPOINT 3 - SEL0433
; Eduardo Gondim Rezende - 15448693
; Matheus Herberts Rios de Lima - 15653174
;========================================================
; Controle de direção + contagem de voltas
;
; Funções implementadas:
; - Leitura da chave SW em P2.0
; - Inversão do sentido do motor
; - Contagem de pulsos com Timer1
; - Exibição da contagem no display (0 a 9)
; - Ao chegar em 10, reinicia em 0
;========================================================

CONTAGEM EQU 30H          ; variável em RAM para armazenar a contagem

ORG 0000H
    SJMP START              ; desvia para o início do programa

;========================================================
; TABELA DO DISPLAY DE 7 SEGMENTOS (ÂNODO COMUM)
; Cada posição representa um número de 0 a 9
;========================================================
TAB7SEG:
    DB 0C0H ; 0
    DB 0F9H ; 1
    DB 0A4H ; 2
    DB 0B0H ; 3
    DB 099H ; 4
    DB 092H ; 5
    DB 082H ; 6
    DB 0F8H ; 7
    DB 080H ; 8
    DB 090H ; 9

;========================================================
; INICIALIZAÇÃO
;========================================================
START:

    MOV SP, #60H            ; move a pilha para RAM alta
    CLR F0                  ; estado inicial do motor = 0
    MOV CONTAGEM, #00H      ; zera variável de contagem

    ACALL ATUALIZA_MOTOR    ; aplica sentido inicial

    ;----------------------------------------------------
    ; Configuração do Timer1
    ; TMOD = 50H
    ; Timer1 em modo contador externo, modo 1 (16 bits)
    ;----------------------------------------------------
    MOV TMOD, #50H

    MOV TH1, #00H           ; zera parte alta
    MOV TL1, #00H           ; zera parte baixa

    SETB TR1                ; liga Timer1

;========================================================
; LOOP PRINCIPAL
;========================================================
MAIN:

    ACALL VERIFICA_SW       ; verifica se mudou a chave
    ACALL MOSTRA_CONTAGEM   ; atualiza display

    SJMP MAIN               ; repete para sempre

;========================================================
; SUBROTINA: VERIFICA_SW
; Lê a chave em P2.0 e compara com o estado atual (F0)
; Se mudou, atualiza o motor
;========================================================
VERIFICA_SW:

    MOV C, P2.0             ; lê chave
    CPL C                   ; inverte lógica da chave

    JNB F0, CHECK_ZERO      ; se F0=0 vai testar caso zero

    ; Caso atual = 1
    JC IGUAL                ; se chave também =1, não mudou
    SJMP MUDA               ; senão mudou

CHECK_ZERO:

    ; Caso atual = 0
    JNC IGUAL               ; se chave também =0, não mudou

MUDA:

    MOV F0, C               ; salva novo estado
    ACALL ATUALIZA_MOTOR    ; muda sentido do motor

IGUAL:
    RET

;========================================================
; SUBROTINA: ATUALIZA_MOTOR
; Controla P3.0 e P3.1
;========================================================
ATUALIZA_MOTOR:

    JB F0, SENTIDO1         ; se F0=1 vai para sentido 1

;--------------------------
; Sentido 0
;--------------------------
SENTIDO0:
    SETB P3.0               ; ativa saída 1
    CLR  P3.1               ; desativa saída 2
    RET

;--------------------------
; Sentido 1
;--------------------------
SENTIDO1:
    CLR  P3.0               ; desativa saída 1
    SETB P3.1               ; ativa saída 2
    RET

;========================================================
; SUBROTINA: MOSTRA_CONTAGEM
; Lê TL1, salva na variável CONTAGEM e mostra no display
; Se chegar em 10, volta para zero
;========================================================
MOSTRA_CONTAGEM:

    MOV A, TL1              ; A recebe contagem atual
    MOV CONTAGEM, A         ; armazena contagem na variável

    MOV A, CONTAGEM         ; A recebe a variável de contagem

    CLR C
    SUBB A, #0AH            ; testa se CONTAGEM >= 10
    JC MENOR_QUE_10         ; se menor que 10, continua normal

    ;------------------------------------
    ; Se chegou em 10, reinicia contagem
    ;------------------------------------
    MOV TL1, #00H
    MOV CONTAGEM, #00H
    MOV A, #00H

    MOV DPTR, #TAB7SEG
    MOVC A, @A+DPTR
    MOV P1, A
    RET

MENOR_QUE_10:

    MOV A, CONTAGEM         ; pega valor atual da variável
    MOV DPTR, #TAB7SEG      ; aponta para tabela

    MOVC A, @A+DPTR         ; busca padrão do número
    MOV P1, A               ; envia para display

    RET

END