;========================================================
; PROJETO FINAL - SEL0433
; Eduardo Gondim Rezende - 15448693
; Matheus Herberts Rios de Lima - 15653174
;========================================================
; Sistema de dosagem rotativa
;
; Baseado nos Checkpoints 1, 2 e 3
;
; Funcoes implementadas:
; - Controle de sentido do motor por chave SW em P2.0
; - Motor controlado por P3.0 e P3.1
; - Contagem de voltas usando Timer1 como contador externo
; - Display de 7 segmentos em P1 mostrando 0 a 9
; - Ao atingir 10 pulsos, a interrupcao do Timer1 zera a contagem
; - Ao mudar o sentido, o motor para, a contagem zera e o motor reinicia
; - Ponto decimal do display indica o sentido de rotacao
;========================================================

CONTAGEM EQU 30H          ; variavel em RAM para armazenar a contagem

;========================================================
; VETORES DE INTERRUPCAO
;========================================================

ORG 0000H
    LJMP START            ; vetor de reset

ORG 001BH
    LJMP ISR_TIMER1       ; vetor de interrupcao do Timer1


;========================================================
; INICIALIZACAO
;========================================================

ORG 0030H

START:

    MOV SP, #60H          ; move a pilha para uma regiao segura da RAM

    CLR F0                ; sentido inicial do motor = 0
    MOV CONTAGEM, #00H    ; zera variavel de contagem

    ;----------------------------------------------------
    ; Configuracao do Timer1
    ;
    ; TMOD = 50H
    ; Timer1 em modo contador externo
    ; Modo 1: contador de 16 bits
    ;
    ; O Timer1 sera carregado com FFF6H.
    ; Assim, depois de 10 pulsos externos:
    ;
    ; FFF6 -> FFF7 -> ... -> FFFF -> 0000
    ;
    ; Ao passar de FFFF para 0000, ocorre overflow
    ; e a interrupcao do Timer1 e acionada.
    ;----------------------------------------------------

    MOV TMOD, #50H        ; Timer1 contador externo, modo 1

    ACALL RESET_TIMER1    ; carrega TH1/TL1 e zera CONTAGEM

    SETB ET1              ; habilita interrupcao do Timer1
    SETB EA               ; habilita interrupcoes globais

    ACALL ATUALIZA_MOTOR  ; aplica o sentido inicial do motor


;========================================================
; LOOP PRINCIPAL
;========================================================

MAIN:

    ACALL VERIFICA_SW       ; verifica se a chave de sentido mudou
    ACALL MOSTRA_CONTAGEM   ; atualiza o display

    SJMP MAIN               ; repete continuamente


;========================================================
; SUBROTINA: VERIFICA_SW
;
; Le a chave em P2.0 e compara com o estado atual em F0.
; Se a chave mudou:
; - para o motor
; - atualiza F0
; - zera o Timer1 e a contagem
; - reinicia o motor no novo sentido
;========================================================

VERIFICA_SW:

    MOV C, P2.0             ; le a chave SW0
    CPL C                   ; inverte a logica, mantendo o padrao usado antes

    JNB F0, CHECK_ZERO      ; se F0 = 0, verifica caso zero

    ; Caso atual: F0 = 1
    JC IGUAL                ; se chave tambem = 1, nao mudou
    SJMP MUDA               ; senao, mudou

CHECK_ZERO:

    ; Caso atual: F0 = 0
    JNC IGUAL               ; se chave tambem = 0, nao mudou

MUDA:

    ACALL PARA_MOTOR        ; para o motor antes da troca de sentido

    MOV F0, C               ; atualiza o sentido armazenado

    ACALL RESET_TIMER1      ; zera a contagem ao mudar o sentido

    ACALL ATUALIZA_MOTOR    ; liga o motor no novo sentido

IGUAL:

    RET


;========================================================
; SUBROTINA: PARA_MOTOR
;
; Desliga as duas saidas de controle do motor.
;========================================================

PARA_MOTOR:

    CLR P3.0
    CLR P3.1
    RET


;========================================================
; SUBROTINA: ATUALIZA_MOTOR
;
; Controla P3.0 e P3.1 de acordo com F0.
;========================================================

