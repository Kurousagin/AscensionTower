# Sistema Modular de Eventos

## Estrutura Criada:

```
lib/services/events/
├── event_processor.dart        # Classe base com helpers comuns
├── construction_events.dart    # Reações a construções ✅
├── relationship_events.dart    # Relacionamentos, taverna ✅
├── combat_events.dart          # Arena, duelos, conflitos ✅
└── profession_events.dart      # Treino diário, profissões ✅
```

## ✅ Já Migrado:

### construction_events.dart
- `processNpcBuildReaction()` - Reações contextuais a construções
  - Barracks (com lógica melhorada: moral, ameaças, força militar)
  - TrainingField
  - Temple
  - Tavern
  - Arena
  - CouncilHall
  - PromotionHall

### relationship_events.dart
- `processTavernEvents()` - Eventos da taverna (boatos, relacionamentos)
- `processRelationshipFormation()` - Formação de novas amizades
- `processRelationshipDecay()` - Deterioração de relações ruins

### combat_events.dart
- `processArenaEvents()` - Duelos na arena
- `processConflicts()` - Conflitos entre NPCs
  - Conflitos físicos
  - Conflitos verbais

### profession_events.dart
- `processTraining()` - Treino diário por profissão
  - Inclui bônus de Barracks (0.3/0.5/0.8 FOR baseado no tier)
- `processAutoProfessionAssignment()` - Atribuição automática de profissões

## 🔄 Uso no game_engine.dart:

```dart
// Inicialização (feita automaticamente no construtor)
_constructionEvents = ConstructionEvents(...);
_relationshipEvents = RelationshipEvents(...);
_combatEvents = CombatEvents(...);
_professionEvents = ProfessionEvents(...);

// Substituições feitas:
_processTraining()           → _professionEvents.processTraining()
_processArenaEvents()        → _combatEvents.processArenaEvents()
_processTavernEvents()       → _relationshipEvents.processTavernEvents()
_processNpcBuildReaction()   → _constructionEvents.processNpcBuildReaction()
```

## 📋 Próximos Processadores (Sugestões):

### crisis_events.dart
- Fome (já existe `_processResourceConsumption`)
- Traição (já existe `_processBetrayalAttempts`)
- Emergências (já existe `_processEmergencySummon`)
- Epidemias
- Desastres naturais

### political_events.dart
- Eleições/votações
- Mudanças de liderança
- Facções/grupos políticos
- Revoltas

### lifecycle_events.dart
- Nascimentos (`_processPregnancies`)
- Mortes (`_processChildMortality`)
- Envelhecimento (`_processAging`)
- Crescimento (`_processGrowthTransitions`)

### tower_events.dart
- Resultados de expedições
- Loot distribution
- Floor clearing celebrations
- Party formation

## 💡 Vantagens da Modularização:

1. **Organização**: Cada tipo de evento em seu arquivo
2. **Manutenção**: Fácil encontrar e modificar lógica específica
3. **Testabilidade**: Cada processador pode ser testado isoladamente
4. **Reutilização**: Helpers comuns na classe base
5. **Escalabilidade**: Adicionar novos eventos sem alterar game_engine
6. **Legibilidade**: Código mais limpo e focado

## 🎯 Como Adicionar Novos Eventos:

1. Criar novo arquivo em `lib/services/events/`
2. Estender `EventProcessor`
3. Implementar métodos de processamento
4. Registrar no `game_engine.dart`:
   ```dart
   late final MeuEventProcessor _meuEventProcessor;
   
   void _initEventProcessors() {
     // ...
     _meuEventProcessor = MeuEventProcessor(...);
   }
   
   // Usar no processDayEnd:
   _meuEventProcessor.processarAlgo();
   ```
