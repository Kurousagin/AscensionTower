# THE TOWER OF THE SECOND HUMANITY
## Simulacao Textual Cyberpunk com IA Narrativa | Flutter MVP v5.0

---

## PREMISSA

15 humanos comuns foram arrancados de suas vidas cotidianas e jogados na base de uma torre mistica de **100 andares**. Ninguem sabe por que estao aqui. Ninguem sabe quem os invocou. A unica certeza: **subir e a unica opcao**. E voce? Voce e o Observador — uma entidade que monitora tudo, sugere treinos, organiza grupos, mas nao controla ninguem diretamente.

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

### Sistema de Fadiga (v4.0)

Enviar NPCs repetidamente custa **fadiga fisica**. Forcar NPCs exaustos tem consequencias graves.

#### Estados de Fadiga
| Faixa | Status | Efeito |
|-------|--------|--------|
| 0-29% | Descansado | Nenhum. Performance normal. |
| 30-49% | Levemente cansado | Aceitacao de treino levemente reduzida |
| 50-69% | Cansado | -15% poder de combate. Reducao na recuperacao de sanidade. |
| 70-89% | **Exausto** | -35% poder de combate. -3 sanidade/dia. -0.5 lealdade/dia. Quase sempre recusa treinos. |
| 90-100% | **Incapacitado** | -60% poder de combate. -5 sanidade/dia. -1 lealdade/dia. Forcado a Ocioso. Risco de colapso fisico. **Bloqueado de selecao em expedicoes.** |

#### Custo de Fadiga por Atividade
| Atividade | Fadiga Base | Escala |
|-----------|------------|--------|
| Expedicao (andar novo) | 20-35 | +1.5 por tier |
| Re-exploracao | 15-25 | +1.0 por tier |
| Treino em andar | 12-22 | +1.0 por tier |
| Treino no Campo | 8 | Fixo |
| Treino autonomo | 6 | Fixo |

**Bonus de consecutividade**: Cada expedicao extra **no mesmo dia** adiciona +8~10 de fadiga bonus! Enviar o mesmo NPC 3x no mesmo dia resulta em fadiga massiva.

#### Recuperacao Diaria
| Fator | Recuperacao |
|-------|------------|
| Base | 15 + (RES/15 * 10) por dia |
| Enfermaria | +5/dia |
| Templo | +3/dia |
| Parceiro | +2/dia |
| Grupo | +1/dia |
| Fez expedicao hoje | Apenas 30% da recuperacao |

#### Cascata de Consequencias
```
Envio excessivo
  -> Fadiga 70%+ (Exausto)
    -> -3 sanidade/dia
    -> -0.5 lealdade/dia
    -> Recusa treinos
    -> Alerta narrativo a cada 3 dias
  -> Fadiga 90%+ (Incapacitado)
    -> -5 sanidade/dia  
    -> -1 lealdade/dia
    -> Profissao forcada a Ocioso
    -> 8% chance/dia de colapso fisico (trauma + -0.5 RES permanente)
    -> Bloqueado de expedicoes
```

**Implicacao Estrategica**: Voce NAO pode mandar o mesmo grupo infinitamente. Forca seus soldados e eles colapsam, perdem sanidade, lealdade, e eventualmente morrem. **Rotacione seus esquadroes.**

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

## A TORRE — 100 ANDARES, 10 TIERS

A Torre e dividida em **10 Tiers de 10 andares cada**. A dificuldade escala exponencialmente. Cada Tier introduz novos perigos, biomas e mecanicas.

### Estrutura Geral

```
TIER 10 [91-100]  IMPOSSIVEL   - Boss: TEL - A Criadora do Jogo
TIER  9 [81-90]   INFERNAL     - Boss: A Sombra Primordial
TIER  8 [71-80]   INFERNAL     - Boss: O Arquiteto do Caos
TIER  7 [61-70]   BRUTAL       - Boss: O Devorador de Almas
TIER  6 [51-60]   BRUTAL       - Boss: A Rainha Venenosa
TIER  5 [41-50]   BRUTAL       - Boss: O Imperador de Ferro
TIER  4 [31-40]   DIFICIL      - Boss: A Fortaleza Viva
TIER  3 [21-30]   DIFICIL      - Boss: O Oraculo da Loucura
TIER  2 [11-20]   NORMAL       - Boss: A Hidra das Profundezas
TIER  1 [1-10]    FACIL/NORMAL - Boss: O Guardiao do Primeiro Umbral
```

### Padrao de Cada Tier (10 andares)
| Posicao | Tipo | Funcao |
|---------|------|--------|
| Andar X1 | Variado | Andar normal |
| Andar X2 | Variado | Andar normal |
| Andar X3 | Variado | Andar normal |
| Andar X4 | Variado | Andar normal |
| **Andar X5** | **ELITE** | **Mini-boss - Portao do Tier** |
| Andar X6 | Variado | Andar normal |
| Andar X7 | Variado | Andar normal |
| Andar X8 | Variado | Andar normal |
| Andar X9 | Desafio/Gauntlet | Pre-boss |
| **Andar X0** | **BOSS** | **Boss do Tier - Recompensa massiva** |

### Tipos de Andar (10 tipos)
| Tipo | Icone | Descricao | Recursos Farmaveis |
|------|-------|-----------|-------------------|
| Combate | `[!]` | Luta direta contra criaturas | Ferro, Pedra |
| Sobrevivencia | `[~]` | Resistir a ambientes hostis | Comida, Madeira |
| Moral | `[?]` | Dilemas eticos e psicologicos | Conhecimento, Comida |
| Estrategico | `[*]` | Resolver problemas complexos | Conhecimento, Ferro |
| Misterio | `[.]` | Segredos e exploracoes | Conhecimento, Comida |
| Quebra-cabeca | `[P]` | Enigmas e logica | Conhecimento, Ferro |
| Caca | `[H]` | Rastrear e abater criaturas | Comida, Madeira |
| Desafio | `[G]` | Gauntlet de ondas/resistencia | Ferro, Pedra |
| **Elite** | `[E]` | Mini-boss a cada 5 andares | Todos + Material de Promocao |
| **BOSS** | `[X]` | Boss a cada 10 andares | Todos + Expansao + Revelacao |