ATUALIZA_MOTOR:

    JB F0, SENTIDO1         ; se F0 = 1, vai para sentido 1

;--------------------------
; Sentido 0
;--------------------------
SENTIDO0:

    SETB P3.0               ; ativa saida 1
    CLR  P3.1               ; desativa saida 2
    RET

;--------------------------
; Sentido 1
;--------------------------
SENTIDO1:

    CLR  P3.0               ; desativa saida 1
    SETB P3.1               ; ativa saida 2
    RET


;========================================================
; SUBROTINA: RESET_TIMER1
;
; Reinicia o Timer1 para gerar overflow depois de 10 pulsos.
;
; Valor inicial:
; TH1 = FFH
; TL1 = F6H
;
; Como FFF6H + 10 pulsos = 0000H, o Timer1 interrompe
; exatamente no decimo pulso.
;========================================================

RESET_TIMER1:

    CLR TR1                 ; para Timer1
    CLR TF1                 ; limpa flag de overflow

    MOV TH1, #0FFH          ; parte alta do valor inicial
    MOV TL1, #0F6H          ; parte baixa do valor inicial

    MOV CONTAGEM, #00H      ; zera variavel de contagem

    SETB TR1                ; reinicia Timer1

    RET


;========================================================
; SUBROTINA: MOSTRA_CONTAGEM
;
; Calcula a contagem atual a partir de TL1.
;
; Como TL1 comeca em F6H:
;
; TL1 = F6H -> contagem 0
; TL1 = F7H -> contagem 1
; TL1 = F8H -> contagem 2
; ...
; TL1 = FFH -> contagem 9
;
; A contagem e usada como indice da tabela de 7 segmentos.
; O ponto decimal e ajustado de acordo com F0.
;========================================================

MOSTRA_CONTAGEM:

    MOV A, TL1              ; le parte baixa do Timer1

    CLR C
    SUBB A, #0F6H           ; A = TL1 - F6H

    JNC CONTAGEM_VALIDA     ; se nao deu borrow, valor esta entre 0 e 9

    MOV A, #00H             ; protecao caso ocorra overflow durante a leitura

CONTAGEM_VALIDA:

    MOV CONTAGEM, A         ; salva contagem atual

    MOV DPTR, #TAB7SEG      ; aponta para tabela do display
    MOVC A, @A+DPTR         ; busca padrao correspondente

    ;----------------------------------------------------
    ; Ponto decimal indicando sentido
    ;
    ; Display anodo comum:
    ; bit em 0 acende segmento
    ; bit em 1 apaga segmento
    ;
    ; Se F0 = 0: ponto decimal apagado
    ; Se F0 = 1: ponto decimal aceso
    ;----------------------------------------------------

    JB F0, DP_ACESO

DP_APAGADO:

    SETB ACC.7              ; apaga ponto decimal
    SJMP ENVIA_DISPLAY

DP_ACESO:

    CLR ACC.7               ; acende ponto decimal

ENVIA_DISPLAY:

    MOV P1, A               ; envia padrao final para display
    RET


;========================================================
; INTERRUPCAO DO TIMER1
;
; Esta rotina e chamada quando o Timer1 transborda.
; Como o Timer1 foi iniciado em FFF6H, isso acontece
; depois de 10 pulsos externos.
;
; Quando isso ocorre:
; - Timer1 e parado
; - TH1/TL1 voltam para FFF6H
; - CONTAGEM volta para 0
; - Timer1 e reiniciado
;========================================================

ISR_TIMER1:

    PUSH ACC
    PUSH PSW

    CLR TR1                 ; para Timer1
    CLR TF1                 ; limpa flag da interrupcao

    MOV TH1, #0FFH
    MOV TL1, #0F6H

    MOV CONTAGEM, #00H

    SETB TR1                ; reinicia Timer1

    POP PSW
    POP ACC

    RETI


;========================================================
; TABELA DO DISPLAY DE 7 SEGMENTOS - ANODO COMUM
;
; Os valores abaixo mostram os numeros de 0 a 9.
; O bit 7 corresponde ao ponto decimal e sera ajustado
; na rotina MOSTRA_CONTAGEM.
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


END