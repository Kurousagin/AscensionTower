import 'package:flutter/material.dart';
import '../widgets/theme.dart';
import '../widgets/terminal_widgets.dart';

class CodexScreen extends StatefulWidget {
  const CodexScreen({super.key});

  @override
  State<CodexScreen> createState() => _CodexScreenState();
}

class _CodexScreenState extends State<CodexScreen> {
  String _selectedCategory = 'geral';

  final Map<String, String> _categories = {
    'geral': 'Visao Geral',
    'atributos': 'Atributos',
    'profissoes': 'Profissoes',
    'origens': 'Origens',
    'talentos': 'Talentos Ocultos',
    'personalidade': 'Personalidade',
    'mental': 'Estado Mental',
    'torre': 'Andares da Torre',
    'edificios': 'Edificios',
    'cidadela': 'Niveis da Cidadela',
    'recursos': 'Recursos',
    'eventos': 'Tipos de Evento',
    'mecanicas': 'Mecanicas do Jogo',
    'lealdade': 'Lealdade & Traicao',
    'grupos': 'Esquadroes',
    'treino': 'Sistema de Treino',
    'reexploracao': 'Re-Exploracao',
    'invocacao': 'Invocacao Emergencial',
    'politica': 'Politica Interna',
  };

  @override
  Widget build(BuildContext context) {
    return ScanlineOverlay(
      child: Row(
        children: [
          _buildCategoryNav(),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildCategoryNav() {
    return Container(
      width: 140,
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: AppTheme.border)),
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: _categories.entries.map((entry) {
          final active = _selectedCategory == entry.key;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = entry.key),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: active ? AppTheme.cyan.withValues(alpha: 0.1) : null,
                border: Border(
                  left: BorderSide(
                    color: active ? AppTheme.cyan : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: TerminalText(
                entry.value,
                fontSize: 9,
                color: active ? AppTheme.cyan : AppTheme.textSecondary,
                fontWeight: active ? FontWeight.bold : null,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _getContentForCategory(),
      ),
    );
  }

  List<Widget> _getContentForCategory() {
    switch (_selectedCategory) {
      case 'geral':
        return _buildGeralContent();
      case 'atributos':
        return _buildAtributosContent();
      case 'profissoes':
        return _buildProfissoesContent();
      case 'origens':
        return _buildOrigensContent();
      case 'talentos':
        return _buildTalentosContent();
      case 'personalidade':
        return _buildPersonalidadeContent();
      case 'mental':
        return _buildMentalContent();
      case 'torre':
        return _buildTorreContent();
      case 'edificios':
        return _buildEdificiosContent();
      case 'cidadela':
        return _buildCidadelaContent();
      case 'recursos':
        return _buildRecursosContent();
      case 'eventos':
        return _buildEventosContent();
      case 'mecanicas':
        return _buildMecanicasContent();
      case 'lealdade':
        return _buildLealdadeContent();
      case 'grupos':
        return _buildGruposContent();
      case 'treino':
        return _buildTreinoContent();
      case 'reexploracao':
        return _buildReexploracaoContent();
      case 'invocacao':
        return _buildInvocacaoContent();
      case 'politica':
        return _buildPoliticaContent();
      default:
        return [const TerminalText('Selecione uma categoria.', color: AppTheme.textDim)];
    }
  }

  List<Widget> _buildGeralContent() {
    return [
      _sectionTitle('A TORRE DA SEGUNDA HUMANIDADE'),
      _paragraph(
        '15 humanos comuns foram arrancados de suas vidas cotidianas e jogados na base '
        'de uma torre mistica de 100 andares. Ninguem sabe por que estao aqui. Ninguem '
        'sabe quem os invocou. A unica certeza: subir e a unica opcao.',
      ),
      const SizedBox(height: 12),
      _sectionTitle('VOCE E UM OBSERVADOR'),
      _paragraph(
        'Voce nao controla os habitantes. Voce observa. O tempo dentro da Torre e distorcido: '
        '24 horas no mundo real equivalem a 48 horas la dentro (ratio 2:1). Os NPCs tomam decisoes '
        'autonomamente — formam casais, exploram andares, constroem, entram em colapso, morrem.',
      ),
      const SizedBox(height: 12),
      _sectionTitle('OBJETIVO'),
      _paragraph(
        'Sobreviver. Escalar a Torre. Construir uma sociedade funcional. '
        'Gerar novas geracoes que herdam atributos dos pais (com chance de mutacao). '
        'Conquistar os 10 andares do MVP sem que a populacao seja extinta.',
      ),
      const SizedBox(height: 12),
      _sectionTitle('TEMPO DISTORCIDO (Continuo)'),
      _paragraph(
        'O mundo real e o mundo da Torre existem em dimensoes diferentes. '
        '24 horas no mundo real equivalem a 48 horas dentro da Torre (ratio 2:1). '
        'O tempo flui continuamente baseado em timestamps reais — nao depende de ticks fixos.'
      ),
      const SizedBox(height: 8),
      _codexEntry('Formula', 'deltaGameSeconds = deltaRealSeconds x 2 x velocidade', color: AppTheme.cyan),
      const SizedBox(height: 8),
      _entryRow('Ratio base', '1 segundo real = 2 segundos na Torre'),
      _entryRow('1 dia in-game', '~12h reais na vel. 1x'),
      _entryRow('Velocidade 1x', '24h real = 2 dias jogo'),
      _entryRow('Velocidade 2x', '24h real = 4 dias jogo'),
      _entryRow('Velocidade 5x', '24h real = 10 dias jogo'),
      _entryRow('Velocidade 10x', '24h real = 20 dias jogo'),
      _entryRow('Velocidade 25x', '24h real = 50 dias jogo'),
      _entryRow('Velocidade 50x', '24h real = 100 dias jogo'),
      const SizedBox(height: 8),
      _sectionTitle('CICLO DIA/NOITE'),
      _entryRow('Madrugada', '00:00 - 05:59'),
      _entryRow('Manha', '06:00 - 11:59'),
      _entryRow('Tarde', '12:00 - 17:59'),
      _entryRow('Noite', '18:00 - 21:59'),
      _entryRow('Madrugada', '22:00 - 23:59'),
      const SizedBox(height: 8),
      _sectionTitle('PROGRESSO OFFLINE'),
      _paragraph(
        'O tempo continua passando mesmo com o jogo fechado! Ao reabrir, '
        'o sistema calcula quanto tempo real se passou e converte em tempo da Torre. '
        'Dias acumulados sao processados automaticamente (limite: 30 dias por sessao). '
        'Offline usa velocidade 1x (ratio base) para manter o equilibrio.'
      ),
      const SizedBox(height: 12),
      _sectionTitle('MORTE PERMANENTE'),
      _paragraph(
        'Quando um NPC morre, morre para sempre. Seu parceiro entra em luto (perda de sanidade), '
        'seus filhos ficam orfaos (trauma), e aliados proximos sofrem impacto emocional. '
        'A moral da cidadela tambem cai. Mortes em cascata podem extinguir a populacao.',
      ),
    ];
  }

  List<Widget> _buildAtributosContent() {
    return [
      _sectionTitle('ATRIBUTOS DOS HABITANTES'),
      _paragraph('Cada NPC possui 6 atributos que definem suas capacidades e limitacoes:'),
      const SizedBox(height: 8),
      _codexEntry('Forca (FOR)', 'Poder fisico bruto. Influencia combate, construcao e trabalho pesado. Escala 1-15.'),
      _codexEntry('Agilidade (AGI)', 'Velocidade e reflexos. Afeta esquiva, exploracao e eficiencia em tarefas rapidas. Escala 1-15.'),
      _codexEntry('Inteligencia (INT)', 'Capacidade mental. Essencial para estrategia, pesquisa e producao de conhecimento. Escala 1-15.'),
      _codexEntry('Resistencia (RES)', 'Vigor fisico e capacidade de suportar danos. Influencia sobrevivencia e duracao. Escala 1-15.'),
      _codexEntry('Carisma (CAR)', 'Habilidade social. Afeta relacionamentos, lideranca e moral. Escala 1-15.'),
      _codexEntry('Sanidade Mental (SAN)', 'Estabilidade psicologica. Escala 0-100. Abaixo de 15, riscos de colapso mental.'),
      const SizedBox(height: 12),
      _sectionTitle('FORMULAS DERIVADAS'),
      _codexEntry('Poder de Combate', 'FOR x 0.30 + AGI x 0.25 + RES x 0.25 + INT x 0.20'),
      _codexEntry('Media Geral', '(FOR + AGI + INT + RES + CAR) / 5'),
      _codexEntry('Score de Sobrevivencia', 'RES x 0.30 + FOR x 0.20 + AGI x 0.20 + INT x 0.15 + SAN x 0.015'),
    ];
  }

  List<Widget> _buildProfissoesContent() {
    return [
      _sectionTitle('PROFISSOES DA CIDADELA'),
      _paragraph('Os NPCs sao designados automaticamente para funcoes baseadas em seus atributos e origens:'),
      const SizedBox(height: 8),
      _codexEntry('Ocioso', 'Sem funcao atribuida. Nao contribui com producao de recursos. NPCs inativos ou em colapso.'),
      _codexEntry('Explorador', 'Participa de expedicoes na Torre. Selecionado por alto poder de combate.'),
      _codexEntry('Guarda', 'Protege a cidadela e participa de expedicoes. Treina Forca e Resistencia automaticamente.'),
      _codexEntry('Cozinheiro', 'Produz comida extra quando a Cozinha esta construida (+3 comida/dia por chef).'),
      _codexEntry('Medico', 'Cuida de feridos. Reduz mortalidade quando a Enfermaria esta construida.'),
      _codexEntry('Professor', 'Educa jovens e treina Inteligencia. Funciona com a Escola construida.'),
      _codexEntry('Ferreiro', 'Produz armas e ferramentas. Requer a Forja construida.'),
      _codexEntry('Mercador', 'Gerencia troca de recursos. Funciona com o Mercado construido.'),
      _codexEntry('Escriba', 'Gera conhecimento (+1.5/dia). Selecionado pela alta inteligencia.'),
      _codexEntry('Fazendeiro', 'Produz comida (+3 comida/dia por fazendeiro). Vital para a sobrevivencia.'),
      _codexEntry('Construtor', 'Produz madeira (+2/dia) e pedra (+1/dia). Essencial para edificar.'),
      _codexEntry('Batedor', 'Reconhecimento e exploracao. Treina Agilidade automaticamente.'),
    ];
  }

  List<Widget> _buildOrigensContent() {
    return [
      _sectionTitle('ORIGENS DOS INVOCADOS'),
      _paragraph('Cada NPC chega com uma profissao do mundo real que define seus atributos base:'),
      const SizedBox(height: 8),
      _codexEntry('Estudante', 'FOR: 3 | AGI: 4 | INT: 8 | RES: 3 | CAR: 5 | SAN: 60'),
      _codexEntry('Chef', 'FOR: 4 | AGI: 6 | INT: 6 | RES: 5 | CAR: 7 | SAN: 65'),
      _codexEntry('Soldado', 'FOR: 9 | AGI: 7 | INT: 5 | RES: 9 | CAR: 4 | SAN: 75'),
      _codexEntry('Programador', 'FOR: 2 | AGI: 3 | INT: 9 | RES: 3 | CAR: 4 | SAN: 55'),
      _codexEntry('Atleta', 'FOR: 8 | AGI: 9 | INT: 4 | RES: 8 | CAR: 6 | SAN: 70'),
      _codexEntry('Empresario', 'FOR: 4 | AGI: 4 | INT: 7 | RES: 5 | CAR: 9 | SAN: 68'),
      _codexEntry('Medico', 'FOR: 3 | AGI: 5 | INT: 9 | RES: 5 | CAR: 6 | SAN: 72'),
      _codexEntry('Professor', 'FOR: 3 | AGI: 4 | INT: 8 | RES: 4 | CAR: 8 | SAN: 70'),
      _codexEntry('Artista', 'FOR: 3 | AGI: 5 | INT: 7 | RES: 3 | CAR: 8 | SAN: 50'),
      _codexEntry('Mecanico', 'FOR: 7 | AGI: 6 | INT: 6 | RES: 7 | CAR: 4 | SAN: 65'),
      _codexEntry('Fazendeiro', 'FOR: 7 | AGI: 5 | INT: 4 | RES: 8 | CAR: 5 | SAN: 75'),
      _codexEntry('Musico', 'FOR: 3 | AGI: 5 | INT: 6 | RES: 3 | CAR: 9 | SAN: 55'),
      _codexEntry('Cientista', 'FOR: 2 | AGI: 3 | INT: 10 | RES: 4 | CAR: 4 | SAN: 60'),
      _codexEntry('Bombeiro', 'FOR: 8 | AGI: 7 | INT: 5 | RES: 9 | CAR: 6 | SAN: 78'),
      _codexEntry('Enfermeiro(a)', 'FOR: 4 | AGI: 5 | INT: 7 | RES: 6 | CAR: 7 | SAN: 70'),
      const SizedBox(height: 12),
      _sectionTitle('ORIGENS OBSCURAS (Perigo!)'),
      _paragraph('Invocados com passado criminoso. Fortes em certas areas, mas risco de traicao elevado:'),
      const SizedBox(height: 8),
      _codexEntry('Ladrao', 'FOR: 4 | AGI: 9 | INT: 7 | RES: 5 | CAR: 6 | SAN: 55 | Risco base: +25%', color: AppTheme.red),
      _codexEntry('Assassino', 'FOR: 8 | AGI: 10 | INT: 6 | RES: 7 | CAR: 3 | SAN: 45 | Pode matar NPCs!', color: AppTheme.red),
      _codexEntry('Estelionatario', 'FOR: 3 | AGI: 5 | INT: 9 | RES: 3 | CAR: 10 | SAN: 50 | Manipula lealdade', color: AppTheme.red),
    ];
  }

  List<Widget> _buildTalentosContent() {
    return [
      _sectionTitle('TALENTOS OCULTOS'),
      _paragraph(
        'Alguns NPCs possuem talentos ocultos que podem ser revelados durante eventos aleatorios '
        'ou ao conquistar certos andares (especialmente o Andar 7 - Biblioteca Proibida). '
        'Chance de 15% ao ser invocado. Filhos podem herdar talentos (20% chance) ou ganhar novos (8%).',
      ),
      const SizedBox(height: 8),
      _codexEntry('Genio do Combate', '+50% poder de combate. Transforma um NPC comum em uma maquina de guerra.'),
      _codexEntry('Toque Curativo', 'Cura aliados apos batalha. Restaura Resistencia e Sanidade dos sobreviventes.'),
      _codexEntry('Mente Estrategica', 'Reduz mortalidade do grupo em 15%. O estrategista nunca e dispensavel.'),
      _codexEntry('Lider Natural', '+20% moral do grupo. Inspira outros e eleva o espirito coletivo.'),
      _codexEntry('Sussurrador de Feras', 'Chance de domar criaturas hostis nos andares de combate.'),
      _codexEntry('Mestre da Forja', 'Equipamentos produzidos sao 2x mais eficientes.'),
      _codexEntry('Herbalista', 'Produz medicamentos naturais com plantas encontradas na Torre.'),
      _codexEntry('Leitor de Runas', 'Revela segredos e informacoes ocultas dos andares da Torre.'),
      _codexEntry('Caminhante das Sombras', 'Pode evadir qualquer combate. O NPC perfeito para reconhecimento.'),
      _codexEntry('Vontade de Ferro', 'Imune a perda de sanidade. Nunca sofre colapso mental.'),
    ];
  }

  List<Widget> _buildPersonalidadeContent() {
    return [
      _sectionTitle('TRACOS DE PERSONALIDADE'),
      _paragraph(
        'Cada NPC possui 2-3 tracos de personalidade que influenciam seu comportamento, '
        'combate e interacoes sociais. Filhos herdam tracos dos pais (com variacao).',
      ),
      const SizedBox(height: 8),
      _codexEntry('Corajoso', 'Bonus de +10% poder de combate. Avanca sem hesitar.'),
      _codexEntry('Covarde', 'Penalidade de -15% poder de combate. Tende a fugir do perigo.'),
      _codexEntry('Lider', 'Melhora a moral do grupo. Tomador de decisoes natural.'),
      _codexEntry('Solitario', 'Prefere estar sozinho. Menor chance de formar relacionamentos.'),
      _codexEntry('Compassivo', 'Cuida dos outros. Bonus em interacoes sociais e cura.'),
      _codexEntry('Implacavel', 'Frio e calculista. Prioriza eficiencia sobre emocao.'),
      _codexEntry('Otimista', 'Recupera +0.5 sanidade/dia naturalmente. Ve o lado bom.'),
      _codexEntry('Pessimista', 'Perde -0.5 sanidade/dia. Ve tudo como condenado.'),
      _codexEntry('Analitico', 'Bonus em andares estrategicos. Pensa antes de agir.'),
      _codexEntry('Impulsivo', 'Age sem pensar. Pode causar problemas ou acertos inesperados.'),
      _codexEntry('Leal', 'Bonus de afinidade com aliados. Nunca trai.'),
      _codexEntry('Traicoeiro', 'Pode trair aliados em momentos de crise.'),
      _codexEntry('Calmo', 'Resiste melhor a pressao. Menos vulneravel a colapso.'),
      _codexEntry('Agressivo', 'Mais forte em combate, mas propenso a surtos violentos.'),
      _codexEntry('Criativo', 'Encontra solucoes inesperadas. Bonus em andares de misterio.'),
      _codexEntry('Pragmatico', 'Eficiente e pratico. Faz o que precisa ser feito.'),
    ];
  }

  List<Widget> _buildMentalContent() {
    return [
      _sectionTitle('ESTADOS MENTAIS'),
      _paragraph(
        'A sanidade de um NPC e medida de 0 a 100. Conforme cai, o NPC entra em estados '
        'progressivamente piores. Abaixo de 15, colapsos mentais podem ocorrer.',
      ),
      const SizedBox(height: 8),
      _codexEntry('Estavel (70-100)', 'NPC funciona normalmente. Contribui com eficiencia total.', color: AppTheme.green),
      _codexEntry('Estressado (55-69)', 'Leve tensao. Performance ligeiramente reduzida.', color: AppTheme.yellow),
      _codexEntry('Deprimido (40-54)', 'Perda de motivacao. Pode parar de trabalhar.', color: AppTheme.blue),
      _codexEntry('Rebelde (25-39)', 'Ressentimento contra a sociedade. Pode destruir recursos.', color: AppTheme.orange),
      _codexEntry('Isolado (15-24)', 'Retirada total. Nao interage com ninguem. Risco critico.', color: AppTheme.textDim),
      _codexEntry('Descontrolado (5-14)', 'Surtos de violencia ou desespero. Perigo para si e outros.', color: AppTheme.red),
      _codexEntry('Quebrado (0-4)', 'Destruido emocionalmente. Praticamente nao funcional.', color: AppTheme.red),
      const SizedBox(height: 12),
      _sectionTitle('TIPOS DE COLAPSO MENTAL'),
      _paragraph('Quando sanidade cai abaixo de 15, ha 10% de chance por dia de:'),
      const SizedBox(height: 8),
      _codexEntry('Isolamento', 'NPC se tranca. Profissao vira Ocioso. Adiciona trauma.'),
      _codexEntry('Rebeliao', 'NPC destroi suprimentos. -10 comida, -5 moral. Trauma.'),
      _codexEntry('Sacrificio Suicida', '30% chance de morte: parte sozinho para a Torre. 70%: tenta fugir e desmaia.'),
      _codexEntry('Depressao Profunda', 'Para de comer/falar. Vira Ocioso, perde -1 Forca.'),
      _codexEntry('Surto Agressivo', 'Ataca outros moradores. -3 moral. Precisa ser contido.'),
    ];
  }

  List<Widget> _buildTorreContent() {
    return [
      _sectionTitle('ANDARES DA TORRE (MVP: 1-10)'),
      _paragraph(
        'Cada andar possui tipo, dificuldade, taxa de mortalidade e recompensas unicas. '
        'Andares conquistados podem ser revisitados para treino (com ganhos reduzidos).',
      ),
      const SizedBox(height: 8),
      _towerEntry(1, 'Sobrevivencia', 'As Ruinas Silenciosas',
          'Campo devastado com criaturas rastejantes.', 'Dif: 2.0 | Mort: 5%', '+15 Madeira, +10 Pedra'),
      _towerEntry(2, 'Combate', 'O Corredor das Bestas',
          'Criaturas deformadas em corredores estreitos.', 'Dif: 3.0 | Mort: 8%', '+20 Comida, +5 Ferro'),
      _towerEntry(3, 'Moral', 'A Sala dos Espelhos',
          'Espelhos mostram piores medos. Risco de insanidade.', 'Dif: 2.5 | Mort: 3%', '+15 Conhecimento, +10 Moral'),
      _towerEntry(4, 'Estrategico', 'O Labirinto Mecanico',
          'Engrenagens e armadilhas. Requer INT > 6 no lider.', 'Dif: 4.0 | Mort: 10%', '+10 Ferro, +10 Conhecimento'),
      _towerEntry(5, 'Combate', 'A Arena Sangrenta',
          'Lutem ou morram. Sem fuga possivel.', 'Dif: 5.0 | Mort: 12%', '+15 Ferro, +20 Fama'),
      _towerEntry(6, 'Sobrevivencia', 'O Pantano Toxico',
          'Ar venenoso e agua acida. Dano continuo.', 'Dif: 5.5 | Mort: 10%', '+25 Comida, +5 Conhecimento'),
      _towerEntry(7, 'Misterio', 'A Biblioteca Proibida',
          'Tomos perigosos. Pode revelar talentos ocultos.', 'Dif: 4.5 | Mort: 7%', '+30 Conhecimento'),
      _towerEntry(8, 'Moral', 'O Tribunal dos Pecados',
          'A Torre julga invasores. Segredos revelados.', 'Dif: 6.0 | Mort: 5%', '+/-20 Moral'),
      _towerEntry(9, 'Estrategico', 'A Fortaleza das Sombras',
          'Inimigos inteligentes. Estrategia > Forca.', 'Dif: 7.0 | Mort: 15%', '+15 Ferro, +15 Pedra'),
      _towerEntry(10, 'CHEFE', 'O GUARDIAO DO PRIMEIRO UMBRAL',
          'Entidade massiva. Requer preparacao maxima.', 'Dif: 10.0 | Mort: 20%', '+50 todos, expansao'),
    ];
  }

  List<Widget> _buildEdificiosContent() {
    return [
      _sectionTitle('EDIFICIOS DA CIDADELA'),
      _paragraph('Construidos automaticamente quando recursos estao disponiveis. Cada um oferece bonus unicos:'),
      const SizedBox(height: 8),
      _buildingEntry('Fogueira', 'Madeira: 5', '+1 moral/dia. Centro social da comunidade.'),
      _buildingEntry('Tenda', 'Madeira: 10', '+3 capacidade de populacao. Abrigo basico.'),
      _buildingEntry('Armazem', 'Madeira: 15, Pedra: 10', '+50 capacidade de armazenamento de recursos.'),
      _buildingEntry('Cozinha', 'Madeira: 10, Pedra: 5', '+3 comida/dia por cozinheiro ativo.'),
      _buildingEntry('Enfermaria', 'Madeira: 15, Pedra: 10, Conhec.: 5', 'Cura feridos, reduz mortes em expedicoes.'),
      _buildingEntry('Oficina', 'Madeira: 20, Pedra: 15, Ferro: 5', 'Produz equipamentos basicos de trabalho.'),
      _buildingEntry('Escola', 'Madeira: 15, Pedra: 10, Conhec.: 10', '+1 conhecimento/dia. Treina a nova geracao.'),
      _buildingEntry('Forja', 'Pedra: 25, Ferro: 15, Conhec.: 5', 'Produz armas e armaduras. +1 ferro/dia.'),
      _buildingEntry('Mercado', 'Madeira: 20, Pedra: 15', 'Troca eficiente de recursos entre moradores.'),
      _buildingEntry('Quartel', 'Madeira: 25, Pedra: 20, Ferro: 10', 'Treina guardas. +2 Forca para soldados.'),
      _buildingEntry('Biblioteca', 'Madeira: 20, Pedra: 15, Conhec.: 15', '+3 conhecimento/dia. Arquivo do saber.'),
      _buildingEntry('Fazenda', 'Madeira: 15, Pedra: 5', '+5 comida/dia. Fonte constante de alimento.'),
      _buildingEntry('Muralha', 'Pedra: 30, Ferro: 10', 'Defesa contra ameacas externas.'),
      _buildingEntry('Torre de Vigia', 'Madeira: 15, Pedra: 25, Ferro: 5', 'Alerta antecipado de perigos.'),
      _buildingEntry('Templo', 'Pedra: 30, Madeira: 20, Conhec.: 20', '+2 moral/dia, +0.5 sanidade para todos.'),
      _buildingEntry('Campo de Treino', 'Madeira: 25, Pedra: 20, Ferro: 10, Conhec.: 10',
          'Treino seguro, menor risco de morte, cria instrutores veteranos.'),
    ];
  }

  List<Widget> _buildCidadelaContent() {
    return [
      _sectionTitle('NIVEIS DE EVOLUCAO DA CIDADELA'),
      _paragraph('A cidadela evolui automaticamente quando recursos e populacao sao suficientes:'),
      const SizedBox(height: 8),
      _codexEntry('Abrigo (Nivel 1)', 'Inicio. Max 3 edificios. O basico para nao morrer no primeiro dia.'),
      _codexEntry('Acampamento (Nivel 2)', 'Max 6 edificios. Requer 8 habitantes. Custo: 50 Mad, 30 Ped, 30 Com.'),
      _codexEntry('Vila (Nivel 3)', 'Max 10 edificios. Requer 15 habitantes. Custo: 100 Mad, 80 Ped, 20 Fer, 15 Con.'),
      _codexEntry('Cidade (Nivel 4)', 'Max 16 edificios. Requer 30 habitantes. Custo: 200 Mad, 150 Ped, 50 Fer, 40 Con.'),
      _codexEntry('Reino (Nivel 5)', 'Max 25 edificios. Requer 60 habitantes. Custo: 400 Mad, 300 Ped, 100 Fer, 80 Con.'),
      const SizedBox(height: 12),
      _paragraph('Cada evolucao aumenta a capacidade de populacao em +10.'),
    ];
  }

  List<Widget> _buildRecursosContent() {
    return [
      _sectionTitle('RECURSOS'),
      _paragraph('A cidadela gerencia 6 recursos vitais para a sobrevivencia:'),
      const SizedBox(height: 8),
      _codexEntry('Comida', 'Consumo: 1.5 por habitante/dia. Se acabar, fome causa -3 sanidade, -0.2 resistencia e 5% chance de morte. Produzida por fazendeiros (+3/dia cada), Fazenda (+5/dia), Cozinha + cozinheiros (+3/dia cada).',
          color: AppTheme.green),
      _codexEntry('Madeira', 'Material de construcao basico. Produzida por construtores (+2/dia cada). Base: +1/dia.',
          color: AppTheme.orange),
      _codexEntry('Pedra', 'Construcao avancada. Produzida por construtores (+1/dia cada). Base: +0.5/dia.',
          color: AppTheme.textSecondary),
      _codexEntry('Ferro', 'Armas, ferramentas e estruturas avancadas. Forja: +1/dia. Obtido em recompensas da Torre.',
          color: AppTheme.blue),
      _codexEntry('Conhecimento', 'Pesquisa e evolucao. Escribas (+1.5/dia), Biblioteca (+3/dia). Base: +0.2/dia.',
          color: AppTheme.purple),
      _codexEntry('Moral', 'Espirito coletivo (0-100). Fogueira (+1/dia), Templo (+2/dia). Afeta sanidade de todos. Abaixo de 30: -2 sanidade/dia para todos.',
          color: AppTheme.yellow),
    ];
  }

  List<Widget> _buildEventosContent() {
    return [
      _sectionTitle('TIPOS DE EVENTOS'),
      _paragraph('Os registros categorizam eventos pela seguinte tipologia:'),
      const SizedBox(height: 8),
      _eventEntry('Combate', 'Batalhas nos andares da Torre ou conflitos internos.', AppTheme.red),
      _eventEntry('Morte', 'Falecimento de um habitante. Causa cascata de efeitos negativos.', AppTheme.red),
      _eventEntry('Nascimento', 'Novo membro da sociedade. Herda atributos dos pais.', AppTheme.green),
      _eventEntry('Descoberta', 'Algo novo encontrado: inscricoes, talentos, recursos.', AppTheme.cyan),
      _eventEntry('Crise', 'Fome, conflitos, escassez. Ameacas ao coletivo.', AppTheme.orange),
      _eventEntry('Celebracao', 'Momentos de alegria. Restaura moral da comunidade.', AppTheme.yellow),
      _eventEntry('Traicao', 'Rebeliao ou quebra de confianca entre moradores.', AppTheme.pink),
      _eventEntry('Romance', 'Formacao de vinculos amorosos entre NPCs.', AppTheme.pink),
      _eventEntry('Construcao', 'Novo edificio construido na cidadela.', AppTheme.blue),
      _eventEntry('Exploracao', 'Incursao em andares da Torre.', AppTheme.cyan),
      _eventEntry('Colapso Mental', 'NPC sofre quebra psicologica. Veja "Estado Mental".', AppTheme.purple),
      _eventEntry('Torre Conquistada', 'Andar da Torre superado com sucesso.', AppTheme.green),
      _eventEntry('Evolucao', 'Cidadela evoluiu de nivel.', AppTheme.green),
      _eventEntry('Recursos Ganhos', 'Descoberta de suprimentos extras.', AppTheme.green),
      _eventEntry('Recursos Perdidos', 'Tempestade ou desastre danificou estoques.', AppTheme.orange),
      _eventEntry('Treino', 'Moradores treinaram em andares conquistados.', AppTheme.blue),
      _eventEntry('Sistema', 'Mensagens do jogo (invocacao, game over, etc).', AppTheme.textDim),
    ];
  }

  List<Widget> _buildMecanicasContent() {
    return [
      _sectionTitle('MECANICAS DO JOGO'),
      const SizedBox(height: 8),
      _sectionTitle('SIMULACAO TEMPORAL CONTINUA'),
      _paragraph(
        'O jogo usa um sistema de tempo continuo baseado em timestamps reais. '
        'Nao depende de ticks fixos — a cada segundo real, o sistema calcula '
        'deltaRealSeconds x 2 x velocidade para obter o tempo na Torre. '
        'Quando o tempo acumulado (gameSeconds) atinge 86400 (24h in-game), '
        'um dia completo e processado: recursos, relacionamentos, saude mental, '
        'eventos aleatorios, gravidezes, envelhecimento e treino. '
        'O sistema funciona mesmo com o jogo fechado (offline progress).',
      ),
      const SizedBox(height: 12),
      _sectionTitle('EXPLORACOES AUTONOMAS'),
      _paragraph(
        'A cada ~28 dias in-game, os NPCs avaliam se estao prontos para explorar. '
        'Guardas, Exploradores e Batedores com sanidade > 25 sao candidatos prioritarios. '
        'Outros NPCs com poder de combate > 4.0 e sanidade > 30 complementam. '
        'Se o poder total alcanca 60% do recomendado, a expedicao parte.',
      ),
      const SizedBox(height: 12),
      _sectionTitle('SISTEMA DE RELACIONAMENTOS'),
      _paragraph(
        '15% de chance por dia de dois NPCs interagirem. Afinidade cresce com carisma. '
        'Quando afinidade > 0.7, ambos solteiros, formam um casal. '
        'Casais podem ter filhos se: comida > 20, moral > 40, populacao < capacidade, '
        'afinidade > 0.6. Chance: 3% por dia.',
      ),
      const SizedBox(height: 12),
      _sectionTitle('HERANCA E MUTACAO'),
      _paragraph(
        'Filhos herdam a media dos atributos dos pais. 10% chance de mutacao por atributo '
        '(variacao de +/- 3 pontos). Talentos: 20% chance de herdar talento do pai/mae, '
        '8% chance de talento completamente novo. Tracos de personalidade herdados aleatoriamente.',
      ),
      const SizedBox(height: 12),
      _sectionTitle('CRESCIMENTO (GERACAO 2+)'),
      _paragraph(
        'NPCs nascidos na Torre comecam com 0 anos. A cada 30 dias, envelhecem 1 ano. '
        'Antes dos 16 anos, ganham +0.3 FOR/AGI/RES e +0.2 INT por ano. '
        'Apos 60 anos: -0.2 FOR/AGI e -0.3 RES por ano, com 2% chance de morte natural.',
      ),
      const SizedBox(height: 12),
      _sectionTitle('CONSTRUCAO E EVOLUCAO AUTOMATICA'),
      _paragraph(
        'A cidadela constroi edificios e evolui automaticamente quando recursos sao '
        'suficientes. Prioridade: Fazenda > Cozinha > Enfermaria > Forja > Escola > outros. '
        'Evolucao da cidadela acontece quando populacao e recursos atingem os requisitos.',
      ),
      const SizedBox(height: 12),
      _sectionTitle('COMBATE NA TORRE'),
      _paragraph(
        'Poder total do grupo vs Dificuldade x Tamanho do grupo. '
        'Chance de sucesso = (ratio x 0.6 + 0.2), limitada entre 10% e 95%. '
        'Vitoria: sobreviventes ganham +FOR, +RES, +Fama, -2 Sanidade. '
        'Mortalidade reduzida em vitoria (50% da base). '
        'Derrota: mortalidade total, -5 Sanidade, -0.3 RES para sobreviventes, -8 Moral.',
      ),
    ];
  }

  // ====== NOVAS MECANICAS ======

  List<Widget> _buildLealdadeContent() {
    return [
      _sectionTitle('SISTEMA DE LEALDADE'),
      _paragraph('Cada NPC possui um valor de lealdade (0-100) que afeta sua cooperacao:'),
      const SizedBox(height: 8),
      _codexEntry('Lealdade Alta (70-100)', 'NPC aceita sugestoes, trabalha com empenho, defende o grupo.', color: AppTheme.green),
      _codexEntry('Lealdade Media (40-69)', 'Comportamento normal. Pode aceitar ou recusar sugestoes.', color: AppTheme.yellow),
      _codexEntry('Lealdade Baixa (0-39)', 'NPC resiste a ordens, risco de traicao elevado.', color: AppTheme.red),
      const SizedBox(height: 12),
      _sectionTitle('FATORES DE LEALDADE'),
      _entryRow('Moral alta (>70)', '+0.1/dia'),
      _entryRow('Moral baixa (<30)', '-0.3/dia'),
      _entryRow('Comida abundante', '+0.05/dia'),
      _entryRow('Traco Leal', '+0.1/dia'),
      _entryRow('Traco Traicoeiro', '-0.1/dia'),
      _entryRow('Origem obscura', '-0.05/dia'),
      _entryRow('Membro de grupo', '+0.05/dia'),
      _entryRow('Vitoria na Torre', '+3 por vitoria'),
      _entryRow('Derrota na Torre', '-2 por derrota'),
      const SizedBox(height: 12),
      _sectionTitle('RISCO DE TRAICAO'),
      _paragraph(
        'O risco de traicao e calculado automaticamente baseado em: '
        'origem obscura (+25%), traco traicoeiro (+20%), baixa lealdade, '
        'baixa sanidade (<30: +15%), e traumas acumulados.'
      ),
      const SizedBox(height: 8),
      _sectionTitle('TIPOS DE TRAICAO'),
      _codexEntry('Roubo', 'Rouba 5-20 de comida dos estoques.', color: AppTheme.orange),
      _codexEntry('Sabotagem', 'Danifica equipamentos. -8 moral.', color: AppTheme.orange),
      _codexEntry('Manipulacao', 'Espalha rumores, reduz lealdade de outros.', color: AppTheme.orange),
      _codexEntry('Assassinato', 'Apenas assassinos. Pode matar NPCs famosos!', color: AppTheme.red),
    ];
  }

  List<Widget> _buildGruposContent() {
    return [
      _sectionTitle('SISTEMA DE ESQUADROES'),
      _paragraph(
        'Organize NPCs em grupos para coordenar expedicoes e treinos. '
        'Grupos aumentam coesao, lealdade e eficiencia.'
      ),
      const SizedBox(height: 8),
      _sectionTitle('FUNCOES DE GRUPO'),
      _codexEntry('Geral', 'Grupo multiuso sem especializacao.'),
      _codexEntry('Assalto', 'Focado em combate. Ideal para explorar novos andares.'),
      _codexEntry('Reconhecimento', 'Focado em exploracao. Ideal para re-exploracao.'),
      _codexEntry('Treinamento', 'Focado em evolucao. Ideal para sessoes de treino.'),
      _codexEntry('Defesa', 'Focado em protecao. Ideal para defesa da cidadela.'),
      const SizedBox(height: 12),
      _sectionTitle('COESAO DE GRUPO'),
      _paragraph(
        'Grupos ganham coesao ao longo do tempo e com missoes bem-sucedidas. '
        'Membros do mesmo grupo formam lacos mais rapido. '
        'Coesao alta melhora performance em combate e treino.'
      ),
    ];
  }

  List<Widget> _buildTreinoContent() {
    return [
      _sectionTitle('SISTEMA DE TREINO'),
      _paragraph('O treino tem 3 camadas de controle:'),
      const SizedBox(height: 8),
      _codexEntry('1. Jogador designa ascensao', 'Voce decide quem sobe novos andares. Decisao final.'),
      _codexEntry('2. Jogador sugere treino', 'Voce sugere NPCs ou grupos para treinar. Eles decidem se aceitam.'),
      _codexEntry('3. NPCs decidem autonomamente', 'NPCs treinam por conta propria em andares conquistados (~15% chance a cada 5 dias).'),
      const SizedBox(height: 12),
      _sectionTitle('RESPOSTAS A SUGESTOES'),
      _codexEntry('Aceitar', 'NPC treina conforme sugerido. +2 lealdade.', color: AppTheme.green),
      _codexEntry('Recusar', 'NPC se nega. Motivo baseado em personalidade. -1 lealdade.', color: AppTheme.red),
      _codexEntry('Negociar', 'NPC aceita com condicoes ("descanso depois").', color: AppTheme.yellow),
      _codexEntry('Ignorar', 'NPC simplesmente ignora.', color: AppTheme.textDim),
      _codexEntry('Persuadir', 'NPC convence outros a treinar junto.', color: AppTheme.blue),
      const SizedBox(height: 12),
      _sectionTitle('CAMPO DE TREINO (Edificio)'),
      _paragraph(
        'O Campo de Treino reduz risco de morte (0.5% vs ~3% em andares), '
        'mas oferece ganhos menores. Cria instrutores veteranos. '
        'Pode causar disputas e hierarquias internas.'
      ),
      const SizedBox(height: 12),
      _sectionTitle('TREINO EM ANDARES CONQUISTADOS'),
      _paragraph(
        'Treinar em andares ja conquistados oferece ganhos maiores, '
        'mas pode reativar ameacas ocultas (~4% chance), '
        'gerar acidentes (~3%), ou revelar descobertas raras (~5%).'
      ),
    ];
  }

  List<Widget> _buildReexploracaoContent() {
    return [
      _sectionTitle('RE-EXPLORACAO DE ANDARES'),
      _paragraph(
        'Andares conquistados podem ser revisitados para coletar recursos. '
        'Cada andar possui fauna e flora unica que gera recursos diferentes.'
      ),
      const SizedBox(height: 8),
      _sectionTitle('RECURSOS POR ANDAR'),
      _codexEntry('Andar 1 - Ruinas', 'Madeira: ~8, Pedra: ~5, Comida: ~3'),
      _codexEntry('Andar 2 - Corredor', 'Comida: ~10, Ferro: ~2'),
      _codexEntry('Andar 3 - Espelhos', 'Conhecimento: ~8, Comida: ~3'),
      _codexEntry('Andar 4 - Labirinto', 'Ferro: ~5, Conhecimento: ~5'),
      _codexEntry('Andar 5 - Arena', 'Ferro: ~8, Pedra: ~3'),
      _codexEntry('Andar 6 - Pantano', 'Comida: ~15, Conhecimento: ~3'),
      _codexEntry('Andar 7 - Biblioteca', 'Conhecimento: ~15'),
      _codexEntry('Andar 8 - Tribunal', 'Conhecimento: ~5, Comida: ~5'),
      _codexEntry('Andar 9 - Fortaleza', 'Ferro: ~8, Pedra: ~8'),
      _codexEntry('Andar 10 - Guardiao', 'Todos: ~10 cada'),
      const SizedBox(height: 12),
      _sectionTitle('RISCOS'),
      _paragraph(
        'Ameacas ocultas podem reaparecer (5% base + 2% por re-exploracao anterior). '
        'Novas criaturas surgem, acidentes podem ocorrer, mas tambem descobertas raras.'
      ),
    ];
  }

  List<Widget> _buildInvocacaoContent() {
    return [
      _sectionTitle('INVOCACAO EMERGENCIAL'),
      _paragraph(
        'Quando a populacao cai para 5 ou menos, a Torre detecta o risco de extincao '
        'e invoca automaticamente 1-3 novos humanos a cada 14 dias.'
      ),
      const SizedBox(height: 8),
      _codexEntry('Condicao', 'Populacao <= 5 habitantes vivos'),
      _codexEntry('Frequencia', 'A cada 14 dias enquanto condicao persistir'),
      _codexEntry('Quantidade', '1 a 3 novos NPCs por invocacao'),
      _codexEntry('RISCO', 'Invocados emergenciais podem ter origens obscuras! Vigiar com atencao.', color: AppTheme.red),
      const SizedBox(height: 12),
      _paragraph(
        'O sistema garante que NPCs nao sejam repetidos e que a simulacao '
        'continue funcional mesmo em populacoes criticamente baixas. '
        'Permadeath continua valendo - cada morte e permanente.'
      ),
    ];
  }

  List<Widget> _buildPoliticaContent() {
    return [
      _sectionTitle('POLITICA INTERNA'),
      _paragraph(
        'Suas decisoes como lider afetam a dinamica social da Cidadela. '
        'O jogo agora e uma simulacao social + gerenciamento estrategico + sobrevivencia.'
      ),
      const SizedBox(height: 8),
      _sectionTitle('IMPACTO DO JOGADOR'),
      _codexEntry('Favoritismo', 'Sugerir treino sempre para os mesmos NPCs gera ressentimento nos outros. '
          'Se um NPC recebe >5 sugestoes com <30% aceitas, perde lealdade.', color: AppTheme.orange),
      _codexEntry('Inatividade', 'Nunca sugerir treinos faz parecer ausente. NPCs perdem referencia de lideranca.', color: AppTheme.yellow),
      _codexEntry('Perigo Constante', 'Enviar NPCs para missoes perigosas demais corroi confianca. '
          'Mortes reduzem lealdade geral.', color: AppTheme.red),
      const SizedBox(height: 12),
      _sectionTitle('EVENTOS POLITICOS'),
      _paragraph(
        'NPCs famosos (fama >10) podem inspirar (+3 moral) ou aterrorizar (-2 moral) a comunidade. '
        'Conflitos entre NPCs reduzem lealdade de ambos. '
        'Nascimentos aumentam lealdade geral (+0.5 para todos). '
        'Evolucao da Cidadela aumenta lealdade (+3 para todos).'
      ),
      const SizedBox(height: 12),
      _sectionTitle('HIERARQUIA DE CONTROLE'),
      _codexEntry('Nivel 1', 'Jogador decide quem ascende novos andares.'),
      _codexEntry('Nivel 2', 'Jogador sugere treinos (NPCs podem recusar).'),
      _codexEntry('Nivel 3', 'NPCs decidem autonomamente sobre treino e relacionamentos.'),
    ];
  }

  // ====== Helper Widgets ======

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TerminalText('// $title', fontSize: 12, color: AppTheme.cyan, fontWeight: FontWeight.bold),
          const SizedBox(height: 4),
          Container(height: 1, color: AppTheme.cyan.withValues(alpha: 0.3)),
        ],
      ),
    );
  }

  Widget _paragraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: TerminalText(text, fontSize: 10, color: AppTheme.textSecondary),
    );
  }

  Widget _codexEntry(String term, String definition, {Color? color}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.bgElevated,
        border: Border.all(color: (color ?? AppTheme.border).withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TerminalText(term, fontSize: 10, color: color ?? AppTheme.cyan, fontWeight: FontWeight.bold),
          const SizedBox(height: 3),
          TerminalText(definition, fontSize: 9, color: AppTheme.textSecondary),
        ],
      ),
    );
  }

  Widget _entryRow(String key, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 140, child: TerminalText(key, fontSize: 9, color: AppTheme.cyan)),
          Expanded(child: TerminalText(value, fontSize: 9, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _towerEntry(int num, String type, String name, String desc, String stats, String reward) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.bgElevated,
        border: Border.all(
          color: num == 10
              ? AppTheme.red.withValues(alpha: 0.5)
              : AppTheme.border.withValues(alpha: 0.4),
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TerminalText('ANDAR ${num.toString().padLeft(2, '0')}', fontSize: 10, color: AppTheme.cyan, fontWeight: FontWeight.bold),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.yellow.withValues(alpha: 0.5)),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: TerminalText(type, fontSize: 8, color: AppTheme.yellow),
              ),
              const Spacer(),
              TerminalText(stats, fontSize: 8, color: AppTheme.red),
            ],
          ),
          const SizedBox(height: 4),
          TerminalText(name, fontSize: 10, color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
          TerminalText(desc, fontSize: 9, color: AppTheme.textSecondary),
          const SizedBox(height: 3),
          TerminalText('Recompensa: $reward', fontSize: 8, color: AppTheme.green),
        ],
      ),
    );
  }

  Widget _buildingEntry(String name, String cost, String effect) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.bgElevated,
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: TerminalText(name, fontSize: 10, color: AppTheme.cyan, fontWeight: FontWeight.bold)),
              TerminalText('Custo: $cost', fontSize: 8, color: AppTheme.orange),
            ],
          ),
          const SizedBox(height: 3),
          TerminalText(effect, fontSize: 9, color: AppTheme.textSecondary),
        ],
      ),
    );
  }

  Widget _eventEntry(String name, String desc, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 5, right: 8),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TerminalText(name, fontSize: 10, color: color, fontWeight: FontWeight.bold),
                TerminalText(desc, fontSize: 9, color: AppTheme.textSecondary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