---

## DETALHAMENTO POR TIER

### TIER 1 — Andares 1 a 10 | Dificuldade: FACIL → NORMAL
**O Despertar** — Os primeiros passos na Torre. Dificuldade introdutoria para aprender mecanicas.

| # | Tipo | Nome | Dif. Base | Mortalidade | Grupo Rec. | Recompensa |
|---|------|------|-----------|-------------|------------|------------|
| 1 | Sobrevivencia | Ruinas Silenciosas | 1.4 | 4% | 3 | +8 Com, +4 Mad |
| 2 | Combate | Corredor das Bestas | 1.8 | 5% | 3 | +5 Fer, +3 Ped |
| 3 | Moral | Sala dos Espelhos | 2.2 | 6% | 3 | +5 Con, +3 Moral |
| 4 | Estrategico | Labirinto Mecanico | 2.6 | 7% | 3 | +6 Con, +3 Fer |
| **5** | **ELITE** | **Guarda Avancada** | **3.9** | 8% | 3 | +4 todos, Mat. Promocao |
| 6 | Caca | Terreno de Caca | 3.4 | 8% | 3 | +8 Com, +4 Mad |
| 7 | Misterio | Biblioteca Proibida | 3.8 | 8% | 3 | +8 Con, Talento Oculto |
| 8 | Quebra-cabeca | Enigma das Runas | 4.2 | 9% | 3 | +6 Con, +3 Fer |
| 9 | Desafio | Desafio Sem Fim | 4.6 | 10% | 3 | +5 Fer, +3 Ped |
| **10** | **BOSS** | **O Guardiao do Primeiro Umbral** | **9.0** | 15% | 3 | +10 todos, Expansao |

> **Boss**: Uma entidade massiva que testa o valor da humanidade. O primeiro grande desafio.
> **Biomas**: Fungos luminosos, ratos cristalinos, bestas deformadas, fragmentos de espelho

---

### TIER 2 — Andares 11 a 20 | Dificuldade: NORMAL
**A Descida Real** — A dificuldade cresce. Mortes comecam a ser possiveis.

| # | Tipo | Nome | Dif. Base | Mortalidade | Grupo Rec. | Recompensa |
|---|------|------|-----------|-------------|------------|------------|
| 11 | Combate | Arena Sangrenta | 5.0 | 10% | 4 | +10 Fer, +6 Ped |
| 12 | Sobrevivencia | Pantano Toxico | 5.5 | 10% | 4 | +16 Com, +8 Mad |
| 13 | Quebra-cabeca | Cubo Dimensional | 6.0 | 11% | 4 | +12 Con, +6 Fer |
| 14 | Caca | Selva Noturna | 6.5 | 11% | 4 | +16 Com, +8 Mad |
| **15** | **ELITE** | **Sentinela do Tier** | **9.1** | 13% | 4 | +8 todos, Mat. Promocao |
| 16 | Moral | Tribunal dos Pecados | 7.5 | 12% | 4 | +10 Con, +6 Moral |
| 17 | Estrategico | Fortaleza das Sombras | 8.0 | 12% | 4 | +12 Con, +6 Fer |
| 18 | Misterio | Sala Vazia | 8.5 | 13% | 4 | +16 Con, Talento Oculto |
| 19 | Desafio | Maratona da Dor | 9.0 | 13% | 4 | +10 Fer, +6 Ped |
| **20** | **BOSS** | **A Hidra das Profundezas** | **16.2** | 20% | 4 | +20 todos, Expansao |

> **Boss**: Uma criatura de muitas cabecas emerge das aguas escuras. Cada cabeca guarda um segredo mortal.

---

### TIER 3 — Andares 21 a 30 | Dificuldade: DIFICIL
**O Filtro** — Mortes se tornam frequentes. Preparacao e essencial.

| # | Tipo | Nome | Dif. Base | Mortalidade | Grupo Rec. | Recompensa |
|---|------|------|-----------|-------------|------------|------------|
| 21 | Caca | Caca ao Predador | 8.6 | 13% | 5 | +24 Com, +12 Mad |
| 22 | Moral | Jardim das Memorias | 9.2 | 13% | 5 | +15 Con, +9 Moral |
| 23 | Combate | Campo de Batalha | 9.8 | 13% | 5 | +15 Fer, +9 Ped |
| 24 | Misterio | Espaco Entre Mundos | 10.4 | 14% | 5 | +24 Con, Talento Oculto |
| **25** | **ELITE** | **Portao do Meio** | **14.3** | 17% | 5 | +12 todos, Mat. Promocao |
| 26 | Sobrevivencia | Deserto de Cinzas | 11.6 | 14% | 5 | +24 Com, +12 Mad |
| 27 | Quebra-cabeca | Cifra Impossivel | 12.2 | 15% | 5 | +18 Con, +9 Fer |
| 28 | Estrategico | Tabuleiro Gigante | 12.8 | 15% | 5 | +18 Con, +9 Fer |
| 29 | Desafio | Prova de Resistencia | 13.4 | 16% | 5 | +15 Fer, +9 Ped |
| **30** | **BOSS** | **O Oraculo da Loucura** | **25.2** | 24% | 5 | +30 todos, Expansao |

> **Boss**: Um ser que enxerga alem da realidade. Seus olhos revelam verdades que destroem a mente.

---

### TIER 4 — Andares 31 a 40 | Dificuldade: DIFICIL → BRUTAL
**A Provacao** — Cada expedicao e uma aposta. Grupos fortes sao obrigatorios.

