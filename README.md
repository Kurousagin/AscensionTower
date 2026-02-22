# THE TOWER OF THE SECOND HUMANITY
## Simulacao Textual Cyberpunk com IA Narrativa | Flutter MVP v2.0

---

## PREMISSA

15 humanos comuns foram arrancados de suas vidas cotidianas e jogados na base de uma torre mistica de 100 andares. Ninguem sabe por que estao aqui. Ninguem sabe quem os invocou. A unica certeza: **subir e a unica opcao**. E voce? Voce e o Observador — uma entidade que monitora tudo, sugere treinos, organiza grupos, mas nao controla ninguem diretamente.

**ATENCAO**: Alguns invocados podem ter passados obscuros. Ladroes, assassinos e estelionatarios podem estar entre eles. Vigiar com atencao.

---

## MECANICAS PRINCIPAIS

### Tempo Distorcido (Sistema Continuo — Ratio 2:1)
O mundo real e o mundo da Torre existem em **dimensoes diferentes**.

- **24 horas reais = 48 horas in-game** (ratio de distorcao: 2:1)
- **1 segundo real = 2 segundos na Torre**
- Sistema **continuo baseado em timestamp real** — nao depende de ticks fixos
- **Progresso offline**: o tempo continua passando com o jogo fechado!

**Formula**: `deltaGameSeconds = deltaRealSeconds * 2 * speedMultiplier`

**Estado salvo**: `lastRealTimestamp` (DateTime real) + `gameSeconds` (tempo acumulado na Torre)

**Ao abrir o jogo**: calcula delta real, converte para game seconds, processa dias acumulados (max 30/sessao)

#### Ciclo Dia/Noite
| Periodo | Horario |
|---------|---------|
| Madrugada | 00:00 - 05:59 |
| Manha | 06:00 - 11:59 |
| Tarde | 12:00 - 17:59 |
| Noite | 18:00 - 21:59 |
| Madrugada | 22:00 - 23:59 |

#### Velocidades
| Vel. | 24h real = | 1 dia jogo = |
|------|-----------|-------------|
| 1x | 2 dias jogo | ~12h reais |
| 2x | 4 dias jogo | ~6h reais |
| 5x | 10 dias jogo | ~2.4h reais |
| 10x | 20 dias jogo | ~72min reais |
| 25x | 50 dias jogo | ~29min reais |
| 50x | 100 dias jogo | ~14min reais |

- Tudo acontece automaticamente — voce observa e sugere

### Morte Permanente (Permadeath)
Quando um NPC morre, morre para sempre. Cascata de efeitos:
- Parceiro entra em luto (-15 sanidade)
- Filhos ficam orfaos (-10 sanidade + trauma)
- Aliados proximos sofrem (-3 sanidade)
- Moral geral cai (-5)
- Lealdade do parceiro cai (-5)

### Invocacao Emergencial
Quando a populacao cai para **5 ou menos**, a Torre invoca automaticamente 1-3 novos humanos a cada 14 dias. RISCO: podem ter origens obscuras!

---

## HIERARQUIA DE CONTROLE (Core Design)

O jogador **nao controla NPCs diretamente**. A hierarquia funciona assim:

| Nivel | Quem Decide | O Que |
|-------|------------|-------|
| 1 | **Jogador** | Quem ascende novos andares |
| 2 | **Jogador sugere** | Treinos (NPCs podem recusar!) |
| 3 | **NPCs autonomamente** | Se aceitam, se treinam, relacionamentos |

Esta e a dificuldade central e o objetivo do jogo: **ser lider sem controle direto**.

---

## SISTEMA DE LEALDADE (NOVO)

Cada NPC possui lealdade (0-100):

| Faixa | Estado | Comportamento |
|-------|--------|---------------|
| 70-100 | Leal | Aceita sugestoes, trabalha com empenho |
| 40-69 | Neutro | Pode aceitar ou recusar |
| 0-39 | Desleal | Resiste, risco de traicao elevado |

### Fatores que Afetam Lealdade
- Moral alta: +0.1/dia
- Moral baixa: -0.3/dia
- Comida abundante: +0.05/dia
- Traco "Leal": +0.1/dia
- Traco "Traicoeiro": -0.1/dia
- Origem obscura: -0.05/dia
- Membro de grupo: +0.05/dia
- Vitoria na Torre: +3
- Derrota na Torre: -2
- Nascimentos: +0.5 para todos
- Evolucao da Cidadela: +3 para todos

