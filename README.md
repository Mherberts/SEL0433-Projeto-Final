#  Lógica de Controle: Sistema de Dosagem Rotativa (8051)

**Disciplina:** SEL0433 - Aplicação de Microprocessadores  
**Autores:**
* Eduardo Gondim Rezende (15448693)
* Matheus Herberts Rios de Lima (15653174)

---

##  Sobre o Projeto

Este projeto consiste no desenvolvimento de um firmware escrito em **Assembly para a arquitetura do microcontrolador 8051**. O trabalho foi estruturado com base na metodologia PBL (Problem-Based Learning) para resolver uma situação teórica: o controle de um módulo dosador rotativo numa linha de produção.

Como a implementação é focada exclusivamente no software, os componentes (como o motor e o sensor de voltas) são abstraídos e representados pela manipulação direta das portas lógicas no simulador **EdSim51**. Os pinos `P3.0` e `P3.1` representam os sinais de acionamento do sentido, enquanto a chave `SW0` em `P2.0` funciona como o seletor de sentido de rotação.

A construção do código foi dividida em três entregas parciais evolutivas (**Checkpoints**), onde cada etapa permitiu o domínio de recursos específicos do microcontrolador, como I/O digital, sub-rotinas e temporizadores. Na etapa final, todos os blocos foram integrados, utilizando interrupções do Timer 1 para gerir o ciclo de dosagem de forma eficiente.

---

##  Checkpoint 1: Leitura de Chaves e Display de 7 Segmentos

O objetivo desta primeira etapa foi estabelecer a base de interação com o hardware, compreendendo os conceitos iniciais de entrada e saída digital (I/O) do 8051 e o acesso a dados gravados na memória de programa.

**O que foi desenvolvido:**  
O programa lê continuamente o estado de um banco de chaves (SW0 a SW7) conectadas à porta `P2`. Quando o operador aciona uma dessas chaves, o sistema identifica qual foi pressionada e exibe o número correspondente (de 0 a 7) em um display de 7 segmentos conectado à porta `P1`.

**Lógica e Arquitetura em Assembly:**  
Para realizar a conversão do número do botão para o padrão visual do display (do tipo ânodo comum), utilizamos uma estratégia de mapeamento via memória de programa:

* **Look-up Table:** Criamos uma tabela estática chamada `TABELA` contendo os valores hexadecimais dos padrões de segmento para os dígitos de 0 a 7.
* **Ponteiro de Dados:** O registrador `DPTR` foi configurado para apontar para o endereço inicial dessa tabela na memória de programa (ROM).
* **Busca com MOVC:** Após identificar o botão pressionado e armazenar seu índice numérico no Acumulador (`A`), utilizamos a instrução `MOVC A, @A+DPTR`. Essa instrução soma o valor do Acumulador com o endereço base do `DPTR`, acessando diretamente o padrão binário correto na ROM — diferentemente de `MOV`, que acessa a RAM de dados.
* **Subrotina MOSTRAR:** O envio do padrão ao display foi encapsulado em uma sub-rotina, que recebe o índice em `A`, faz a busca na tabela e escreve o resultado na porta `P1`.

---

##  Checkpoint 2: Controle de Direção do Motor

Nesta segunda etapa, o objetivo foi desenvolver a lógica de controle do sentido de rotação (simulado pelos pinos de saída), introduzindo a organização do programa em blocos funcionais e o uso de variáveis de estado.

**O que foi desenvolvido:**  
O sistema monitora continuamente a chave `SW0` no pino `P2.0`. Dependendo do estado desta chave, o programa define o sentido de rotação através dos pinos `P3.0` e `P3.1`. Se a chave for alterada, o "motor" inverte o sentido imediatamente.

**Lógica e Arquitetura em Assembly:**  
A principal evolução técnica nesta fase foi a implementação de uma lógica condicional com uso de sub-rotinas:

* **Variável de Estado (Bit F0):** Utilizamos o bit de propósito geral `F0` do registrador de status (`PSW`) para armazenar o sentido atual de rotação. Isso permite que o programa compare o estado lido da chave com o estado armazenado, agindo apenas quando há uma mudança efetiva.
* **Sub-rotinas:** O código foi estruturado com as sub-rotinas `VERIFICA_SW` (leitura e comparação da chave com `F0`) e `ATUALIZA_MOTOR` (atualização das saídas `P3.0` e `P3.1`). Essa separação facilita a reutilização e a manutenção nas etapas seguintes.
* **Manipulação de Saídas:** O controle é feito alternando os níveis lógicos nos pinos `P3.0` e `P3.1`. Para o sentido 0, `P3.0` é ativado (`SETB`) e `P3.1` desativado (`CLR`); para o sentido 1, os estados são invertidos.
* **Uso da Pilha:** Com o uso de `ACALL` e `RET`, os endereços de retorno das sub-rotinas são gerenciados automaticamente pela pilha do 8051. Neste checkpoint, o Stack Pointer (`SP`) ainda utiliza seu valor padrão; a inicialização explícita do `SP` para uma região segura da RAM foi introduzida a partir do Checkpoint 3.