| # | Tipo | Nome | Dif. Base | Mortalidade | Grupo Rec. | Recompensa |
|---|------|------|-----------|-------------|------------|------------|
| 31 | Estrategico | Relogio de Engrenagens | 10.8 | 13% | 5 | +24 Con, +12 Fer |
| 32 | Combate | Trincheira dos Caidos | 11.6 | 13% | 5 | +20 Fer, +12 Ped |
| 33 | Caca | Trilha das Feras | 12.4 | 14% | 5 | +32 Com, +16 Mad |
| 34 | Moral | Santuario do Remorso | 13.2 | 14% | 5 | +20 Con, +12 Moral |
| **35** | **ELITE** | **Guardiao Menor** | **18.2** | 17% | 5 | +16 todos, Mat. Promocao |
| 36 | Misterio | Sonho Coletivo | 14.8 | 15% | 5 | +32 Con, Talento Oculto |
| 37 | Sobrevivencia | Floresta Petrificada | 15.6 | 15% | 5 | +32 Com, +16 Mad |
| 38 | Desafio | Corrida Mortal | 16.4 | 15% | 5 | +20 Fer, +12 Ped |
| 39 | Quebra-cabeca | Paradoxo Temporal | 17.2 | 16% | 5 | +24 Con, +12 Fer |
| **40** | **BOSS** | **A Fortaleza Viva** | **32.4** | 24% | 5 | +40 todos, Expansao |

> **Boss**: As proprias paredes estao vivas. O andar inteiro e o boss. Nao ha para onde correr.

---

### TIER 5 — Andares 41 a 50 | Dificuldade: BRUTAL
**O Abismo** — Mesmo os mais fortes podem cair. Recursos escassos, mortalidade alta.

| # | Tipo | Nome | Dif. Base | Mortalidade | Grupo Rec. | Recompensa |
|---|------|------|-----------|-------------|------------|------------|
| 41 | Misterio | Eco do Futuro | 18.8 | 19% | 6 | +40 Con, Talento Oculto |
| 42 | Desafio | Sequencia de Ondas | 19.6 | 19% | 6 | +25 Fer, +15 Ped |
| 43 | Combate | Coliseu Sombrio | 20.4 | 19% | 6 | +25 Fer, +15 Ped |
| 44 | Quebra-cabeca | Sequencia Mortal | 21.2 | 20% | 6 | +30 Con, +15 Fer |
| **45** | **ELITE** | **Teste de Elite** | **28.6** | 24% | 6 | +20 todos, Mat. Promocao |
| 46 | Caca | Covil Subterraneo | 22.8 | 20% | 6 | +40 Com, +20 Mad |
| 47 | Moral | Ponte da Escolha | 23.6 | 21% | 6 | +25 Con, +15 Moral |
| 48 | Estrategico | Maquina Infernal | 24.4 | 21% | 6 | +30 Con, +15 Fer |
| 49 | Sobrevivencia | Caverna Glacial | 25.2 | 22% | 6 | +40 Com, +20 Mad |
| **50** | **BOSS** | **O Imperador de Ferro** | **46.8** | 33% | 6 | +50 todos, Expansao |

> **Boss**: Um colossus de metal forjado em sangue de herois caidos. Cada armadura que veste foi de alguem.

---

### TIER 6 — Andares 51 a 60 | Dificuldade: BRUTAL
**O Ponto Sem Retorno** — Cada expedicionario que volta e um milagre.

| # | Tipo | Nome | Dif. Base | Mortalidade | Grupo Rec. | Recompensa |
|---|------|------|-----------|-------------|------------|------------|
| 51 | Sobrevivencia | Vulcao Adormecido | 21.0 | 18% | 6 | +48 Com, +24 Mad |
| 52 | Combate | Patio da Carnificina | 22.0 | 19% | 6 | +30 Fer, +18 Ped |
| 53 | Moral | Camera do Julgamento | 23.0 | 19% | 6 | +30 Con, +18 Moral |
| 54 | Caca | Floresta dos Lobos | 24.0 | 20% | 6 | +48 Com, +24 Mad |
| **55** | **ELITE** | **Barreira de Poder** | **32.5** | 24% | 6 | +24 todos, Mat. Promocao |
| 56 | Estrategico | Xadrez dos Deuses | 26.0 | 21% | 6 | +36 Con, +18 Fer |
| 57 | Misterio | Fragmento de Realidade | 27.0 | 21% | 6 | +48 Con, Talento Oculto |
| 58 | Quebra-cabeca | Codigo da Torre | 28.0 | 22% | 6 | +36 Con, +18 Fer |
| 59 | Desafio | Horda Infinita | 29.0 | 22% | 6 | +30 Fer, +18 Ped |
| **60** | **BOSS** | **A Rainha Venenosa** | **54.0** | 34% | 6 | +60 todos, Expansao |

> **Boss**: A floresta inteira obedece sua vontade. O veneno e tao sutil que voce nao percebe ate ser tarde.

---

### TIER 7 — Andares 61 a 70 | Dificuldade: BRUTAL → INFERNAL
**Terra Incognita** — Poucos registros existem. Cada andar e um campo desconhecido.

| # | Tipo | Nome | Dif. Base | Mortalidade | Grupo Rec. | Recompensa |
|---|------|------|-----------|-------------|------------|------------|
| 61 | Quebra-cabeca | Padroes Ocultos | 31.0 | 23% | 7 | +42 Con, +21 Fer |
| 62 | Combate | Fosso do Gladiador | 32.0 | 24% | 7 | +35 Fer, +21 Ped |
| 63 | Caca | Pantano dos Repteis | 33.0 | 24% | 7 | +56 Com, +28 Mad |
| 64 | Misterio | Limiar da Loucura | 34.0 | 25% | 7 | +56 Con, Talento Oculto |
| **65** | **ELITE** | **Desafio do Forte** | **45.5** | 30% | 7 | +28 todos, Mat. Promocao |
| 66 | Sobrevivencia | Mar de Acido | 36.0 | 26% | 7 | +56 Com, +28 Mad |
| 67 | Moral | Altar do Sacrificio | 37.0 | 26% | 7 | +35 Con, +21 Moral |
| 68 | Estrategico | Circuito do Caos | 38.0 | 27% | 7 | +42 Con, +21 Fer |
| 69 | Desafio | Combate Continuo | 39.0 | 27% | 7 | +35 Fer, +21 Ped |
| **70** | **BOSS** | **O Devorador de Almas** | **72.0** | 41% | 7 | +70 todos, Expansao |