---

## SISTEMA DE TRAICAO (NOVO)

### Origens Obscuras
12% dos invocados podem ser de origem obscura:

| Origem | Atributos Base | Perigo |
|--------|---------------|--------|
| **Ladrao** | AGI 9, INT 7, CAR 6 | Rouba recursos (+25% risco base) |
| **Assassino** | FOR 8, AGI 10, RES 7 | Pode **matar** NPCs famosos! |
| **Estelionatario** | INT 9, CAR 10 | Manipula lealdade de outros |

### Tipos de Traicao (a cada 7 dias, se risco > 30%)
1. **Roubo**: Rouba 5-20 comida dos estoques
2. **Sabotagem**: Danifica equipamentos, -8 moral
3. **Manipulacao**: Espalha rumores, reduz lealdade de alvos
4. **Assassinato**: Apenas assassinos, 40% chance de sucesso contra NPCs famosos

### Calculo de Risco de Traicao
```
Risco = Base_Origem + Traicoeiro(+20) + Implacavel(+10) - Leal(-25) - Compassivo(-10)
       + (50-Lealdade)*0.3 + Sanidade_Baixa(+15/+15) + Traumas*2
```

---

## SISTEMA DE SUGESTAO DE TREINO (NOVO)

### Como Funciona
1. Jogador sugere treino para NPC individual ou grupo
2. NPC calcula chance de aceitacao baseada em multiplos fatores
3. NPC responde: Aceitar, Recusar, Negociar, Ignorar, ou Persuadir outros

### Fatores de Decisao do NPC
- Lealdade ao lider
- Fadiga/resistencia
- Moral atual
- Personalidade (Corajoso +15%, Covarde -15%)
- Presenca de Campo de Treino (+15%)
- Sanidade mental
- Historico de sugestoes anteriores

### Respostas Possiveis
| Resposta | Efeito |
|----------|--------|
| **Aceitar** | Treina, +2 lealdade |
| **Recusar** | Nao treina, -1 lealdade, razao baseada em personalidade |
| **Negociar** | Aceita com condicoes, +1 lealdade |
| **Ignorar** | Simplesmente ignora |
| **Persuadir** | Convence outros a treinar tambem |

### Impacto Politico
- **Favoritismo**: >5 sugestoes para o mesmo NPC com <30% aceitacao = perda de lealdade
- **Inatividade**: Nunca sugerir = perder referencia de lideranca
- **Perigo constante**: Enviar para missoes perigosas demais = corroer confianca

---

## SISTEMA DE GRUPOS/ESQUADROES (NOVO)

### Criacao
- Minimo 2 membros
- Lider eleito automaticamente (maior combatPower + carisma)
- Funcoes: Geral, Assalto, Reconhecimento, Treinamento, Defesa

### Beneficios
- Membros formam lacos mais rapido (+0.1 afinidade)
- +0.05 lealdade/dia por ser membro
- +0.2 sanidade/dia por ter grupo
- Coesao aumenta com tempo e missoes

### Coesao de Grupo (0-100%)
- Aumenta com missoes bem-sucedidas
- Aumenta com eventos aleatorios
- Diminui com baixas e conflitos internos

---

## RE-EXPLORACAO DE ANDARES (NOVO)

Andares conquistados podem ser revisitados para coletar recursos. Cada andar tem fauna e flora unica:

| Andar | Bioma | Recursos |
|-------|-------|----------|
| 1 | Ratos cristalinos, fungos luminosos | Madeira: ~8, Pedra: ~5, Comida: ~3 |
| 2 | Bestas deformadas, couro resistente | Comida: ~10, Ferro: ~2 |
| 3 | Fragmentos de espelho, essencia psiquica | Conhecimento: ~8, Comida: ~3 |
| 4 | Engrenagens antigas, metal raro | Ferro: ~5, Conhecimento: ~5 |
| 5 | Sangue de gladiador, trofeus | Ferro: ~8, Pedra: ~3 |
| 6 | Plantas toxicas, raizes curativas | Comida: ~15, Conhecimento: ~3 |
| 7 | Pergaminhos antigos, tinta magica | Conhecimento: ~15 |
| 8 | Cristais de julgamento | Conhecimento: ~5, Comida: ~5 |
| 9 | Sombras solidificadas, metal sombrio | Ferro: ~8, Pedra: ~8 |
| 10 | Fragmentos do Guardiao | Todos: ~10 cada |