---

##  Checkpoint 3: Contagem de Voltas com o Timer

O objetivo deste checkpoint foi incorporar o uso de temporizadores, configurando o **Timer 1** do 8051 como um contador de eventos externos para registar os pulsos simulados do sensor de voltas.

**O que foi desenvolvido:**  
O código passou a contabilizar as rotações por meio de pulsos externos simulados no EdSim51. O valor acumulado é exibido no display de 7 segmentos no intervalo de 0 a 9, com atualização contínua a cada iteração do laço principal.

**Lógica e Arquitetura em Assembly:**

* **Inicialização do Stack Pointer:** O `SP` foi movido para `60H` (`MOV SP, #60H`) para garantir que a pilha opere em uma região da RAM que não conflite com as variáveis do programa.
* **Configuração do TMOD:** O registrador `TMOD` foi carregado com o valor `50H`. Esse valor configura o Timer 1 no **Modo 1 (contador de 16 bits)** operando como **contador de eventos externos** — diferentemente do modo temporizador interno, onde o contador avança a cada ciclo de máquina; neste modo, ele avança apenas a cada pulso aplicado no pino externo `T1`.
* **Leitura de Pulsos:** O valor acumulado é lido diretamente do registrador `TL1` (parte baixa do contador de 16 bits), que é incrementado automaticamente pelo hardware a cada pulso externo.
* **Variável de Contagem:** O valor lido de `TL1` é armazenado na variável `CONTAGEM` (endereço `30H` na RAM), que serve como índice para a look-up table do display.
* **Atualização do Display:** O índice em `CONTAGEM` é usado com `MOVC A, @A+DPTR` para buscar o padrão de segmentos correto e enviá-lo à porta `P1`.
* **Modularidade:** As sub-rotinas `VERIFICA_SW` e `ATUALIZA_MOTOR` do checkpoint anterior foram reutilizadas diretamente no laço principal, permitindo que o sistema monitore a chave de sentido e a contagem de forma integrada.

---

##  Montagem Final (Integração e Interrupções)

Na entrega final, unimos as funcionalidades dos três checkpoints e implementamos as regras de negócio exigidas pelo projeto, utilizando interrupções de hardware para tornar o controle do contador mais organizado e eliminar a necessidade de polling contínuo.

**Principais Funcionalidades Integradas:**

* **Reset Automático via Interrupção (Ciclo de Dosagem):** O Timer 1 é inicializado com o valor `FFF6H` (`TH1 = FFH`, `TL1 = F6H`). Como o contador é de 16 bits, ao receber 10 pulsos externos (`FFF6H + 10 = 10000H`), ocorre overflow e a flag `TF1` é setada, disparando a interrupção do Timer 1. O vetor de interrupção está definido no endereço `001BH`, conforme a arquitetura do 8051.

* **ISR do Timer 1 (`ISR_TIMER1`):** A rotina de serviço de interrupção salva o contexto (`PUSH ACC` / `PUSH PSW`), para o timer, recarrega `TH1` e `TL1` com `FFF6H`, zera a variável `CONTAGEM` e reinicia o timer — garantindo um novo ciclo de 10 pulsos de forma automática e sem bloquear o laço principal.

* **Cálculo da Contagem na Exibição:** Como `TL1` parte de `F6H` (e não de `00H`), a subrotina `MOSTRA_CONTAGEM` não usa o valor bruto de `TL1` diretamente como índice. Em vez disso, calcula `A = TL1 - F6H`, convertendo o valor do timer para o índice real entre 0 e 9 antes de acessar a look-up table. Uma proteção foi adicionada para o caso de leitura ocorrer durante um overflow.

* **Reset Direcional:** Sempre que a chave `SW0` aciona a reversão do motor, o sistema primeiro para as saídas via `PARA_MOTOR`, atualiza `F0`, chama `RESET_TIMER1` (zerando timer e `CONTAGEM`) e só então liga o motor no novo sentido. Isso garante que o display represente apenas as voltas do sentido atual.

* **Indicação Visual do Sentido (Ponto Decimal):** O bit `P1.7` do display (ponto decimal) reflete o estado de `F0`. Como o display é ânodo comum, `CLR ACC.7` acende o ponto e `SETB ACC.7` o apaga. O bit é ajustado diretamente no padrão de segmentos antes do envio à porta `P1`, dentro da subrotina `MOSTRA_CONTAGEM`.

## Demonstração em Vídeo
 
O vídeo abaixo apresenta o projeto final em execução no simulador EdSim51, demonstrando as funcionalidades implementadas ao longo dos checkpoints.
 
🎥 [Clique aqui para assistir à demonstração](https://youtu.be/Z08C_YVxi5E)