> **Boss**: Alimenta-se de memorias e emocoes. Os mais fortes emocionalmente sao os mais vulneraveis.

---

### TIER 8 — Andares 71 a 80 | Dificuldade: INFERNAL
**O Inferno** — Mortalidade absurda. Apenas os mais preparados chegam aqui.

| # | Tipo | Nome | Dif. Base | Mortalidade | Grupo Rec. | Recompensa |
|---|------|------|-----------|-------------|------------|------------|
| 71 | Estrategico | Prisao Logica | 41.0 | 28% | 7 | +48 Con, +24 Fer |
| 72 | Sobrevivencia | Tundra Infinita | 42.5 | 28% | 7 | +64 Com, +32 Mad |
| 73 | Combate | Planicie Vermelha | 44.0 | 29% | 7 | +40 Fer, +24 Ped |
| 74 | Moral | Teatro das Sombras | 45.5 | 29% | 7 | +40 Con, +24 Moral |
| **75** | **ELITE** | **Filtro Natural** | **60.7** | 35% | 7 | +32 todos, Mat. Promocao |
| 76 | Caca | Ninho de Monstros | 36.5 | 25% | 8 | +64 Com, +32 Mad |
| 77 | Misterio | Camera Selada | 38.0 | 26% | 8 | +64 Con, Talento Oculto |
| 78 | Quebra-cabeca | Equacao do Caos | 39.5 | 26% | 8 | +48 Con, +24 Fer |
| 79 | Desafio | Escalada Brutal | 41.0 | 27% | 8 | +40 Fer, +24 Ped |
| **80** | **BOSS** | **O Arquiteto do Caos** | **75.6** | 40% | 8 | +80 todos, Expansao |

> **Boss**: Reescreve as regras do andar a cada momento. Nada e como parece. A logica e a unica arma.

---

### TIER 9 — Andares 81 a 90 | Dificuldade: INFERNAL
**O Crepusculo** — Os andares finais antes do impossivel. Lendas sao forjadas aqui.

| # | Tipo | Nome | Dif. Base | Mortalidade | Grupo Rec. | Recompensa |
|---|------|------|-----------|-------------|------------|------------|
| 81 | Misterio | Portao Invertido | 44.0 | 28% | 8 | +72 Con, Talento Oculto |
| 82 | Desafio | Teste de Limite | 45.5 | 29% | 8 | +45 Fer, +27 Ped |
| 83 | Combate | Covil do Predador | 47.0 | 30% | 8 | +45 Fer, +27 Ped |
| 84 | Quebra-cabeca | Matriz de Luz | 48.5 | 30% | 8 | +54 Con, +27 Fer |
| **85** | **ELITE** | **Muro Vivo** | **65.0** | 36% | 8 | +36 todos, Mat. Promocao |
| 86 | Caca | Savana Perigosa | 51.5 | 31% | 8 | +72 Com, +36 Mad |
| 87 | Moral | Lagrimas do Passado | 53.0 | 32% | 8 | +45 Con, +27 Moral |
| 88 | Estrategico | Dimensao Geometrica | 54.5 | 32% | 8 | +54 Con, +27 Fer |
| 89 | Sobrevivencia | Abismo Sem Fundo | 56.0 | 33% | 8 | +72 Com, +36 Mad |
| **90** | **BOSS** | **A Sombra Primordial** | **102.6** | 50% | 8 | +90 todos, Expansao |

> **Boss**: A encarnacao do medo coletivo de todos que morreram na Torre. Cada heroi caido fortalece a Sombra.

---

### TIER 10 — Andares 91 a 100 | Dificuldade: IMPOSSIVEL
**Ascensao** — O topo da Torre. A verdade final. Pouquissimos chegam aqui.

| # | Tipo | Nome | Dif. Base | Mortalidade | Grupo Rec. | Recompensa |
|---|------|------|-----------|-------------|------------|------------|
| 91 | Sobrevivencia | Tempestade Eterna | 59.0 | 35% | 8 | +80 Com, +40 Mad |
| 92 | Combate | Fronteira da Morte | 60.5 | 35% | 8 | +50 Fer, +30 Ped |
| 93 | Moral | Porta da Verdade | 62.0 | 36% | 8 | +50 Con, +30 Moral |
| 94 | Caca | Toca do Dragao | 63.5 | 37% | 8 | +80 Com, +40 Mad |
| **95** | **ELITE** | **Portao Blindado** | **84.5** | 44% | 8 | +40 todos, Mat. Promocao |
| 96 | Misterio | Nexus Temporal | 66.5 | 38% | 8 | +80 Con, Talento Oculto |
| 97 | Estrategico | Dimensao Geometrica | 68.0 | 38% | 8 | +60 Con, +30 Fer |
| 98 | Desafio | Ultimo Suspiro | 69.5 | 39% | 8 | +50 Fer, +30 Ped |
| 99 | Quebra-cabeca | Quebra-cabeca Final | 71.0 | 40% | 8 | +60 Con, +30 Fer |
| **100** | **BOSS** | **TEL - A Criadora do Jogo** | **130.5** | 60% | 8 | +100 todos, Ascensao |

> **Boss Final**: A mente por tras de tudo. Ela criou este jogo. Ela observa. E agora, ela luta.
> **Mortalidade 60%**: Espere perder metade ou mais do grupo. E o desafio definitivo.