### Riscos da Re-Exploracao
- **Ameaca oculta**: 5% base + 2% por re-exploracao anterior
- **Novas criaturas**: Podem surgir e causar baixas
- **Acidentes**: Ferimentos durante coleta
- **Descobertas**: 10% chance de recurso raro (+5 conhecimento)

### Automatizacao
Re-exploracoes acontecem automaticamente a cada ~14 dias (40% chance por ciclo) com exploradores e batedores disponiveis.

---

## DIFICULDADE ESCALADA (NOVO)

### Andares 1-2: Faceis
- Dificuldade: x0.6 do valor base
- Mortalidade: x0.4 da taxa base
- Ideal para: Primeiros passos, coleta facil

### Andares 3-9: Dificeis
- Dificuldade: valor nominal
- Mortalidade: taxa base
- Requer: Preparacao e grupo forte

### Andar 10: Boss
- Dificuldade: 10.0 (máxima)
- Mortalidade: 20% (pode perder metade do grupo)
- Requer: Preparacao maxima, grupo completo

---

## ANDARES DA TORRE (1-10)

| # | Tipo | Nome | Dif. | Mort. | Recompensa |
|---|------|------|------|-------|------------|
| 1 | Sobrevivencia | As Ruinas Silenciosas | 1.2 | 2% | +15 Mad, +10 Ped |
| 2 | Combate | O Corredor das Bestas | 1.8 | 3.2% | +20 Com, +5 Fer |
| 3 | Moral | A Sala dos Espelhos | 2.5 | 3% | +15 Con, +10 Moral |
| 4 | Estrategico | O Labirinto Mecanico | 4.0 | 10% | +10 Fer, +10 Con |
| 5 | Combate | A Arena Sangrenta | 5.0 | 12% | +15 Fer, +20 Fama |
| 6 | Sobrevivencia | O Pantano Toxico | 5.5 | 10% | +25 Com, +5 Con |
| 7 | Misterio | A Biblioteca Proibida | 4.5 | 7% | +30 Con, Talento |
| 8 | Moral | O Tribunal dos Pecados | 6.0 | 5% | +/-20 Moral |
| 9 | Estrategico | A Fortaleza das Sombras | 7.0 | 15% | +15 Fer, +15 Ped |
| 10 | BOSS | O GUARDIAO DO PRIMEIRO UMBRAL | 10.0 | 20% | +50 todos |

---

## ATRIBUTOS DOS NPCs

| Atributo | Escala | Efeito |
|----------|--------|--------|
| Forca (FOR) | 1-15 | Combate, construcao |
| Agilidade (AGI) | 1-15 | Esquiva, exploracao |
| Inteligencia (INT) | 1-15 | Estrategia, pesquisa |
| Resistencia (RES) | 1-15 | Sobrevivencia, duracao |
| Carisma (CAR) | 1-15 | Relacionamentos, moral |
| Sanidade (SAN) | 0-100 | Estabilidade psicologica |
| **Lealdade** | 0-100 | Cooperacao com o lider |

### Formulas
- **Poder de Combate**: FOR*0.3 + AGI*0.25 + RES*0.25 + INT*0.2
- **Risco de Traicao**: Calculado por multiplos fatores (ver secao Traicao)
- **Aceitacao de Treino**: Calculado por lealdade, fadiga, personalidade, etc.

---

## ORIGENS (18 tipos)

### Origens Regulares (15)
Estudante, Chef, Soldado, Programador, Atleta, Empresario, Medico, Professor, Artista, Mecanico, Fazendeiro, Musico, Cientista, Bombeiro, Enfermeiro(a)

### Origens Obscuras (3) - PERIGO!
- **Ladrao**: AGI alta, risco de roubo
- **Assassino**: FOR + AGI altas, risco de assassinato
- **Estelionatario**: INT + CAR altas, risco de manipulacao

---

## EDIFICIOS DA CIDADELA (16 tipos)

