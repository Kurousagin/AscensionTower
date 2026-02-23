# Mapa de Mecânicas do Código - Ascension Tower

> **Guia de referência rápida**: Onde encontrar cada mecânica no código

---

## 📋 Índice Rápido
- [Modelos de Dados](#-modelos-de-dados)
- [Sistema de NPCs](#-sistema-de-npcs)
- [Cidadela e Construções](#-cidadela-e-construções)
- [Torre e Exploração](#-torre-e-exploração)
- [Grupos e Expedições](#-grupos-e-expedições)
- [Sistema de Eventos](#-sistema-de-eventos)
- [Engine do Jogo](#-engine-do-jogo---game_enginedart)
- [Provider e Estado](#-provider-e-estado)
- [Telas (UI)](#-telas-ui)
- [Serviços](#-serviços)
- [Widgets e Tema](#-widgets-e-tema)

---

## 📦 Modelos de Dados

### `lib/models/npc.dart`
**O que contém:**
- ✅ Modelo `Npc` (atributos, profissões, traits, talentos)
- ✅ `NpcAttributes` (força, agilidade, inteligência, resistência, carisma, sanidade, sorte)
- ✅ `NpcOrigin` (12 origens: farmer, builder, scholar, etc.)
- ✅ `Profession` (14 profissões: guard, farmer, scribe, blacksmith, etc.)
- ✅ `PersonalityTrait` (12 traços: brave, coward, leader, lazy, etc.)
- ✅ `HiddenTalent` (11 talentos ocultos: combatGenius, forgemaster, etc.)
- ✅ `MentalCondition` (5 estados: stable, anxious, traumatized, broken, numb)
- ✅ `GrowthStage` (4 estágios: baby, child, adolescent, adult)
- ✅ `Relationship` (relacionamentos entre NPCs)
- ✅ `NpcNameGenerator` (geração de nomes com API + fallback local)
- ✅ Geração aleatória de NPCs (`Npc.generateRandom()`)
- ✅ Cálculo de poder de combate (`combatPower` getter)
- ✅ Sistema de fadiga e expedições consecutivas
- ✅ Sistema de marcas psicológicas e traumas
- ✅ Sistema de gravidez e nutrição maternal
- ✅ Sistema de ociosidade (`daysIdle`)
- ✅ Serialização JSON completa

**Onde mexer para:**
- Adicionar novo atributo → Linha ~100-120 (`NpcAttributes`)
- Adicionar nova profissão → Linha ~134-150 (`Profession enum`)
- Adicionar novo talento → Linha ~298-343 (`HiddenTalent`)
- Modificar cálculo de combate → Linha ~600-650 (`combatPower`)
- Alterar geração de nomes → Linha ~437-480 (`NpcNameGenerator`)

---

### `lib/models/citadel.dart`
**O que contém:**
- ✅ Modelo `Citadel` (nível, edifícios, recursos)
- ✅ `Resources` (food, wood, stone, iron, knowledge, morale)
- ✅ `Building` (tipo, tier de evolução)
- ✅ `BuildingType` (20 tipos: farm, forge, temple, arena, etc.)
- ✅ Sistema de capacidade de armazém (storage levels 0-4)
- ✅ Cálculo de custos de construção
- ✅ Cálculo de custos de upgrade da cidadela
- ✅ Evolução automática de edifícios (nomes por tier)
- ✅ Descrições de edifícios por tier
- ✅ Sistema de overflow de recursos (hardcore)
- ✅ Produção diária de edifícios

**Onde mexer para:**
- Adicionar novo edifício → Linha ~23-50 (`BuildingType enum`)
- Alterar custos de construção → Linha ~92-153 (`buildingCost()`)
- Modificar capacidade armazém → Linha ~184-197 (`storageCapacity`)
- Alterar nomes de edifícios evoluídos → Linha ~535-620 (`buildingName()`)
- Ajustar descrições de edifícios → Linha ~623-760 (`buildingDescription()`)

---

### `lib/models/tower.dart`
**O que contém:**
- ✅ Modelo `TowerFloor` (número, tipo, dificuldade, recompensas)
- ✅ `FloorType` (8 tipos: combat, survival, strategic, mystery, etc.)
- ✅ `TowerChallenge` (resultado de expedição)
- ✅ `FloorExplorationResult` (resultado de re-exploração)
- ✅ Geração procedural de 100 andares (`generateMvpFloors()`)
- ✅ Sistema de tiers (1-10, cada 10 andares)
- ✅ Boss floors (múltiplos de 10)
- ✅ Elite floors (múltiplos de 5) 
- ✅ Recursos farmáveis por tipo de andar
- ✅ Mortalidade escalada por tier
- ✅ Condições especiais de andares
- ✅ Sistema de re-exploração (treino e coleta)

**Onde mexer para:**
- Adicionar novo tipo de andar → Linha ~6-17 (`FloorType enum`)
- Modificar geração de andares → Linha ~132-380 (`generateMvpFloors()`)
- Ajustar dificuldade por tier → Linha ~154-164 (lógica de mortality)
- Alterar recursos farmáveis → Linha ~216-251 (`_farmableResources()`)
- Mudar descrições de andares → Linha ~390-470 (`description` getter)

---

### `lib/models/game_event.dart`
**O que contém:**
- ✅ Modelo `GameEvent` (tipo, título, descrição, dia, NPCs envolvidos)
- ✅ `GameEventType` (20 tipos: death, birth, betrayal, discovery, etc.)
- ✅ Sistema de eventos maiores (`isMajor`)
- ✅ Serialização JSON

**Onde mexer para:**
- Adicionar novo tipo de evento → Linha ~5-30 (`GameEventType enum`)

---

### `lib/models/group_model.dart`
**O que contém:**
- ✅ Modelo `NpcGroup` (ID, nome, membros, líder, papel)
- ✅ `GroupRole` (expedition, training, resource, defense)
- ✅ Sistema de baixas e missões completas
- ✅ Serialização JSON

**Onde mexer para:**
- Adicionar novo papel de grupo → Linha ~20-26 (`GroupRole enum`)

---

## 👥 Sistema de NPCs

### Atributos e Stats
📁 **Arquivo:** `lib/models/npc.dart` (linhas 100-130)
- Força, Agilidade, Inteligência, Resistência, Carisma
- Sanidade Mental (20-100)
- Sorte (1-15)

### Profissões
📁 **Arquivo:** `lib/models/npc.dart` (linhas 134-150)
📁 **Lógica:** `lib/services/game_engine.dart` (linhas 2003-2032)
- 14 profissões disponíveis
- Treinamento diário por profissão
- Escolha autônoma de profissão (linha 595-752 em game_engine)

### Traços de Personalidade
📁 **Arquivo:** `lib/models/npc.dart` (linhas 152-167)
📁 **Uso:** Espalhado por `game_engine.dart`
- Brave, Coward, Leader, Lazy, Ambitious, etc.
- Afeta decisões, lealdade, traições

### Talentos Ocultos
📁 **Arquivo:** `lib/models/npc.dart` (linhas 298-343)
📁 **Ativação:** `lib/services/game_engine.dart` (linhas 2612-2636)
- 11 talentos raros (15% de chance ao nascer)
- Descoberta em eventos específicos
- **Implementados:**
  - combatGenius: `game_engine.dart:2315` (+50% poder)
  - healingTouch: `game_engine.dart:2318-2329` (cura pós-batalha)
  - strategicMind: `game_engine.dart:1013-1016` (-15% mortalidade)
  - naturalLeader: `game_engine.dart:1020-1023` (+15% sinergia)
- **Não implementados ainda:**
  - forgemaster, herbalist, runeReader, shadowWalker, ironWill, beastWhisperer

### Sistema de Fadiga
📁 **Arquivo:** `lib/models/npc.dart` (linhas ~540)
📁 **Processamento:** `lib/services/game_engine.dart` (linhas 298-314)
- Acúmulo em expedições (10-30 fadiga)
- Expedições consecutivas aumentam fadiga
- Recuperação diária: 15 base, +15 se Infirmary

### Sistema de Ociosidade
📁 **Arquivo:** `lib/models/npc.dart` (linha ~527 - campo `daysIdle`)
📁 **Processamento:** `lib/services/game_engine.dart` (linhas 487-586)
- NPCs sem profissão acumulam dias ociosos
- Penalidades progressivas (7/14/21 dias)
- Eventos narrativos a cada 7 dias após 21 dias
- Personalidade afeta penalidades (lazy -40%, ambitious +30%)

### Escolha Autônoma de Profissão
📁 **Lógica completa:** `lib/services/game_engine.dart` (linhas 595-752)
- Avaliação a cada 3 dias
- Chance base 15%, até 80% para ambitious com muitos dias idle
- Weighted selection baseado em atributos + necessidades da cidadela
- Matching inteligente (ex-farmer → farmer)

### Gravidez e Nascimento
📁 **Processamento:** `lib/services/game_engine.dart` (linhas 1716-1780)
- Casais formam relacionamentos
- Gravidez dura 2 dias
- Risco de morte no parto (baseado em nutrição maternal)
- Bebês herdam atributos dos pais + variação genética

### Mortalidade Infantil
📁 **Processamento:** `lib/services/game_engine.dart` (linhas 1782-1845)
- Mortalidade infantil baseada em:
  - Comida per capita
  - NPCs doentes na cidadela
  - Nutrição maternal
- Infirmary reduz mortalidade

### Envelhecimento e Morte Natural
📁 **Processamento:** `lib/services/game_engine.dart` (linhas 1960-1977)
- Ganho de atributos (18-25 anos)
- Perda de atributos (60+ anos)
- 2% chance de morte aos 60+

### Saúde Mental
📁 **Processamento:** `lib/services/game_engine.dart` (linhas 316-450)
- 5 estados mentais (stable → numb)
- Perda de sanidade por fome, trauma, eventos
- Recuperação com Temple (+1/dia), moral alto, eventos positivos
- Surtos mentais quando sanity < 20 (4 tipos de surto)

### Lealdade e Traições
📁 **Processamento:** `lib/services/game_engine.dart` (linhas 452-485, 756-859)
- Lealdade afetada por: comida, moral, salário, eventos
- Tentativas de traição quando loyalty < 30
- 4 tipos de traição:
  1. Roubo de recursos
  2. Sabotagem de moral
  3. Rebelião (destroy supplies)
  4. Assassinato (apenas assassins)

---

## 🏰 Cidadela e Construções

### Recursos
📁 **Modelo:** `lib/models/citadel.dart` (linhas 9-21)
📁 **Gestão:** `lib/services/game_engine.dart` (linhas 186-228)
- 6 recursos: Food, Wood, Stone, Iron, Knowledge, Morale
- Consumo diário: 1.5 comida/NPC
- Overflow perdido permanentemente (hardcore)

### Armazém e Capacidade
📁 **Modelo:** `lib/models/citadel.dart` (linhas 184-207)
📁 **Uso:** `lib/services/game_engine.dart` (linhas 186-195)
- Level 0: 30 cap
- Level 1: 60 cap
- Level 2: 120 cap
- Level 3: 250 cap
- Level 4: Infinito

### Construção de Edifícios
📁 **UI:** `lib/screens/citadel_screen.dart` (linhas 300-550)
📁 **Backend:** `lib/providers/game_provider.dart` (linhas 185-220)
📁 **Custos:** `lib/models/citadel.dart` (linhas 92-153)
- 20 tipos de edifícios
- Tier requirements (citadel level)
- Reações de NPCs: `game_engine.dart:2553-2654`

### Evolução de Edifícios
📁 **Lógica:** `lib/services/game_engine.dart` (linhas 2680-2710)
📁 **Nomes:** `lib/models/citadel.dart` (linhas 535-620)
- Automatic upgrade com citadel level
- Edifícios evoluem: tent, farm, firepit
- Nomes dinâmicos por tier

### Ocultação de Edifícios Obsoletos
📁 **Lógica:** `lib/services/game_engine.dart` (linhas 2362-2395)
- Se existe versão evoluída (tier > 0), esconde tier 0
- Exemplo: Casa (tier 1) esconde Tenda (tier 0)

### Produção Diária de Edifícios
📁 **Processamento:** `lib/services/game_engine.dart` (linhas 230-276)
- Farm: 5/12/25 food by tier
- Workshop: iron + wood
- Forge: iron (+ weapons description - não implementado)
- Kitchen: food per chef
- Library: knowledge
- School: knowledge
- Barracks: treino de atributos
- Firepit: moral scaling (1/2/3/5)
- Temple: moral + mental stability
- Market: efficiency bonus

---

## 🗼 Torre e Exploração

### Andares da Torre
📁 **Modelo:** `lib/models/tower.dart` (linhas 132-380)
📁 **Geração:** 100 andares procedurais
- Boss floors: 10, 20, 30... (difficulty x2.5, rewards x3)
- Elite floors: 5, 15, 25... (difficulty x1.5, rewards x1.5)
- 8 tipos diferentes (combat, survival, strategic, puzzle, etc.)

### Expedições
📁 **UI:** `lib/screens/tower_screen.dart` (linhas 1680-1940)
📁 **Backend:** `lib/services/game_engine.dart` (linhas 2265-2450)
- Seleção de NPCs
- Custo de comida por NPC (3 + tier)
- Cálculo de mortalidade
- Recompensas baseadas em tier
- Casualties e traumas

### Re-exploração (Treino)
📁 **UI:** `lib/screens/tower_screen.dart` (linhas 1992-2350)
📁 **Backend:** `lib/services/game_engine.dart` (linhas 2452-2514)
- Treino em andares conquistados
- Custo reduzido (2 + tier * 0.6)
- Ganhos de atributos (~0.05-0.15)
- Risco baixo (~3% mortalidade)
- Fadiga menor (6-10)

### Re-exploração (Coleta de Recursos)
📁 **UI:** `lib/screens/groups_screen.dart` (linhas 560-820)
📁 **Backend:** `lib/services/game_engine.dart` (linhas 1257-1354)
- Grupos coletam recursos farmáveis
- Rendimento baseado em atributos + sinergia
- Diminishing returns (timesReexplored)
- Eventos de expedição (acidentes, descobertas)
- Ameaça reativada (5% + 2% por reexploração)

### Sinergia de Grupo
📁 **Cálculo:** `lib/services/game_engine.dart` (linhas 986-1030)
- Leaders: +15% sinergia
- Natural Leaders (talent): +15% extra
- Casais no grupo: +10%
- Crianças de membros: +5%
- Suspeitos: -20%
- Covardes: -10%

### Campo de Treino
📁 **Processamento:** `lib/services/game_engine.dart` (linhas 1426-1453)
- Treino de Barracks: grupos de guards
- Custo: 1.5 comida/NPC
- Ganhos pequenos mas seguros
- Risco baixíssimo (0.1% vs 95% reduzida)

### Treino Autônomo
📁 **Processamento:** `lib/services/game_engine.dart` (linhas 943-963)
- NPCs com floorsCleared < 5 treinam sozinhos (15% chance)
- Escolhem andar aleatório
- Ganhos pequenos (0.05-0.15)
- Sistema de fadiga aplicado

### Auto Re-exploração
📁 **Processamento:** `lib/services/game_engine.dart` (linhas 903-920)
- NPCs iniciativa própria (3% chance/dia)
- Pegam exploradores disponíveis
- Escolhem andar aleatório
- Sistema automático de melhoria

---

## 👨‍👨‍👧‍👦 Grupos e Expedições

### Criação de Grupos
📁 **UI:** `lib/screens/groups_screen.dart` (linhas 822-1163)
📁 **Backend:** `lib/services/game_engine.dart` (linhas 2484-2545)
- Seleção de membros
- Escolha de papel (expedition, training, resource, defense)
- Líder automático (maior combatPower + carisma)

### Gestão de Grupos
📁 **UI:** `lib/screens/groups_screen.dart` (linhas 140-430)
📁 **Backend:** `lib/providers/game_provider.dart` (linhas 478-550)
- Dissolver grupo
- Ver membros
- Enviar expedição
- Sugerir treino
- Coletar recursos

### Sugestões de Treino
📁 **UI:** `lib/screens/groups_screen.dart` (linhas 1169-1250)
📁 **Backend:** `lib/services/game_engine.dart` (linhas 2998-3090)
- NPCs decidem aceitar/recusar/ignorar
- Baseado em: personality, loyalty, fatigue, relationship com líder
- Histórico de aceitação registrado

---

## 📜 Sistema de Eventos

### Tipos de Eventos
📁 **Modelo:** `lib/models/game_event.dart`
- 20 tipos diferentes
- Eventos maiores destacados
- NPCs envolvidos linkados

### Log de Eventos
📁 **UI:** `lib/screens/event_log_screen.dart`
📁 **Geração:** Espalhada por `game_engine.dart` (método `_addEvent()`)
- Filtro por tipo
- Marca de eventos maiores
- Link para NPCs envolvidos

### Eventos Aleatórios
📁 **Processamento:** `lib/services/game_engine.dart` (linhas 861-901)
- Descobertas (2%)
- Visitas de merchants (1%)
- Festivais (1.5%)
- Doenças (3% if no infirmary)
- Conflitos de personalidade

### Eventos de Expedição
📁 **Processamento:** `lib/services/game_engine.dart` (linhas 1358-1424)
- Acidentes (chance baseada em endurance)
- Descobertas (chance baseada em luck)
- Emboscadas (chance baseada em cautious)
- Ferimentos leves

---

## ⚙️ Engine do Jogo - `game_engine.dart`

> **Arquivo**: `lib/services/game_engine.dart` (3425 linhas)
> **Função**: Coração do jogo, processa todos os sistemas diários

### Estrutura do Loop Diário
📍 **Método principal:** `processDayEnd()` (linhas 160-202)

**Ordem de execução:**
1. Consumo de comida (linhas 206-228)
2. Recuperação de fadiga (linhas 298-314)
3. Produção de edifícios (linhas 230-276)
4. Formação de casais (linhas 1630-1659)
5. Saúde mental (linhas 316-450)
6. Lealdade (linhas 452-485)
7. Ociosidade (linhas 487-586)
8. Escolha autônoma de profissão (linhas 595-752)
9. Eventos aleatórios (linhas 861-901)
10. Tentativas de traição (linhas 756-859)
11. Gravidezes (linhas 1716-1780)
12. Mortalidade infantil (linhas 1782-1845)
13. Transições de crescimento (linhas 1847-1932)
14. Envelhecimento (linhas 1960-1977)
15. Treino profissional (linhas 2003-2032)
16. Treino autônomo (linhas 943-963)
17. Auto-reexploração (linhas 903-920)
18. Eventos de arena (linhas 1522-1588)
19. Eventos de taverna (linhas 1590-1628)
20. Invocação emergencial (linhas 1459-1484)

### Métodos Importantes

**NPCs:**
- `_killNpc()` - Linha 2642
- `_traumatizeParents()` - Linha 2655
- `_addPsychologicalMarksToChildren()` - Linha 2664

**Recursos:**
- `_applyBuildingProduction()` - Linha 230
- `_applyResourcesToStock()` - Linha 2520

**Torre:**
- `sendExpedition()` - Linha 2265
- `trainOnFloor()` - Linha 2452
- `reexploreFloor()` - Linha 1257
- `_applyFloorRewards()` - Linha 3095

**Grupos:**
- `createGroup()` - Linha 2484
- `_calculateGroupSynergy()` - Linha 986
- `_resolveParty()` - Linha 931

**Profissões:**
- `_applyProfessionTraining()` - Linha 2003
- `changeProfession()` - Linha 3071

**Estado:**
- `toJson()` - Linha 3357
- `loadFromJson()` - Linha 3392

---

## 🎮 Provider e Estado

### GameProvider
📁 **Arquivo:** `lib/providers/game_provider.dart`
- Wrapper do GameEngine para UI
- ChangeNotifier para updates
- Métodos públicos das actions
- Auto-save a cada ação

**Métodos principais:**
- `newGame()` - Linha 28
- `loadGame()` - Linha 33
- `processDayEnd()` - Linha 106
- `buildBuilding()` - Linha 185
- `upgradeCitadel()` - Linha 209
- `sendExpedition()` - Linha 265
- `createGroup()` - Linha 482
- `suggestTraining()` - Linha 503

### SaveService
📁 **Arquivo:** `lib/services/save_service.dart`
- Salva/carrega JSON em arquivo local
- SharedPreferences para path
- Tratamento de erros

---

## 🖥️ Telas (UI)

### TitleScreen
📁 **Arquivo:** `lib/screens/title_screen.dart`
- Menu inicial
- New Game / Load Game
- Estética terminal

### DashboardScreen
📁 **Arquivo:** `lib/screens/dashboard_screen.dart`
- Visão geral da cidadela
- Recursos, população, moral
- Botão de avançar dia
- Navigator para outras telas

### CitadelScreen
📁 **Arquivo:** `lib/screens/citadel_screen.dart`
- Lista de edifícios construídos
- Construir novos edifícios
- Upgrade da cidadela
- Upgrade do armazém
- Info de produção diária

### TowerScreen
📁 **Arquivo:** `lib/screens/tower_screen.dart`
- Próximo andar a conquistar
- Histórico de andares limpos
- Enviar expedição (dialog)
- Re-explorar para treino (dialog)
- Info de comando e dificuldade

### GroupsScreen
📁 **Arquivo:** `lib/screens/groups_screen.dart`
- Lista de grupos ativos
- Criar novo grupo (dialog)
- Sugerir treino (dialog com scroll fix)
- Coletar recursos (dialog com scroll fix)
- Dissolver grupo

### NpcListScreen
📁 **Arquivo:** `lib/screens/npc_list_screen.dart`
- Lista de todos NPCs (vivos + mortos)
- Detalhes de cada NPC (dialog)
- Info de atributos, profissão, relacionamentos, histórico

### EventLogScreen
📁 **Arquivo:** `lib/screens/event_log_screen.dart`
- Cronologia de eventos
- Filtro por tipo de evento
- Destaque de eventos maiores

### CodexScreen
📁 **Arquivo:** `lib/screens/codex_screen.dart`
- Documentação in-game
- 13 categorias
- Info sobre mecânicas, profissões, edifícios, torre
- Atualizado com mecânicas recentes

---

## 🛠️ Serviços

### SaveService
📁 **Arquivo:** `lib/services/save_service.dart`
- `save()` - Salva GameEngine em JSON
- `load()` - Carrega GameEngine de JSON
- Path via SharedPreferences

### GameEngine
📁 **Arquivo:** `lib/services/game_engine.dart`
- Ver seção detalhada acima

---

## 🎨 Widgets e Tema

### Theme
📁 **Arquivo:** `lib/widgets/theme.dart`
- Paleta de cores terminal (green, cyan, orange, red, etc.)
- Cores de texto (primary, secondary, dim)
- Cores de fundo (bg, bgCard, border)

### TerminalWidgets
📁 **Arquivo:** `lib/widgets/terminal_widgets.dart`
- `TerminalText` - Texto estilo terminal
- `TerminalButton` - Botão personalizado
- `TerminalCard` - Card com borda
- `StatBar` - Barra de progresso
- `ResourceDisplay` - Display de recursos
- `CyanDivider` - Divisor visual

---

## 🔧 Modificações Recentes

### Building Evolution System
📁 **Implementado em:**
- `game_engine.dart:2362-2395` (filter obsolete buildings)
- `citadel.dart:553-555, 789` (firepit evolution)
- `game_engine.dart:272-276` (firepit scaling bonus)

### Idleness System
📁 **Implementado em:**
- `npc.dart:527` (daysIdle field)
- `game_engine.dart:487-586` (processing + penalties)

### Autonomous Profession Choice
📁 **Implementado em:**
- `game_engine.dart:595-752` (complete logic)

### Re-exploration UI Enhancement
📁 **Implementado em:**
- `tower_screen.dart:2198-2348` (enhanced NPC selector)

### Groups Screen Scroll Fix
📁 **Implementado em:**
- `groups_screen.dart:708-715` (resource collection)
- `groups_screen.dart:1208-1224` (training suggestion)

### Codex Updates
📁 **Implementado em:**
- `codex_screen.dart:35-36` (new categories)
- `codex_screen.dart:250-264` (autonomous professions)
- `codex_screen.dart:696-708` (building evolution)
- `codex_screen.dart:720-879` (ociosidade + evolucao content)

---

## 📍 Localização Rápida de Constantes

### Valores de Balanceamento

**NPCs:**
- Consumo diário comida: `game_engine.dart:217` (1.5/NPC)
- Threshold de sanidade surto: `game_engine.dart:385` (< 20)
- Chance de traição: `game_engine.dart:768` (loyalty < 30)
- Dias de gravidez: `game_engine.dart:1728` (2 dias)

**Edifícios:**
- Produção Farm: `citadel.dart:625-627` (5/12/25 by tier)
- Bonus Firepit: `game_engine.dart:273` ([1, 2, 3, 5])
- Bônus Forge: `citadel.dart:684-686` (+10/15/25% combat)

**Torre:**
- Boss multipliers: `tower.dart:157-159` (difficulty x2.5, rewards x3)
- Elite multipliers: `tower.dart:161-162` (difficulty x1.5)
- Re-exploração custo: `game_engine.dart:933` (2 + tier * 0.6)

**Talentos:**
- Chance de talento ao nascer: `npc.dart:869` (15%)
- CombatGenius: `game_engine.dart:2315` (+50%)
- StrategicMind: `game_engine.dart:1013` (-15% mortality)
- NaturalLeader: `game_engine.dart:1020` (+15% synergy)

---

## 🎯 Roadmap de Funcionalidades (Planejadas)

### v2.0 - Sistema de Fortalecimento (Plano: `/cheerful-seeking-iverson.md`)
**Não implementado ainda:**
- ❌ Equipamentos (weapons, armor, accessories)
- ❌ Relíquias da Torre (boss drops, passive effects)
- ❌ Aprendizado por observação (veterans mentor novices)
- ❌ Synthesis Lab (combine rare materials)
- ❌ Alchemy Lab (potion production + consumption)
- ❌ Talentos: forgemaster, herbalist, runeReader, shadowWalker, ironWill, beastWhisperer

---

## 💡 Dicas de Navegação

**Para mexer em combate:**
1. Ver cálculo: `npc.dart:~600` (combatPower)
2. Ver uso em expedição: `game_engine.dart:2265-2450`
3. Ver talentos de combate: `game_engine.dart:2312-2350`

**Para mexer em economia:**
1. Recursos: `citadel.dart:9-21`
2. Produção: `game_engine.dart:230-276`
3. Consumo: `game_engine.dart:206-228`
4. Capacidade: `citadel.dart:184-207`

**Para mexer em NPCs:**
1. Atributos: `npc.dart:100-130`
2. Geração: `npc.dart:809-885`
3. Morte: `game_engine.dart:2642-2652`
4. Crescimento: `game_engine.dart:1847-1932`

**Para mexer em UI:**
1. Tema global: `widgets/theme.dart`
2. Widgets compartilhados: `widgets/terminal_widgets.dart`
3. Tela específica: `screens/<nome>_screen.dart`

---

**Última atualização:** 2026-02-23
**Versão do jogo:** v5.0 (Sistema de Expedição Hardcore + Armazém Reformulado)