---

## FORMULAS DE ESCALAMENTO

### Dificuldade Base por Faixa
| Faixa | Formula | Resultado |
|-------|---------|-----------|
| 1-5 | 1.0 + andar * 0.4 | 1.4 - 3.0 |
| 6-15 | 2.0 + (andar-5) * 0.5 | 2.5 - 7.0 |
| 16-30 | 5.0 + (andar-15) * 0.6 | 5.6 - 14.0 |
| 31-50 | 10.0 + (andar-30) * 0.8 | 10.8 - 26.0 |
| 51-75 | 20.0 + (andar-50) * 1.0 | 21.0 - 45.0 |
| 76-100 | 35.0 + (andar-75) * 1.5 | 36.5 - 72.5 |

### Multiplicadores
| Tipo | Dificuldade | Mortalidade |
|------|-------------|-------------|
| Boss (a cada 10) | x1.8 | x1.5 |
| Elite (a cada 5) | x1.3 | x1.2 |
| Normal | x1.0 | x1.0 |

### Modificadores de Tier
- **Dificuldade escalonada**: `baseDiff * (1.0 + (tier-1) * 0.4) * easyMod`
- **Mortalidade escalonada**: `baseMort * (1.0 + (tier-1) * 0.25) * easyMod` (clamp 0-85%)
- **Andares 1-2**: easyMod = 0.6 dificuldade / 0.3 mortalidade
- **Andares 3-5**: easyMod = 0.8 dificuldade / 0.6 mortalidade

### Grupo Recomendado
| Faixa de Andares | Tamanho |
|------------------|---------|
| 1-5 | 3 membros |
| 6-15 | 4 membros |
| 16-30 | 5 membros |
| 31-50 | 6 membros |
| 51-75 | 7 membros |
| 76-100 | 8 membros |

### Poder Recomendado
`scaledDifficulty * 1.5 + (andar * 0.3)`

### Tags de Dificuldade
| Faixa | Tag |
|-------|-----|
| 1-5 | Facil |
| 6-15 | Normal |
| 16-30 | Dificil |
| 31-50 | Brutal |
| 51-75 | Infernal |
| 76-100 | Impossivel |

---

## RE-EXPLORACAO DE ANDARES

Andares conquistados podem ser revisitados para farming de recursos. Os recursos escalam com o Tier:

### Recursos Farmaveis por Tipo e Tier
| Tipo | Recurso 1 | Recurso 2 | Formula |
|------|-----------|-----------|---------|
| Combate / Desafio | Ferro | Pedra | Fer: 3+T*2, Ped: 2+T |
| Sobrevivencia / Caca | Comida | Madeira | Com: 5+T*3, Mad: 3+T*2 |
| Estrategico / Quebra-cabeca | Conhecimento | Ferro | Con: 4+T*3, Fer: 2+T |
| Moral | Conhecimento | Comida | Con: 3+T*2, Com: 3+T |
| Misterio | Conhecimento | Comida | Con: 5+T*3, Com: 2+T |
| Elite | Ferro | Conhecimento | Fer: 5+T*3, Con: 3+T*2 |
| Boss | Todos | - | Cada: 5+T*2 |

*(T = Tier do andar, 1-10)*

### Dificuldade de Re-Exploracao
- Base: 50% da dificuldade escalonada do andar
- Aumenta 6% por re-exploracao anterior
- Maximo 20 re-exploracoes por andar

### Riscos
- **Ameaca oculta**: 5% base + 2% por re-exploracao anterior
- **Novas criaturas**: Podem surgir e causar baixas
- **Descobertas**: 10% chance de recurso raro (+5 conhecimento)

---

## BIOMAS (Ciclo de 15 biomas)

| Bioma # | Descricao |
|---------|-----------|
| 1 | Fungos luminosos, ratos cristalinos, ervas raras |
| 2 | Bestas deformadas, couro resistente, ossos de criatura |
| 3 | Fragmentos de espelho, essencia psiquica, nevoa mental |
| 4 | Engrenagens antigas, metal raro, oleo mecanico |
| 5 | Arenas sangrentas, trofeus de gladiador |
| 6 | Plantas toxicas, ambar pantanoso, raizes curativas |
| 7 | Pergaminhos antigos, tinta magica, runas |
| 8 | Cristais de julgamento, essencia de verdade |
| 9 | Sombras solidificadas, metal sombrio |
| 10 | Fragmentos primordiais, reliquia ancestral |
| 11 | Cristais de mana, bestas elementais |
| 12 | Flora carnivora, esporos venenosos |
| 13 | Golems de pedra, metais encantados |
| 14 | Espiritos errantes, fragmentos de alma |
| 15 | Magma solidificado, salamandras de fogo |

*Biomas se repetem ciclicamente: andar 16 usa bioma 1, andar 17 usa bioma 2, etc.*

---

## CONDICOES ESPECIAIS

Andares podem ter condicoes especiais aleatorias que afetam a expedição:

| Condicao | Efeito |
|----------|--------|
| Visibilidade reduzida | Combate penalizado |
| Espaco estreito | Grupo grande perde efetividade |
| Teste de Estabilidade Mental | Risco de colapso mental |
| Requer INT > 6 no lider | Lider deve ser inteligente |
| Sem fuga possivel | Grupo nao pode recuar |
| Dano continuo | Recursos de cura essenciais |
| Risco de perda de sanidade | Sanidade mental cai |
| Revela traicoes ocultas | Traidores podem ser expostos |
| Tempo limitado | Velocidade e eficiencia importam |
| Gravidade invertida | Mobilidade reduzida |
| Veneno no ar | Dano passivo constante |
| Escuridao total | Sem visao, combate cego |
| Silencio absoluto | Comunicacao impossivel |
| Ilusoes constantes | Aliados podem atacar aliados |
| Terreno instavel | Risco de queda |
| Frio extremo | Resistencia cai rapido |
| Calor sufocante | Fadiga acelerada |
| **BOSS - Requer preparacao maxima** | Apenas bosses |
| **ELITE - Mini-boss antes do Boss** | Apenas elites |