| Edificio | Custo | Efeito |
|----------|-------|--------|
| Fogueira | Mad: 5 | +1 moral/dia |
| Tenda | Mad: 10 | +3 pop. capacity |
| Armazem | Mad: 15, Ped: 10 | +50 armazenamento |
| Cozinha | Mad: 10, Ped: 5 | +3 com/dia por chef |
| Enfermaria | Mad: 15, Ped: 10, Con: 5 | Cura, reduz mortes |
| Oficina | Mad: 20, Ped: 15, Fer: 5 | Equipamentos basicos |
| Escola | Mad: 15, Ped: 10, Con: 10 | +1 con/dia |
| Forja | Ped: 25, Fer: 15, Con: 5 | Armas/armaduras, +1 fer/dia |
| Mercado | Mad: 20, Ped: 15 | Troca eficiente |
| Quartel | Mad: 25, Ped: 20, Fer: 10 | Treina guardas |
| Biblioteca | Mad: 20, Ped: 15, Con: 15 | +3 con/dia |
| Fazenda | Mad: 15, Ped: 5 | +5 com/dia |
| Muralha | Ped: 30, Fer: 10 | Defesa |
| Torre de Vigia | Mad: 15, Ped: 25, Fer: 5 | Alerta antecipado |
| Templo | Ped: 30, Mad: 20, Con: 20 | +2 moral, +0.5 san |
| **Campo de Treino** | Mad: 25, Ped: 20, Fer: 10, Con: 10 | Treino seguro, instrutores |

---

## TELAS DA INTERFACE

1. **Observatorio** - Dashboard com status geral, alertas, controles de tempo
2. **Torre** - Mapa dos andares, proximo desafio, re-exploracao, resultados
3. **Cidadela** - Recursos, edificios, progresso de evolucao
4. **Habitantes** - Lista de NPCs com lealdade, fama, risco de traicao
5. **Esquadroes** - Criacao/gerenciamento de grupos, sugestoes de treino
6. **Registros** - Log de eventos com filtros (incluindo traicao, politica, etc.)
7. **Codex** - Enciclopedia completa do jogo

---

## TIPOS DE EVENTOS (24)

Combate, Morte, Nascimento, Descoberta, Crise, Celebracao, Traicao, Romance, Construcao, Exploracao, Colapso Mental, Torre Conquistada, Evolucao, Recursos +/-, Treino, Sistema, **Grupo Formado**, **Sugestao de Treino**, **Tentativa de Traicao**, **Invocacao Emergencial**, **Re-Exploracao**, **Mudanca de Lealdade**, **Politica Interna**

---

## FILOSOFIA DO PROJETO

"The Tower of the Second Humanity" e uma experiencia de **simulacao social + gerenciamento estrategico + sobrevivencia + lideranca psicologica**. O jogador nao e um deus — e um lider que precisa:

- **Gerenciar recursos** sem controle direto
- **Identificar traidores** antes que causem danos
- **Equilibrar favoritismo** vs negligencia
- **Aceitar que NPCs tem vontade propria**
- **Sobreviver com morte permanente**

Cada decisao tem consequencias politicas. Cada morte e irreversivel. Cada invocado pode ser uma bencao ou uma maldicao.

---

## TECNOLOGIA
- Flutter 3.35.4 + Dart 3.9.2
- Provider (estado)
- Hive (persistencia local)
- UI: Terminal Cyberpunk com scanlines
- Fonte: FiraCode Mono

## ARQUITETURA TEMPORAL (Tecnico)

```
GameState {
  gameSeconds: double     // Tempo acumulado na Torre (0..86399.99)
  lastRealTimestamp: int  // Epoch ms do ultimo processamento
  currentDay: int         // Dia atual na Torre
}

// A cada ciclo de update (~1s):
now = DateTime.now().millisecondsSinceEpoch
deltaRealMs = now - lastRealTimestamp
deltaGameSeconds = (deltaRealMs / 1000) * 2.0 * speedMultiplier
gameSeconds += deltaGameSeconds

while (gameSeconds >= 86400):
    simulateDay()      // Processa 1 dia completo
    gameSeconds -= 86400

lastRealTimestamp = now

// Derivados:
currentHour = floor(gameSeconds / 3600)  // 0-23
currentMinute = floor((gameSeconds % 3600) / 60)  // 0-59
```
