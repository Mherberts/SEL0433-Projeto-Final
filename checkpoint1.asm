;========================================================
; CHECKPOINT 1 - SEL0433
; Eduardo Gondim Rezende - 15448693
; Matheus Herberts Rios de Lima - 15653174
;========================================================
; Leitura dos switches e exibição no display de 7 segmentos
;
; Funcionamento:
; - Lê os switches SW0 a SW7 (porta P2)
; - Identifica qual botão foi pressionado
; - Converte o número para padrão de 7 segmentos
; - Exibe o valor no display conectado à porta P1
;
; Observação:
; - Display do tipo ânodo comum
; - Utiliza tabela em memória de programa (CODE)
; - Uso da instrução MOVC para acesso à tabela
;========================================================

ORG 0000H

;--------------------------------------------------------
; Inicialização
;--------------------------------------------------------
START:
    MOV DPTR, #TABELA    ; DPTR aponta para o início da tabela de 7 segmentos

;--------------------------------------------------------
; Loop principal
;--------------------------------------------------------
MAIN:
    MOV A, P2            ; Lê o estado dos switches (P2)
    CPL A                ; Inverte bits (pressionado vira 1)

    ; Verifica qual switch foi pressionado
    ; Se nenhum for pressionado, continua no loop

    JNB ACC.0, VERIF1
    MOV A, #00H
    ACALL MOSTRAR
    SJMP MAIN

VERIF1:
    JNB ACC.1, VERIF2
    MOV A, #01H
    ACALL MOSTRAR
    SJMP MAIN

VERIF2:
    JNB ACC.2, VERIF3
    MOV A, #02H
    ACALL MOSTRAR
    SJMP MAIN

VERIF3:
    JNB ACC.3, VERIF4
    MOV A, #03H
    ACALL MOSTRAR
    SJMP MAIN

VERIF4:
    JNB ACC.4, VERIF5
    MOV A, #04H
    ACALL MOSTRAR
    SJMP MAIN

VERIF5:
    JNB ACC.5, VERIF6
    MOV A, #05H
    ACALL MOSTRAR
    SJMP MAIN

VERIF6:
    JNB ACC.6, VERIF7
    MOV A, #06H
    ACALL MOSTRAR
    SJMP MAIN

VERIF7:
    JNB ACC.7, MAIN
    MOV A, #07H
    ACALL MOSTRAR
    SJMP MAIN


;--------------------------------------------------------
; Subrotina: MOSTRAR
; Entrada: A = número (0 a 7)
; Função: Busca padrão na tabela e envia para P1
;--------------------------------------------------------
MOSTRAR:
    MOVC A, @A+DPTR      ; Lê tabela na memória de programa (CODE)
    MOV P1, A            ; Envia padrão para display
    RET


;--------------------------------------------------------
; Tabela de 7 segmentos (ânodo comum)
; Cada valor corresponde a um número (0 a 7)
;--------------------------------------------------------
TABELA:
    DB 0C0H ; 0
    DB 0F9H ; 1
    DB 0A4H ; 2
    DB 0B0H ; 3
    DB 099H ; 4
    DB 092H ; 5
    DB 082H ; 6
    DB 0F8H ; 7

END