---

## SISTEMA DE LEALDADE

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

## SISTEMA DE TRAICAO

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

## SISTEMA DE SUGESTAO DE TREINO

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

## SISTEMA DE GRUPOS/ESQUADROES

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

## CIDADELA — SISTEMA DE CONSTRUCAO MANUAL

O jogador escolhe **manualmente** o que construir. NPCs reagem narrativamente a cada construcao.

### Niveis de Evolucao da Cidadela

| Nivel | Nome | Max Edificios | Pop. Necessaria | Tier Torre Min. | Custo de Evolucao |
|-------|------|:---:|:---:|:---:|---|
| 1 | Abrigo | 3 | 0 | 0 | - |
| 2 | Acampamento | 5 | 8 | 0 | 50 Mad, 30 Ped, 30 Com |
| 3 | Vila | 8 | 15 | 1 | 80 Mad, 60 Ped, 10 Fer, 10 Con |
| 4 | Povoado | 11 | 22 | 2 | 120 Mad, 100 Ped, 30 Fer, 25 Con |
| 5 | Cidade | 15 | 30 | 3 | 180 Mad, 150 Ped, 60 Fer, 50 Con |
| 6 | Fortaleza | 19 | 40 | 4 | 300 Mad, 250 Ped, 100 Fer, 80 Con |
| 7 | Cidadela | 23 | 55 | 5 | 500 Mad, 400 Ped, 200 Fer, 150 Con |
| 8 | Reino | 27 | 75 | 6 | 800 Mad, 600 Ped, 350 Fer, 250 Con |
| 9 | Imperio | 32 | 100 | 8 | 1200 Mad, 1000 Ped, 600 Fer, 500 Con |
| 10 | Ascendido | 40 | 150 | 10 | 2000 Mad, 1800 Ped, 1000 Fer, 800 Con |

### Edificios — 25 Tipos em 7 Categorias

#### Essencial (Tier 0 — Disponiveis desde o inicio)
| Edificio | Custo | Efeito |
|----------|-------|--------|
| Fogueira | Mad: 5 | +1 moral/dia, centro social |
| Tenda | Mad: 10 | +5 capacidade populacao |
| Fazenda | Mad: 15, Ped: 5 | +5 comida/dia |
| Armazem | Mad: 15, Ped: 10 | +50% capacidade recursos |

#### Producao (Desbloqueio: Tier 1)
| Edificio | Custo | Efeito |
|----------|-------|--------|
| Cozinha | Mad: 10, Ped: 5 | +3 comida/dia por chef |
| Oficina | Mad: 20, Ped: 15, Fer: 5 | Produz equipamentos, +1 ferro/dia |
| Forja | Ped: 25, Fer: 15, Con: 5 | +2 ferro/dia, armas melhores (+10% poder combate) |

#### Conhecimento (Desbloqueio: Tier 1-2)
| Edificio | Custo | Efeito |
|----------|-------|--------|
| Escola | Mad: 15, Ped: 10, Con: 10 | +1 conhecimento/dia, treina jovens |
| Enfermaria | Mad: 15, Ped: 10, Con: 5 | Cura feridos, -30% mortes em expedicoes |
| Biblioteca | Mad: 20, Ped: 15, Con: 15 | +3 conhecimento/dia, revela mecanicas ocultas |

#### Militar (Desbloqueio: Tier 2)
| Edificio | Custo | Efeito |
|----------|-------|--------|
| Quartel | Mad: 25, Ped: 20, Fer: 10 | Treina guardas, +0.3 FOR soldados/dia |
| Campo de Treino | Mad: 25, Ped: 20, Fer: 10, Con: 10 | Treino seguro (-95% morte), evolucao lenta |
| Muralha | Ped: 30, Fer: 10 | -20% risco de ameacas externas |
| Torre de Vigia | Mad: 15, Ped: 25, Fer: 5 | Alerta antecipado, detecta traidores +15% |

#### Social/Politico (Desbloqueio: Tier 3)
| Edificio | Custo | Efeito |
|----------|-------|--------|
| Taverna | Mad: 30, Ped: 15, Com: 10 | Centro social: +relacoes, revela fofocas e traidores |
| Mercado | Mad: 20, Ped: 15 | Troca de recursos, +5% eficiencia geral |
| Templo | Ped: 30, Mad: 20, Con: 20 | +2 moral/dia, +0.5 sanidade/dia para todos |

#### Avancados (Desbloqueio: Tier 4-5)
| Edificio | Custo | Efeito |
|----------|-------|--------|
| Arena | Ped: 40, Fer: 25, Mad: 20 | Duelos entre NPCs, resolve conflitos, +combate |
| Sala do Conselho | Mad: 35, Ped: 30, Con: 20 | Votacoes politicas, resolve crises democraticamente |
| Camara de Sintese | Fer: 40, Con: 30, Ped: 25 | Combina materiais dos andares em itens raros |
| Sala de Promocao | Con: 50, Fer: 30, Ped: 30 | Promove NPCs: muda rank, desbloqueia habilidades |

#### Endgame (Desbloqueio: Tier 6-9)
| Edificio | Custo | Efeito |
|----------|-------|--------|
| Sala de Guerra | Fer: 60, Ped: 40, Con: 40 | +25% chance sucesso em expedicoes, estrategia global |
| Lab. Alquimico | Con: 80, Fer: 50, Ped: 30 | Cria pocoes e itens especiais de recursos raros |
| Monumento | Ped: 100, Fer: 50, Con: 50, Mad: 50 | +5 moral/dia, simbolo de poder, +lealdade geral |
| Nexus da Torre | Con: 150, Fer: 80, Ped: 80 | Conexao com a Torre: -10% dificuldade, +visao dos andares |

