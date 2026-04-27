;========================================================
; CHECKPOINT 2 - SEL0433
; Eduardo Gondim Rezende - 15448693
; Matheus Herberts Rios de Lima - 15653174
;========================================================
; Controle de direção do motor com chave (SW)
;
; Funcionamento:
; - Lê a chave em P2.0
; - Compara com estado atual (F0)
; - Se mudar → altera direção do motor
; - Motor controlado por P3.0 e P3.1
;
; Observação:
; - Usa subrotinas
; - Usa bit F0 como variável de estado
;========================================================

ORG 0000H

;--------------------------------------------------------
; Inicialização
;--------------------------------------------------------
START:
    CLR F0              ; estado inicial = 0
    ACALL ATUALIZA_MOTOR

;--------------------------------------------------------
; Loop principal
;--------------------------------------------------------
MAIN:
    ACALL VERIFICA_SW
    SJMP MAIN


;--------------------------------------------------------
; Subrotina: VERIFICA_SW
; - Lê a chave
; - Compara com F0
; - Se diferente → muda direção
;--------------------------------------------------------
VERIFICA_SW:

    MOV C, P2.0         ; lê chave (SW0)
    CPL C               ; ajusta: pressionado = 1

    ; Se F0 = 0
    JNB F0, CHECK_ZERO

    ; Aqui F0 = 1
    JC IGUAL            ; se chave = 1 → igual
    SJMP MUDA

CHECK_ZERO:
    ; Aqui F0 = 0
    JNC IGUAL           ; se chave = 0 → igual

MUDA:
    MOV F0, C           ; atualiza estado
    ACALL ATUALIZA_MOTOR

IGUAL:
    RET


;--------------------------------------------------------
; Subrotina: ATUALIZA_MOTOR
; Define sentido do motor
;--------------------------------------------------------
ATUALIZA_MOTOR:

    JB F0, SENTIDO1     ; se F0 = 1 → sentido 1

; sentido 0
SENTIDO0:
    SETB P3.0
    CLR  P3.1
    RET

; sentido 1
SENTIDO1:
    CLR  P3.0
    SETB P3.1
    RET

END