> Todos os edificios podem ser melhorados ate nivel 5 (custo = base * nivel * 1.5)

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

## TELAS DA INTERFACE

1. **Observatorio** - Dashboard com status geral, alertas, controles de tempo
2. **Torre** - Mapa visual dos 100 andares segmentados por Tier, proximo desafio, re-exploracao, resultados
3. **Cidadela** - Recursos, construcao manual de edificios (7 categorias), evolucao
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
- **Conquistar 100 andares** com dificuldade que escala de Facil a Impossivel
- **Construir e evoluir** a cidadela manualmente de Abrigo a Ascendido

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

---

## CHANGELOG

### v5.0 — Sistema de Expedicao Hardcore + Armazem Reformulado

#### Sistema de Expedicao Hardcore (Redesign Completo)

O sistema de expedicao foi reformulado para ser **punitivo, estrategico e consequente**.
Decisoes mal calculadas geram **prejuizo real e irreversivel**.

##### Estrutura da Expedicao
A expedicao e calculada com base em:
- **Numero de NPCs enviados** (custo fixo por cabeca)
- **Status individuais** de cada NPC (fadiga, sanidade, lealdade)
- **Personalidade e Traits** de cada membro
- **Sinergia entre membros** (grupos coesos rendem mais)
- **Nivel de risco do andar** (tier determina custo e chance de eventos)

##### Custo da Expedicao (Reformulado)
- Custo pago **ANTES**, independente do resultado
- Formula: `custo_total = num_npcs * (3.0 + tier * 1.0)`
  - Tier 1: 4.0 comida/NPC | Tier 5: 8.0/NPC | Tier 10: 13.0/NPC
- Re-exploracao: `custo = 2.0 + tier * 0.6` (mais barata, mas sem bonus de conquista)
- **Nao ha reembolso**. Voce paga e assume o risco.

##### Formula de Recompensa
```
recompensa_npc = base_recurso * yield_atributos * multiplicador_personalidade
recompensa_total = soma_npcs * (1 + sinergia_grupo) * variancia_aleatoria
```

- `yield_atributos` = forca (+5%), inteligencia (+4%), resistencia (+2.5%), agilidade (+2.5%), sorte (+2.5%) — calculado acima de 5 pontos base
- `multiplicador_personalidade` = modificador por traits (-20% a +15%)
- `sinergia_grupo` = -30% a +60% baseado em relacoes e traits de grupo
- `variancia_aleatoria` = -15% a +15% de randomizacao

**Regra do NPC Solo**: Enviar 1 NPC nunca e totalmente inutil (recompensa minima = 50% do custo).
**Composicao Ruim**: Grupos com individualistas, preguicosos e sem sinergia podem dar prejuizo. Design intencional.

##### Influencia dos Atributos na Coleta
| Atributo | Impacto na Expedicao |
|----------|---------------------|
| **Forca** | +5% por ponto acima de 5. Dominante em andares de combate |
| **Inteligencia** | +4% por ponto. Reduce desperdicio. Dominante em andares estrategicos |
| **Resistencia** | +2.5% por ponto. Reduz penalidade de fadiga e acidentes |
| **Agilidade** | +2.5% por ponto. Eficiencia geral de coleta |
| **Sorte** | +2.5% por ponto. Aumenta chance de eventos raros positivos |

##### Personalidades (Impacto Real na Coleta)
| Trait | Modificador | Efeito Adicional |
|-------|------------|-----------------|
| **Ambicioso** | +15% recompensa | +2% risco de acidente |
| **Analitico** | +6% | Reduz perdas por erro |
| **Pragmatico** | +4% | Estavel, sem surpresas |
| **Bravo** | +5% | Aceita missoes de alto risco |
| **Cauteloso** | -12% (teto menor) | -2% chance de acidente |
| **Calmo** | -5% | Mais previsivel |
| **Preguicoso** | -20% eficiencia | Penalidade severa no yield |
| **Covarde** | -10% | Evita confrontos |
| **Pessimista** | -5% | |
| **Individualista** | -5% + reduz sinergia | Penaliza bonus de grupo |
| **Leal** | +5% sinergia do grupo | |
| **Lider** | +10% sinergia (se unico lider) | Conflito com outros lideres |

##### Sinergia de Grupo
```
sinergia_base = 0.0
+ grupo_coeso (todos mesmo grupo): ate +40% (baseado em coesao)
+ relacoes positivas: +3% por par (max +20%)
+ Leal: +5% por membro
+ Lider (1): +10%  |  Lider (2+): -5% (conflito)
- Solitario: -8% por membro
- Individualista: -10% por membro  
- Lideres demais: -5%
- relacoes negativas: -5% por par (max -30%)
+ NaturalLeader (talento): +15% bonus
```
**Sinergia real**: -30% a +60% no total de recursos coletados.

##### Eventos Aleatorios em Expedicoes
| Evento | Chance Base | Efeito |
|--------|-------------|--------|
| **Acidente** | 12% + tier*1% | -comida extra, -RES, +fadiga |
| **Doenca** | 6% + tier*0.5% | NPC retorna debilitado |
| **Conflito Interno** | 8% (+5%/agressivo) | -20 a -40% da recompensa |
| **Traicao** | 4% (so suspeitos) | -15 a -40% roubado |
| **Evento Raro** | 5% + luck*0.5% | Recompensa DOBRADA |

**Resistencia reduz acidentes**: Alta RES media do grupo = menor chance e severidade.
**Cautelosos reduzem risco**: -2% de acidente por membro Cauteloso.
**Ambiciosos aumentam risco**: +2% de acidente por membro Ambicioso.
**Sorte aumenta eventos raros**: Grupos com alta Sorte tem mais descobertas excepcionais.

##### Analise de Risco na UI
O dialog de selecao de expedicao agora exibe:
- **Sinergia prevista** do grupo selecionado
- **Modificador de personalidade** medio
- **Yield de atributos** medio estimado
- **Chances de eventos** negativos e positivos
- **Alertas visuais** para NPCs suspeitos, preguicosos, exaustos
- **Avaliacao de risco** (Vantagem / Equilibrado / Arriscado / Perigoso / Suicida)
- **Custo fixo** destacado antes da confirmacao

---

#### Sistema de Armazem (Reformulado)

**Regra fundamental**: E **impossivel** armazenar acima da capacidade maxima.
Se o estoque estiver cheio, o excedente e **perdido permanentemente**. Sem excecoes.

##### Niveis de Armazem
| Nivel | Capacidade por Recurso | Custo de Upgrade | Tier Torre Requerido |
|-------|----------------------|-----------------|---------------------|
| Sem Armazem | **30** | Madeira:15, Pedra:10 | 0 |
| Armazem Basico | **60** | Madeira:40, Pedra:30, Ferro:10 | 0 |
| Armazem Expandido | **120** | Madeira:80, Pedra:60, Ferro:30, Conhecimento:15 | 2 |
| Grande Armazem | **250** | Ferro:80, Pedra:100, Conhecimento:60, Madeira:60 | 5 |
| **Armazem Espacial** | **INFINITO** | Ferro:80, Pedra:80, Conhecimento:60 | 9 |

**Armazem Espacial**: Marco de progressao final. Extremamente dificil de alcancar (Tier 9 da Torre necessario). Representa a vitoria economica completa.

##### Comportamento de Overflow
1. Recursos sao produzidos ou coletados normalmente
2. Ao final de cada ciclo de processamento: `clampToCapacity()` e chamado
3. Qualquer quantidade **acima da capacidade e cortada e registrada como perdida**
4. Um evento `ARMAZEM CHEIO!` e gerado com detalhes do que foi perdido
5. **Nao ha como recuperar recursos perdidos por overflow**

##### UI do Armazem (Cidadela)
- **Barra de uso geral**: Indicador visual de quanto do armazem esta ocupado
- **Por recurso**: `valor/capacidade [%]` com indicador `[MAX]` quando cheio
- **Codigo de cores**: Verde (OK) → Amarelo (>60%) → Laranja (>80%) → Vermelho (cheio)
- **Alerta urgente**: Quando cheio, banner vermelho prominente "ARMAZEM CHEIO! Recursos PERDIDOS"
- **Progressao visual**: Todos os niveis mostrados em linha com o nivel atual destacado

---

### v4.0 — Sistema de Fadiga + Consequencias Fisicas
- **Sistema de Fadiga (0-100)**: NPCs acumulam fadiga em expedicoes, re-exploracoes e treinos
- **5 estados de fadiga**: Descansado, Levemente cansado, Cansado, Exausto, Incapacitado
- **Penalidade de combate**: Cansado (-15%), Exausto (-35%), Incapacitado (-60%)
- **Fadiga por atividade**: Expedicao (20-35), Re-exploracao (15-25), Treino andar (12-22), Campo (8), Autonomo (6)
- **Consecutividade penalizada**: Cada expedicao extra no mesmo dia adiciona +8-10 fadiga bonus
- **Cascata de consequencias**: Exaustao -> perda de sanidade (-3/dia) e lealdade (-0.5/dia)
- **Incapacitado**: Profissao forcada a Ocioso, bloqueado de expedicoes, 8% chance/dia de colapso fisico
- **Recuperacao diaria**: 15-25 base (+RES) | Enfermaria +5 | Templo +3 | Parceiro +2 | Grupo +1
- **Narrativa**: Alertas contextuais quando NPCs sao forcados exaustos
- **UI**: Barra de fadiga em detalhes do NPC, indicadores na selecao de expedicao/re-exploracao
- **Filtro**: Novo filtro "EXAUSTOS" e ordenacao por fadiga na lista de NPCs
- **Grupos**: Fadiga media e contagem de exaustos exibidos por grupo
- NPCs incapacitados automaticamente removidos da selecao de expedicoes
- NPCs exaustos recusam sugestoes de treino com dialogo contextual
- Treino autonomo respeita limite de fadiga (nao treina acima de 60%)
- Auto-torre respeita fadiga (nao envia NPCs cansados automaticamente)

### v3.0 — 100 Andares + Construcao Manual
- Torre expandida de 10 para **100 andares** (10 tiers de 10 andares)
- 10 tipos de andar: Combate, Sobrevivencia, Moral, Estrategico, Misterio, Quebra-cabeca, Caca, Desafio, Elite, Boss
- Boss a cada 10 andares (10 bosses unicos com nomes e descricoes)
- Elite (mini-boss) a cada 5 andares
- Dificuldade escalona de Facil (1-5) a Impossivel (76-100)
- Sistema de construcao **100% manual** (25 tipos de edificios em 7 categorias)
- Edificios avancados: Arena, Taverna, Camara de Sintese, Sala de Promocao, Sala do Conselho
- Edificios endgame: Laboratorio Alquimico, Sala de Guerra, Monumento, Nexus
- Cidadela evolui em 10 niveis (Abrigo → Ascendido), vinculada ao tier da Torre
- Edificios podem ser melhorados ate nivel 5
- Arena: duelos semanais entre NPCs
- Taverna: fofocas que revelam traidores
- Icone personalizado do app (torre gotica)
- Removido auto-build/auto-upgrade

### v2.0 — Sistema de Lealdade + Traicao
- Sistema de lealdade (0-100) com impacto em aceitacao de treinos
- Sistema de traicao com origens obscuras
- Sistema de sugestao de treino com respostas dos NPCs
- Sistema de grupos/esquadroes
- Re-exploracao de andares para farming
- 24 tipos de eventos

### v1.0 — MVP Inicial
- 10 andares, 15 NPCs
- Cidadela basica, 16 edificios
- Sistema de tempo continuo 2:1
- Permadeath, invocacao emergencial
