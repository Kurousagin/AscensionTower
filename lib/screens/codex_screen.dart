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
    'ociosidade': 'Ociosidade',
    'evolucao': 'Evolucao de Edificios',
    'crescimento': 'Crescimento Passivo',
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
      case 'ociosidade':
        return _buildOciosidadeContent();
      case 'evolucao':
        return _buildEvolucaoContent();
      case 'crescimento':
        return _buildCrescimentoContent();
      default:
        return [
          const TerminalText(
            'Selecione uma categoria.',
            color: AppTheme.textDim,
          ),
        ];
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
        'O tempo flui continuamente baseado em timestamps reais — nao depende de ticks fixos.',
      ),
      const SizedBox(height: 8),
      _codexEntry(
        'Formula',
        'deltaGameSeconds = deltaRealSeconds x 2 x velocidade',
        color: AppTheme.cyan,
      ),
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
        'Offline usa velocidade 1x (ratio base) para manter o equilibrio.',
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
      _paragraph(
        'Cada NPC possui 6 atributos que definem suas capacidades e limitacoes:',
      ),
      const SizedBox(height: 8),
      _codexEntry(
        'Forca (FOR)',
        'Poder fisico bruto. Influencia combate, construcao e trabalho pesado. Escala 1-15.',
      ),
      _codexEntry(
        'Agilidade (AGI)',
        'Velocidade e reflexos. Afeta esquiva, exploracao e eficiencia em tarefas rapidas. Escala 1-15.',
      ),
      _codexEntry(
        'Inteligencia (INT)',
        'Capacidade mental. Essencial para estrategia, pesquisa e producao de conhecimento. Escala 1-15.',
      ),
      _codexEntry(
        'Resistencia (RES)',
        'Vigor fisico e capacidade de suportar danos. Influencia sobrevivencia e duracao. Escala 1-15.',
      ),
      _codexEntry(
        'Carisma (CAR)',
        'Habilidade social. Afeta relacionamentos, lideranca e moral. Escala 1-15.',
      ),
      _codexEntry(
        'Sanidade Mental (SAN)',
        'Estabilidade psicologica. Escala 0-100. Abaixo de 15, riscos de colapso mental.',
      ),
      const SizedBox(height: 12),
      _sectionTitle('FORMULAS DERIVADAS'),
      _codexEntry(
        'Poder de Combate',
        'FOR x 0.30 + AGI x 0.25 + RES x 0.25 + INT x 0.20',
      ),
      _codexEntry('Media Geral', '(FOR + AGI + INT + RES + CAR) / 5'),
      _codexEntry(
        'Score de Sobrevivencia',
        'RES x 0.30 + FOR x 0.20 + AGI x 0.20 + INT x 0.15 + SAN x 0.015',
      ),
    ];
  }

  List<Widget> _buildProfissoesContent() {
    return [
      _sectionTitle('PROFISSOES DA CIDADELA'),
      _paragraph(
        'Os NPCs escolhem profissoes AUTONOMAMENTE baseado em seus atributos, personalidade, '
        'origens e necessidades da cidadela. Voce nao atribui diretamente - eles decidem!',
      ),
      const SizedBox(height: 8),
      _sectionTitle('ESCOLHA AUTONOMA'),
      _paragraph(
        'A cada 3 dias, NPCs adultos ociosos avaliam se querem escolher uma profissao. '
        'A decisao e influenciada por: personalidade (ambiciosos escolhem rapido, preguicosos resistem), '
        'tempo ocioso (pressao aumenta apos 14 dias), necessidades da cidadela (preferem profissoes carentes), '
        'aptidoes naturais (ex-farmers preferem ser fazendeiros) e moral geral.',
      ),
      const SizedBox(height: 12),
      _sectionTitle('LISTA DE PROFISSOES'),
      _codexEntry(
        'Ocioso',
        'Sem funcao atribuida. Sofre penalidades por ociosidade prolongada.',
        color: AppTheme.textDim,
      ),
      _codexEntry(
        'Explorador',
        'Participa de expedicoes na Torre. Selecionado por alto poder de combate.',
      ),
      _codexEntry(
        'Guarda',
        'Protege a cidadela e participa de expedicoes. Treina Forca e Resistencia automaticamente.',
      ),
      _codexEntry(
        'Cozinheiro',
        'Produz comida extra quando a Cozinha esta construida (+3 comida/dia por chef).',
      ),
      _codexEntry(
        'Medico',
        'Cuida de feridos. Reduz mortalidade quando a Enfermaria esta construida.',
      ),
      _codexEntry(
        'Professor',
        'Educa jovens e treina Inteligencia. Funciona com a Escola construida.',
      ),
      _codexEntry(
        'Ferreiro',
        'Produz armas e ferramentas. Requer a Forja construida.',
      ),
      _codexEntry(
        'Mercador',
        'Gerencia troca de recursos. Funciona com o Mercado construido.',
      ),
      _codexEntry(
        'Escriba',
        'Gera conhecimento (+1.5/dia). Selecionado pela alta inteligencia.',
      ),
      _codexEntry(
        'Fazendeiro',
        'Produz comida (+3 comida/dia por fazendeiro). Vital para a sobrevivencia.',
      ),
      _codexEntry(
        'Construtor',
        'Produz madeira (+2/dia) e pedra (+1/dia). Essencial para edificar.',
      ),
      _codexEntry(
        'Batedor',
        'Reconhecimento e exploracao. Treina Agilidade automaticamente.',
      ),
    ];
  }

  List<Widget> _buildOrigensContent() {
    return [
      _sectionTitle('ORIGENS DOS INVOCADOS'),
      _paragraph(
        'Cada NPC chega com uma profissao do mundo real que define seus atributos base:',
      ),
      const SizedBox(height: 8),
      _codexEntry(
        'Estudante',
        'FOR: 3 | AGI: 4 | INT: 8 | RES: 3 | CAR: 5 | SAN: 60',
      ),
      _codexEntry(
        'Chef',
        'FOR: 4 | AGI: 6 | INT: 6 | RES: 5 | CAR: 7 | SAN: 65',
      ),
      _codexEntry(
        'Soldado',
        'FOR: 9 | AGI: 7 | INT: 5 | RES: 9 | CAR: 4 | SAN: 75',
      ),
      _codexEntry(
        'Programador',
        'FOR: 2 | AGI: 3 | INT: 9 | RES: 3 | CAR: 4 | SAN: 55',
      ),
      _codexEntry(
        'Atleta',
        'FOR: 8 | AGI: 9 | INT: 4 | RES: 8 | CAR: 6 | SAN: 70',
      ),
      _codexEntry(
        'Empresario',
        'FOR: 4 | AGI: 4 | INT: 7 | RES: 5 | CAR: 9 | SAN: 68',
      ),
      _codexEntry(
        'Medico',
        'FOR: 3 | AGI: 5 | INT: 9 | RES: 5 | CAR: 6 | SAN: 72',
      ),
      _codexEntry(
        'Professor',
        'FOR: 3 | AGI: 4 | INT: 8 | RES: 4 | CAR: 8 | SAN: 70',
      ),
      _codexEntry(
        'Artista',
        'FOR: 3 | AGI: 5 | INT: 7 | RES: 3 | CAR: 8 | SAN: 50',
      ),
      _codexEntry(
        'Mecanico',
        'FOR: 7 | AGI: 6 | INT: 6 | RES: 7 | CAR: 4 | SAN: 65',
      ),
      _codexEntry(
        'Fazendeiro',
        'FOR: 7 | AGI: 5 | INT: 4 | RES: 8 | CAR: 5 | SAN: 75',
      ),
      _codexEntry(
        'Musico',
        'FOR: 3 | AGI: 5 | INT: 6 | RES: 3 | CAR: 9 | SAN: 55',
      ),
      _codexEntry(
        'Cientista',
        'FOR: 2 | AGI: 3 | INT: 10 | RES: 4 | CAR: 4 | SAN: 60',
      ),
      _codexEntry(
        'Bombeiro',
        'FOR: 8 | AGI: 7 | INT: 5 | RES: 9 | CAR: 6 | SAN: 78',
      ),
      _codexEntry(
        'Enfermeiro(a)',
        'FOR: 4 | AGI: 5 | INT: 7 | RES: 6 | CAR: 7 | SAN: 70',
      ),
      const SizedBox(height: 12),
      _sectionTitle('ORIGENS OBSCURAS (Perigo!)'),
      _paragraph(
        'Invocados com passado criminoso. Fortes em certas areas, mas risco de traicao elevado:',
      ),
      const SizedBox(height: 8),
      _codexEntry(
        'Ladrao',
        'FOR: 4 | AGI: 9 | INT: 7 | RES: 5 | CAR: 6 | SAN: 55 | Risco base: +25%',
        color: AppTheme.red,
      ),
      _codexEntry(
        'Assassino',
        'FOR: 8 | AGI: 10 | INT: 6 | RES: 7 | CAR: 3 | SAN: 45 | Pode matar NPCs!',
        color: AppTheme.red,
      ),
      _codexEntry(
        'Estelionatario',
        'FOR: 3 | AGI: 5 | INT: 9 | RES: 3 | CAR: 10 | SAN: 50 | Manipula lealdade',
        color: AppTheme.red,
      ),
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
      _codexEntry(
        'Genio do Combate',
        '+50% poder de combate. Transforma um NPC comum em uma maquina de guerra.',
      ),
      _codexEntry(
        'Toque Curativo',
        'Cura aliados apos batalha. Restaura Resistencia e Sanidade dos sobreviventes.',
      ),
      _codexEntry(
        'Mente Estrategica',
        'Reduz mortalidade do grupo em 15%. O estrategista nunca e dispensavel.',
      ),
      _codexEntry(
        'Lider Natural',
        '+20% moral do grupo. Inspira outros e eleva o espirito coletivo.',
      ),
      _codexEntry(
        'Sussurrador de Feras',
        'Chance de domar criaturas hostis nos andares de combate.',
      ),
      _codexEntry(
        'Mestre da Forja',
        'Equipamentos produzidos sao 2x mais eficientes.',
      ),
      _codexEntry(
        'Herbalista',
        'Produz medicamentos naturais com plantas encontradas na Torre.',
      ),
      _codexEntry(
        'Leitor de Runas',
        'Revela segredos e informacoes ocultas dos andares da Torre.',
      ),
      _codexEntry(
        'Caminhante das Sombras',
        'Pode evadir qualquer combate. O NPC perfeito para reconhecimento.',
      ),
      _codexEntry(
        'Vontade de Ferro',
        'Imune a perda de sanidade. Nunca sofre colapso mental.',
      ),
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
      _codexEntry(
        'Corajoso',
        'Bonus de +10% poder de combate. Avanca sem hesitar.',
      ),
      _codexEntry(
        'Covarde',
        'Penalidade de -15% poder de combate. Tende a fugir do perigo.',
      ),
      _codexEntry(
        'Lider',
        'Melhora a moral do grupo. Tomador de decisoes natural.',
      ),
      _codexEntry(
        'Solitario',
        'Prefere estar sozinho. Menor chance de formar relacionamentos.',
      ),
      _codexEntry(
        'Compassivo',
        'Cuida dos outros. Bonus em interacoes sociais e cura.',
      ),
      _codexEntry(
        'Implacavel',
        'Frio e calculista. Prioriza eficiencia sobre emocao.',
      ),
      _codexEntry(
        'Otimista',
        'Recupera +0.5 sanidade/dia naturalmente. Ve o lado bom.',
      ),
      _codexEntry(
        'Pessimista',
        'Perde -0.5 sanidade/dia. Ve tudo como condenado.',
      ),
      _codexEntry(
        'Analitico',
        'Bonus em andares estrategicos. Pensa antes de agir.',
      ),
      _codexEntry(
        'Impulsivo',
        'Age sem pensar. Pode causar problemas ou acertos inesperados.',
      ),
      _codexEntry('Leal', 'Bonus de afinidade com aliados. Nunca trai.'),
      _codexEntry('Traicoeiro', 'Pode trair aliados em momentos de crise.'),
      _codexEntry(
        'Calmo',
        'Resiste melhor a pressao. Menos vulneravel a colapso.',
      ),
      _codexEntry(
        'Agressivo',
        'Mais forte em combate, mas propenso a surtos violentos.',
      ),
      _codexEntry(
        'Criativo',
        'Encontra solucoes inesperadas. Bonus em andares de misterio.',
      ),
      _codexEntry(
        'Pragmatico',
        'Eficiente e pratico. Faz o que precisa ser feito.',
      ),
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
      _codexEntry(
        'Estavel (70-100)',
        'NPC funciona normalmente. Contribui com eficiencia total.',
        color: AppTheme.green,
      ),
      _codexEntry(
        'Estressado (55-69)',
        'Leve tensao. Performance ligeiramente reduzida.',
        color: AppTheme.yellow,
      ),
      _codexEntry(
        'Deprimido (40-54)',
        'Perda de motivacao. Pode parar de trabalhar.',
        color: AppTheme.blue,
      ),
      _codexEntry(
        'Rebelde (25-39)',
        'Ressentimento contra a sociedade. Pode destruir recursos.',
        color: AppTheme.orange,
      ),
      _codexEntry(
        'Isolado (15-24)',
        'Retirada total. Nao interage com ninguem. Risco critico.',
        color: AppTheme.textDim,
      ),
      _codexEntry(
        'Descontrolado (5-14)',
        'Surtos de violencia ou desespero. Perigo para si e outros.',
        color: AppTheme.red,
      ),
      _codexEntry(
        'Quebrado (0-4)',
        'Destruido emocionalmente. Praticamente nao funcional.',
        color: AppTheme.red,
      ),
      const SizedBox(height: 12),
      _sectionTitle('TIPOS DE COLAPSO MENTAL'),
      _paragraph(
        'Quando sanidade cai abaixo de 15, ha 10% de chance por dia de:',
      ),
      const SizedBox(height: 8),
      _codexEntry(
        'Isolamento',
        'NPC se tranca. Profissao vira Ocioso. Adiciona trauma.',
      ),
      _codexEntry(
        'Rebeliao',
        'NPC destroi suprimentos. -10 comida, -5 moral. Trauma.',
      ),
      _codexEntry(
        'Sacrificio Suicida',
        '30% chance de morte: parte sozinho para a Torre. 70%: tenta fugir e desmaia.',
      ),
      _codexEntry(
        'Depressao Profunda',
        'Para de comer/falar. Vira Ocioso, perde -1 Forca.',
      ),
      _codexEntry(
        'Surto Agressivo',
        'Ataca outros moradores. -3 moral. Precisa ser contido.',
      ),
    ];
  }

  List<Widget> _buildTorreContent() {
    return [
      _sectionTitle('ANDARES DA TORRE (MVP: 1-10)'),
      _paragraph(
        'Cada andar possui tipo, dificuldade, taxa de mortalidade e recompensas unicas. '
        'Andares conquistados podem ser REVISITADOS para: (1) Treino de NPCs (ganhos reduzidos, ~3% risco), '
        '(2) Coleta de recursos via expedicoes de grupos (fauna e flora geram recursos). '
        'Re-exploracao tem custos em comida e pode reativar ameacas ocultas.',
      ),
      const SizedBox(height: 8),
      _towerEntry(
        1,
        'Sobrevivencia',
        'As Ruinas Silenciosas',
        'Campo devastado com criaturas rastejantes.',
        'Dif: 2.0 | Mort: 5%',
        '+15 Madeira, +10 Pedra',
      ),
      _towerEntry(
        2,
        'Combate',
        'O Corredor das Bestas',
        'Criaturas deformadas em corredores estreitos.',
        'Dif: 3.0 | Mort: 8%',
        '+20 Comida, +5 Ferro',
      ),
      _towerEntry(
        3,
        'Moral',
        'A Sala dos Espelhos',
        'Espelhos mostram piores medos. Risco de insanidade.',
        'Dif: 2.5 | Mort: 3%',
        '+15 Conhecimento, +10 Moral',
      ),
      _towerEntry(
        4,
        'Estrategico',
        'O Labirinto Mecanico',
        'Engrenagens e armadilhas. Requer INT > 6 no lider.',
        'Dif: 4.0 | Mort: 10%',
        '+10 Ferro, +10 Conhecimento',
      ),
      _towerEntry(
        5,
        'Combate',
        'A Arena Sangrenta',
        'Lutem ou morram. Sem fuga possivel.',
        'Dif: 5.0 | Mort: 12%',
        '+15 Ferro, +20 Fama',
      ),
      _towerEntry(
        6,
        'Sobrevivencia',
        'O Pantano Toxico',
        'Ar venenoso e agua acida. Dano continuo.',
        'Dif: 5.5 | Mort: 10%',
        '+25 Comida, +5 Conhecimento',
      ),
      _towerEntry(
        7,
        'Misterio',
        'A Biblioteca Proibida',
        'Tomos perigosos. Pode revelar talentos ocultos.',
        'Dif: 4.5 | Mort: 7%',
        '+30 Conhecimento',
      ),
      _towerEntry(
        8,
        'Moral',
        'O Tribunal dos Pecados',
        'A Torre julga invasores. Segredos revelados.',
        'Dif: 6.0 | Mort: 5%',
        '+/-20 Moral',
      ),
      _towerEntry(
        9,
        'Estrategico',
        'A Fortaleza das Sombras',
        'Inimigos inteligentes. Estrategia > Forca.',
        'Dif: 7.0 | Mort: 15%',
        '+15 Ferro, +15 Pedra',
      ),
      _towerEntry(
        10,
        'CHEFE',
        'O GUARDIAO DO PRIMEIRO UMBRAL',
        'Entidade massiva. Requer preparacao maxima.',
        'Dif: 10.0 | Mort: 20%',
        '+50 todos, expansao',
      ),
    ];
  }

  List<Widget> _buildEdificiosContent() {
    return [
      _sectionTitle('EDIFICIOS DA CIDADELA'),
      _paragraph(
        'Edificios evoluem AUTOMATICAMENTE quando a cidadela sobe de nivel. '
        'Construcoes obsoletas nao aparecem mais na lista (ex: nao pode construir Tendas se ja tem Casas).',
      ),
      const SizedBox(height: 8),
      _sectionTitle('EDIFICIOS QUE EVOLUEM'),
      _codexEntry(
        'Fogueira → Marco da Vila → Praca Central → Monumento',
        'Bonus de moral escala: +1 → +2 → +3 → +5/dia',
      ),
      _codexEntry(
        'Tenda → Casa → Pousada → Residencia',
        'Capacidade populacional: +2 → +4 → +8 → +15',
      ),
      _codexEntry(
        'Cozinha → Refeitorio → Salao de Banquetes',
        'Producao por chef: +3 → +8 → +15 comida/dia',
      ),
      _codexEntry(
        'Armazem → Deposito → Centro Logistico',
        'Capacidade de recursos: +50% → +100% → +150%',
      ),
      _codexEntry(
        'Fazenda → Plantacao → Fazenda Industrial',
        'Producao: +5 → +12 → +25 comida/dia',
      ),
      _codexEntry(
        'Oficina → Manufatura → Fabrica',
        'Producao de ferro e madeira aumenta',
      ),
      _codexEntry(
        'Forja → Fundicao → Refinaria',
        'Producao de ferro: +2 → +5 → +10/dia',
      ),
      _codexEntry(
        'Quartel → Academia → Complexo de Treino',
        'Treino: +0.3 → +0.5 → +0.8 FOR/dia',
      ),
      const SizedBox(height: 12),
      _sectionTitle('EDIFICIOS FIXOS (NAO EVOLUEM)'),
      _buildingEntry(
        'Enfermaria',
        'Madeira: 15, Pedra: 10, Conhec.: 5',
        'Cura feridos, reduz mortes em expedicoes.',
      ),
      _buildingEntry(
        'Escola',
        'Madeira: 15, Pedra: 10, Conhec.: 10',
        '+1 conhecimento/dia. Treina a nova geracao.',
      ),
      _buildingEntry(
        'Mercado',
        'Madeira: 20, Pedra: 15',
        'Troca eficiente de recursos entre moradores.',
      ),
      _buildingEntry(
        'Biblioteca',
        'Madeira: 20, Pedra: 15, Conhec.: 15',
        '+3 conhecimento/dia. Arquivo do saber.',
      ),
      _buildingEntry(
        'Muralha',
        'Pedra: 30, Ferro: 10',
        'Defesa contra ameacas externas.',
      ),
      _buildingEntry(
        'Torre de Vigia',
        'Madeira: 15, Pedra: 25, Ferro: 5',
        'Alerta antecipado de perigos.',
      ),
      _buildingEntry(
        'Templo',
        'Pedra: 30, Madeira: 20, Conhec.: 20',
        '+2 moral/dia, +0.5 sanidade para todos.',
      ),
      _buildingEntry(
        'Campo de Treino',
        'Madeira: 25, Pedra: 20, Ferro: 10, Conhec.: 10',
        'Treino seguro, menor risco de morte, cria instrutores veteranos.',
      ),
    ];
  }

  List<Widget> _buildCidadelaContent() {
    return [
      _sectionTitle('NIVEIS DE EVOLUCAO DA CIDADELA'),
      _paragraph(
        'A cidadela evolui automaticamente quando recursos e populacao sao suficientes:',
      ),
      const SizedBox(height: 8),
      _codexEntry(
        'Abrigo (Nivel 1)',
        'Inicio. Max 3 edificios. O basico para nao morrer no primeiro dia.',
      ),
      _codexEntry(
        'Acampamento (Nivel 2)',
        'Max 6 edificios. Requer 8 habitantes. Custo: 50 Mad, 30 Ped, 30 Com.',
      ),
      _codexEntry(
        'Vila (Nivel 3)',
        'Max 10 edificios. Requer 15 habitantes. Custo: 100 Mad, 80 Ped, 20 Fer, 15 Con.',
      ),
      _codexEntry(
        'Cidade (Nivel 4)',
        'Max 16 edificios. Requer 30 habitantes. Custo: 200 Mad, 150 Ped, 50 Fer, 40 Con.',
      ),
      _codexEntry(
        'Reino (Nivel 5)',
        'Max 25 edificios. Requer 60 habitantes. Custo: 400 Mad, 300 Ped, 100 Fer, 80 Con.',
      ),
      const SizedBox(height: 12),
      _paragraph('Cada evolucao aumenta a capacidade de populacao em +10.'),
    ];
  }

  List<Widget> _buildRecursosContent() {
    return [
      _sectionTitle('RECURSOS'),
      _paragraph('A cidadela gerencia 6 recursos vitais para a sobrevivencia:'),
      const SizedBox(height: 8),
      _codexEntry(
        'Comida',
        'Consumo: 1.5 por habitante/dia. Se acabar, fome causa -3 sanidade, -0.2 resistencia e 5% chance de morte. Produzida por fazendeiros (+3/dia cada), Fazenda (+5/dia), Cozinha + cozinheiros (+3/dia cada).',
        color: AppTheme.green,
      ),
      _codexEntry(
        'Madeira',
        'Material de construcao basico. Produzida por construtores (+2/dia cada). Base: +1/dia.',
        color: AppTheme.orange,
      ),
      _codexEntry(
        'Pedra',
        'Construcao avancada. Produzida por construtores (+1/dia cada). Base: +0.5/dia.',
        color: AppTheme.textSecondary,
      ),
      _codexEntry(
        'Ferro',
        'Armas, ferramentas e estruturas avancadas. Forja: +1/dia. Obtido em recompensas da Torre.',
        color: AppTheme.blue,
      ),
      _codexEntry(
        'Conhecimento',
        'Pesquisa e evolucao. Escribas (+1.5/dia), Biblioteca (+3/dia). Base: +0.2/dia.',
        color: AppTheme.purple,
      ),
      _codexEntry(
        'Moral',
        'Espirito coletivo (0-100). Centro social (+1 a +5/dia conforme tier), Templo (+2/dia). Afeta sanidade de todos. Abaixo de 30: -2 sanidade/dia para todos.',
        color: AppTheme.yellow,
      ),
    ];
  }

  List<Widget> _buildEventosContent() {
    return [
      _sectionTitle('TIPOS DE EVENTOS'),
      _paragraph('Os registros categorizam eventos pela seguinte tipologia:'),
      const SizedBox(height: 8),
      _eventEntry(
        'Combate',
        'Batalhas nos andares da Torre ou conflitos internos.',
        AppTheme.red,
      ),
      _eventEntry(
        'Morte',
        'Falecimento de um habitante. Causa cascata de efeitos negativos.',
        AppTheme.red,
      ),
      _eventEntry(
        'Nascimento',
        'Novo membro da sociedade. Herda atributos dos pais.',
        AppTheme.green,
      ),
      _eventEntry(
        'Descoberta',
        'Algo novo encontrado: inscricoes, talentos, recursos.',
        AppTheme.cyan,
      ),
      _eventEntry(
        'Crise',
        'Fome, conflitos, escassez. Ameacas ao coletivo.',
        AppTheme.orange,
      ),
      _eventEntry(
        'Celebracao',
        'Momentos de alegria. Restaura moral da comunidade.',
        AppTheme.yellow,
      ),
      _eventEntry(
        'Traicao',
        'Rebeliao ou quebra de confianca entre moradores.',
        AppTheme.pink,
      ),
      _eventEntry(
        'Romance',
        'Formacao de vinculos amorosos entre NPCs.',
        AppTheme.pink,
      ),
      _eventEntry(
        'Construcao',
        'Novo edificio construido na cidadela.',
        AppTheme.blue,
      ),
      _eventEntry('Exploracao', 'Incursao em andares da Torre.', AppTheme.cyan),
      _eventEntry(
        'Colapso Mental',
        'NPC sofre quebra psicologica. Veja "Estado Mental".',
        AppTheme.purple,
      ),
      _eventEntry(
        'Torre Conquistada',
        'Andar da Torre superado com sucesso.',
        AppTheme.green,
      ),
      _eventEntry('Evolucao', 'Cidadela evoluiu de nivel.', AppTheme.green),
      _eventEntry(
        'Recursos Ganhos',
        'Descoberta de suprimentos extras.',
        AppTheme.green,
      ),
      _eventEntry(
        'Recursos Perdidos',
        'Tempestade ou desastre danificou estoques.',
        AppTheme.orange,
      ),
      _eventEntry(
        'Treino',
        'Moradores treinaram em andares conquistados.',
        AppTheme.blue,
      ),
      _eventEntry(
        'Sistema',
        'Mensagens do jogo (invocacao, game over, etc).',
        AppTheme.textDim,
      ),
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
        'ociosidade, eventos aleatorios, gravidezes, envelhecimento, treino e escolha autonoma de profissoes. '
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
        'Evolucao da cidadela acontece quando populacao e recursos atingem os requisitos. '
        'Edificios evolutivos fazem upgrade automatico ao mudar de tier.',
      ),
      const SizedBox(height: 12),
      _sectionTitle('OCIOSIDADE E PROFISSOES'),
      _paragraph(
        'NPCs ociosos sofrem penalidades progressivas apos 7 dias sem profissao (-sanidade, -lealdade, -FOR). '
        'A cada 3 dias, NPCs adultos ociosos avaliam autonomamente se querem escolher uma profissao. '
        'A decisao depende de personalidade, tempo ocioso, necessidades da cidadela e moral. '
        'Preguicosos resistem mais, ambiciosos escolhem rapido.',
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
      _paragraph(
        'Cada NPC possui um valor de lealdade (0-100) que afeta sua cooperacao:',
      ),
      const SizedBox(height: 8),
      _codexEntry(
        'Lealdade Alta (70-100)',
        'NPC aceita sugestoes, trabalha com empenho, defende o grupo.',
        color: AppTheme.green,
      ),
      _codexEntry(
        'Lealdade Media (40-69)',
        'Comportamento normal. Pode aceitar ou recusar sugestoes.',
        color: AppTheme.yellow,
      ),
      _codexEntry(
        'Lealdade Baixa (0-39)',
        'NPC resiste a ordens, risco de traicao elevado.',
        color: AppTheme.red,
      ),
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
        'baixa sanidade (<30: +15%), e traumas acumulados.',
      ),
      const SizedBox(height: 8),
      _sectionTitle('TIPOS DE TRAICAO'),
      _codexEntry(
        'Roubo',
        'Rouba 5-20 de comida dos estoques.',
        color: AppTheme.orange,
      ),
      _codexEntry(
        'Sabotagem',
        'Danifica equipamentos. -8 moral.',
        color: AppTheme.orange,
      ),
      _codexEntry(
        'Manipulacao',
        'Espalha rumores, reduz lealdade de outros.',
        color: AppTheme.orange,
      ),
      _codexEntry(
        'Assassinato',
        'Apenas assassinos. Pode matar NPCs famosos!',
        color: AppTheme.red,
      ),
    ];
  }

  List<Widget> _buildGruposContent() {
    return [
      _sectionTitle('SISTEMA DE ESQUADROES'),
      _paragraph(
        'Organize NPCs em grupos para coordenar expedicoes e treinos. '
        'Grupos aumentam coesao, lealdade e eficiencia. '
        'Antes de enviar, voce pode ver uma ANALISE completa da expedicao.',
      ),
      const SizedBox(height: 8),
      _sectionTitle('ANALISE DE EXPEDICAO'),
      _paragraph(
        'Ao selecionar um andar para coleta, o sistema mostra: '
        'custo total em comida, sinergia do grupo, eficiencia (atributos + personalidade), '
        'estimativa de lucro/prejuizo, e riscos detalhados (acidentes, doencas, conflitos, traicao, ameacas reativadas).',
      ),
      const SizedBox(height: 12),
      _sectionTitle('FUNCOES DE GRUPO'),
      _codexEntry('Geral', 'Grupo multiuso sem especializacao.'),
      _codexEntry(
        'Assalto',
        'Focado em combate. Ideal para explorar novos andares.',
      ),
      _codexEntry(
        'Reconhecimento',
        'Focado em exploracao. Ideal para re-exploracao.',
      ),
      _codexEntry(
        'Treinamento',
        'Focado em evolucao. Ideal para sessoes de treino.',
      ),
      _codexEntry(
        'Defesa',
        'Focado em protecao. Ideal para defesa da cidadela.',
      ),
      const SizedBox(height: 12),
      _sectionTitle('COESAO DE GRUPO'),
      _paragraph(
        'Grupos ganham coesao ao longo do tempo e com missoes bem-sucedidas. '
        'Membros do mesmo grupo formam lacos mais rapido. '
        'Coesao alta melhora performance em combate e treino.',
      ),
    ];
  }

  List<Widget> _buildTreinoContent() {
    return [
      _sectionTitle('SISTEMA DE TREINO'),
      _paragraph('O treino tem 3 camadas de controle:'),
      const SizedBox(height: 8),
      _codexEntry(
        '1. Jogador designa ascensao',
        'Voce decide quem sobe novos andares. Decisao final.',
      ),
      _codexEntry(
        '2. Jogador sugere treino',
        'Voce sugere NPCs ou grupos para treinar. Eles decidem se aceitam.',
      ),
      _codexEntry(
        '3. NPCs decidem autonomamente',
        'NPCs treinam por conta propria em andares conquistados (~15% chance a cada 5 dias).',
      ),
      const SizedBox(height: 12),
      _sectionTitle('RESPOSTAS A SUGESTOES'),
      _codexEntry(
        'Aceitar',
        'NPC treina conforme sugerido. +2 lealdade.',
        color: AppTheme.green,
      ),
      _codexEntry(
        'Recusar',
        'NPC se nega. Motivo baseado em personalidade. -1 lealdade.',
        color: AppTheme.red,
      ),
      _codexEntry(
        'Negociar',
        'NPC aceita com condicoes ("descanso depois").',
        color: AppTheme.yellow,
      ),
      _codexEntry(
        'Ignorar',
        'NPC simplesmente ignora.',
        color: AppTheme.textDim,
      ),
      _codexEntry(
        'Persuadir',
        'NPC convence outros a treinar junto.',
        color: AppTheme.blue,
      ),
      const SizedBox(height: 12),
      _sectionTitle('CAMPO DE TREINO (Edificio)'),
      _paragraph(
        'O Campo de Treino reduz risco de morte (0.5% vs ~3% em andares), '
        'mas oferece ganhos menores. Cria instrutores veteranos. '
        'Pode causar disputas e hierarquias internas.',
      ),
      const SizedBox(height: 12),
      _sectionTitle('TREINO EM ANDARES CONQUISTADOS'),
      _paragraph(
        'Treinar em andares ja conquistados oferece ganhos maiores, '
        'mas pode reativar ameacas ocultas (~4% chance), '
        'gerar acidentes (~3%), ou revelar descobertas raras (~5%).',
      ),
    ];
  }

  List<Widget> _buildReexploracaoContent() {
    return [
      _sectionTitle('RE-EXPLORACAO DE ANDARES'),
      _paragraph(
        'Andares conquistados podem ser revisitados para coletar recursos. '
        'Cada andar possui fauna e flora unica que gera recursos diferentes.',
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
        'Novas criaturas surgem, acidentes podem ocorrer, mas tambem descobertas raras.',
      ),
    ];
  }

  List<Widget> _buildInvocacaoContent() {
    return [
      _sectionTitle('INVOCACAO EMERGENCIAL'),
      _paragraph(
        'Quando a populacao cai para 5 ou menos, a Torre detecta o risco de extincao '
        'e invoca automaticamente 1-3 novos humanos a cada 14 dias.',
      ),
      const SizedBox(height: 8),
      _codexEntry('Condicao', 'Populacao <= 5 habitantes vivos'),
      _codexEntry('Frequencia', 'A cada 14 dias enquanto condicao persistir'),
      _codexEntry('Quantidade', '1 a 3 novos NPCs por invocacao'),
      _codexEntry(
        'RISCO',
        'Invocados emergenciais podem ter origens obscuras! Vigiar com atencao.',
        color: AppTheme.red,
      ),
      const SizedBox(height: 12),
      _paragraph(
        'O sistema garante que NPCs nao sejam repetidos e que a simulacao '
        'continue funcional mesmo em populacoes criticamente baixas. '
        'Permadeath continua valendo - cada morte e permanente.',
      ),
    ];
  }

  List<Widget> _buildPoliticaContent() {
    return [
      _sectionTitle('POLITICA INTERNA'),
      _paragraph(
        'Suas decisoes como lider afetam a dinamica social da Cidadela. '
        'O jogo agora e uma simulacao social + gerenciamento estrategico + sobrevivencia.',
      ),
      const SizedBox(height: 8),
      _sectionTitle('IMPACTO DO JOGADOR'),
      _codexEntry(
        'Favoritismo',
        'Sugerir treino sempre para os mesmos NPCs gera ressentimento nos outros. '
            'Se um NPC recebe >5 sugestoes com <30% aceitas, perde lealdade.',
        color: AppTheme.orange,
      ),
      _codexEntry(
        'Inatividade',
        'Nunca sugerir treinos faz parecer ausente. NPCs perdem referencia de lideranca.',
        color: AppTheme.yellow,
      ),
      _codexEntry(
        'Perigo Constante',
        'Enviar NPCs para missoes perigosas demais corroi confianca. '
            'Mortes reduzem lealdade geral.',
        color: AppTheme.red,
      ),
      const SizedBox(height: 12),
      _sectionTitle('EVENTOS POLITICOS'),
      _paragraph(
        'NPCs famosos (fama >10) podem inspirar (+3 moral) ou aterrorizar (-2 moral) a comunidade. '
        'Conflitos entre NPCs reduzem lealdade de ambos. '
        'Nascimentos aumentam lealdade geral (+0.5 para todos). '
        'Evolucao da Cidadela aumenta lealdade (+3 para todos).',
      ),
      const SizedBox(height: 12),
      _sectionTitle('HIERARQUIA DE CONTROLE'),
      _codexEntry('Nivel 1', 'Jogador decide quem ascende novos andares.'),
      _codexEntry('Nivel 2', 'Jogador sugere treinos (NPCs podem recusar).'),
      _codexEntry(
        'Nivel 3',
        'NPCs decidem autonomamente sobre treino e relacionamentos.',
      ),
    ];
  }

  List<Widget> _buildOciosidadeContent() {
    return [
      _sectionTitle('SISTEMA DE OCIOSIDADE'),
      _paragraph(
        'NPCs adultos sem profissao (Ociosos) acumulam dias consecutivos de inatividade. '
        'Apos 7 dias ociosos, comecam a sofrer penalidades progressivas que refletem '
        'a desorientacao, apatia e deterioracao fisica e mental da falta de proposito.',
      ),
      const SizedBox(height: 8),
      _sectionTitle('CONTADOR DE OCIOSIDADE'),
      _entryRow(
        'Reset',
        'Sempre que um NPC ganha uma profissao, contador volta a 0',
      ),
      _entryRow(
        'Apenas adultos',
        'Criancas, adolescentes e bebes nunca acumulam penalidades',
      ),
      _entryRow('Processamento', 'Verifica a cada dia se o NPC esta ocioso'),
      const SizedBox(height: 12),
      _sectionTitle('PENALIDADES PROGRESSIVAS'),
      _codexEntry(
        '7-13 dias (Fase 1)',
        'Desorientacao inicial: -0.3 sanidade/dia, -0.5 lealdade/dia. '
            'NPC comeca a questionar seu valor para a comunidade.',
        color: AppTheme.yellow,
      ),
      _codexEntry(
        '14-20 dias (Fase 2)',
        'Deterioracao fisica: -0.5 sanidade/dia, -1.0 lealdade/dia, -0.1 Forca/dia. '
            'Falta de atividade causa atrofia muscular e depressao.',
        color: AppTheme.orange,
      ),
      _codexEntry(
        '21+ dias (Fase 3)',
        'Crise existencial: -1.0 sanidade/dia, -1.5 lealdade/dia, -0.2 Forca/dia. '
            'A cada 7 dias nesta fase: evento narrativo destacando o sofrimento do NPC.',
        color: AppTheme.red,
      ),
      const SizedBox(height: 12),
      _sectionTitle('INFLUENCIA DE PERSONALIDADE'),
      _paragraph('Tracos de personalidade modificam as penalidades:'),
      const SizedBox(height: 8),
      _codexEntry(
        'Preguicoso',
        'Penalidades reduzidas em 40%. Menos afetado pela ociosidade.',
        color: AppTheme.green,
      ),
      _codexEntry(
        'Ambicioso',
        'Penalidades aumentadas em 30%. Sofre mais por nao ter proposito.',
        color: AppTheme.red,
      ),
      _codexEntry(
        'Lider',
        'Penalidades aumentadas em 25%. Precisa estar ativo para se sentir util.',
        color: AppTheme.red,
      ),
      const SizedBox(height: 12),
      _sectionTitle('ESCOLHA AUTONOMA DE PROFISSAO'),
      _paragraph(
        'A cada 3 dias, NPCs ociosos avaliam se querem escolher uma profissao. '
        'A chance base e 15%, mas pode aumentar ate 80% para NPCs ambiciosos com muitos dias ociosos. '
        'NPCs preguicosos tem chance reduzida (minimo 5%).',
      ),
      const SizedBox(height: 8),
      _entryRow(
        'Fatores de decisao',
        'Personalidade, dias ocioso, necessidades da cidadela, moral geral',
      ),
      _entryRow(
        'Selecao inteligente',
        'Preferem profissoes que combinam com atributos e origem',
      ),
      _entryRow('Bonus', '+2 lealdade ao escolher uma profissao'),
    ];
  }

  List<Widget> _buildEvolucaoContent() {
    return [
      _sectionTitle('EVOLUCAO DE EDIFICIOS'),
      _paragraph(
        'Certos edificios evoluem AUTOMATICAMENTE quando a cidadela sobe de nivel. '
        'Cada evolucao representa um upgrade arquitetonico com bonus escalados. '
        'Edificios obsoletos desaparecem da lista de construcao quando versoes evoluidas existem.',
      ),
      const SizedBox(height: 8),
      _sectionTitle('MECANICA DE EVOLUCAO'),
      _paragraph(
        'Quando a cidadela atinge um novo tier (Abrigo → Acampamento → Vila → Cidade → Reino), '
        'edificios evolutivos existentes fazem upgrade automatico. Nao e possivel construir '
        'versoes antigas (ex: se ja tem Casa, nao pode mais construir Tenda).',
      ),
      const SizedBox(height: 12),
      _sectionTitle('EDIFICIOS EVOLUTIVOS'),
      const SizedBox(height: 8),
      _codexEntry(
        'Fogueira (Centro Social)',
        'Tier 0: Fogueira (+1 moral/dia)\n'
            'Tier 1: Marco da Vila (+2 moral/dia)\n'
            'Tier 2: Praca Central (+3 moral/dia)\n'
            'Tier 3: Monumento da Ascensao (+5 moral/dia)',
        color: AppTheme.orange,
      ),
      _codexEntry(
        'Tenda (Moradia)',
        'Tier 0: Tenda (+2 capacidade)\n'
            'Tier 1: Casa (+4 capacidade)\n'
            'Tier 2: Pousada (+8 capacidade)\n'
            'Tier 3: Residencia (+15 capacidade)',
        color: AppTheme.blue,
      ),
      _codexEntry(
        'Cozinha (Alimentacao)',
        'Tier 0: Cozinha (+3 comida/chef)\n'
            'Tier 1: Refeitorio (+8 comida/chef)\n'
            'Tier 2: Salao de Banquetes (+15 comida/chef)',
        color: AppTheme.green,
      ),
      _codexEntry(
        'Armazem (Estoque)',
        'Tier 0: Armazem (+50% capacidade)\n'
            'Tier 1: Deposito (+100% capacidade)\n'
            'Tier 2: Centro Logistico (+150% capacidade)',
        color: AppTheme.yellow,
      ),
      _codexEntry(
        'Fazenda (Producao)',
        'Tier 0: Fazenda (+5 comida/dia)\n'
            'Tier 1: Plantacao (+12 comida/dia)\n'
            'Tier 2: Fazenda Industrial (+25 comida/dia)',
        color: AppTheme.green,
      ),
      _codexEntry(
        'Oficina (Manufatura)',
        'Tier 0: Oficina (producao base)\n'
            'Tier 1: Manufatura (producao aumentada)\n'
            'Tier 2: Fabrica (producao massiva)',
        color: AppTheme.cyan,
      ),
      _codexEntry(
        'Forja (Metais)',
        'Tier 0: Forja (+2 ferro/dia)\n'
            'Tier 1: Fundicao (+5 ferro/dia)\n'
            'Tier 2: Refinaria (+10 ferro/dia)',
        color: AppTheme.red,
      ),
      _codexEntry(
        'Quartel (Treino Militar)',
        'Tier 0: Quartel (+0.3 FOR/dia)\n'
            'Tier 1: Academia (+0.5 FOR/dia)\n'
            'Tier 2: Complexo de Treino (+0.8 FOR/dia)',
        color: AppTheme.purple,
      ),
      const SizedBox(height: 12),
      _sectionTitle('EDIFICIOS FIXOS (NAO EVOLUEM)'),
      _paragraph(
        'Alguns edificios nao possuem upgrades automaticos e permanecem fixos: '
        'Enfermaria, Escola, Mercado, Biblioteca, Muralha, Torre de Vigia, Templo, Campo de Treino. '
        'Estes edificios sao especializados e ja funcionam em capacidade maxima.',
      ),
    ];
  }

  // ====== Helper Widgets ======

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TerminalText(
            '// $title',
            fontSize: 12,
            color: AppTheme.cyan,
            fontWeight: FontWeight.bold,
          ),
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
        border: Border.all(
          color: (color ?? AppTheme.border).withValues(alpha: 0.4),
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TerminalText(
            term,
            fontSize: 10,
            color: color ?? AppTheme.cyan,
            fontWeight: FontWeight.bold,
          ),
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
          SizedBox(
            width: 140,
            child: TerminalText(key, fontSize: 9, color: AppTheme.cyan),
          ),
          Expanded(
            child: TerminalText(
              value,
              fontSize: 9,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _towerEntry(
    int num,
    String type,
    String name,
    String desc,
    String stats,
    String reward,
  ) {
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
              TerminalText(
                'ANDAR ${num.toString().padLeft(2, '0')}',
                fontSize: 10,
                color: AppTheme.cyan,
                fontWeight: FontWeight.bold,
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppTheme.yellow.withValues(alpha: 0.5),
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: TerminalText(type, fontSize: 8, color: AppTheme.yellow),
              ),
              const Spacer(),
              TerminalText(stats, fontSize: 8, color: AppTheme.red),
            ],
          ),
          const SizedBox(height: 4),
          TerminalText(
            name,
            fontSize: 10,
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
          TerminalText(desc, fontSize: 9, color: AppTheme.textSecondary),
          const SizedBox(height: 3),
          TerminalText(
            'Recompensa: $reward',
            fontSize: 8,
            color: AppTheme.green,
          ),
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
              Expanded(
                child: TerminalText(
                  name,
                  fontSize: 10,
                  color: AppTheme.cyan,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
                TerminalText(
                  name,
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
                TerminalText(desc, fontSize: 9, color: AppTheme.textSecondary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCrescimentoContent() {
    return [
      _sectionTitle('SISTEMA DE CRESCIMENTO PASSIVO'),
      _paragraph(
        'Os NPCs não são estáticos - eles se fortalecem automaticamente através do ambiente, '
        'experiências vividas e moral da comunidade. O jogador não precisa microgerenciar, mas '
        'decisões estratégicas (construções, moral, expedições) impactam diretamente o crescimento.',
      ),
      const SizedBox(height: 12),

      _sectionTitle('TREINAMENTO AMBIENTAL'),
      _paragraph(
        'Edifícios construídos proporcionam treinamento passivo diário. '
        'Quanto mais sofisticada a cidadela, mais forte a população se torna:',
      ),
      _buildingBonus(
        'Academia/Campo de Treino',
        '+0.05 FOR/AGI por dia (30% chance)',
        AppTheme.red,
      ),
      _buildingBonus(
        'Biblioteca/Escola',
        '+0.05 INT por dia para escribas/professores/ociosos (25%)',
        AppTheme.cyan,
      ),
      _buildingBonus(
        'Enfermaria',
        '+0.05 RES por dia para todos (20%)',
        AppTheme.green,
      ),
      _buildingBonus(
        'Templo',
        '+0.5 Sanidade, +0.03 CAR por dia (15%)',
        AppTheme.purple,
      ),
      _buildingBonus(
        'Arena',
        '+0.1 FOR/AGI/RES para guerreiros (40%)',
        AppTheme.orange,
      ),
      _paragraph(
        'Os percentuais indicam a chance diária de cada NPC se beneficiar. '
        'Com múltiplas construções, os efeitos se acumulam.',
      ),
      const SizedBox(height: 12),

      _sectionTitle('CRESCIMENTO POR SOBREVIVÊNCIA'),
      _paragraph('Experiências extremas fortalecem os NPCs permanentemente:'),
      _buildPhase(
        'Veterano de Longo Prazo',
        'A cada 50 dias sobrevividos: +2 Sanidade Mental, +0.2 RES',
        AppTheme.green,
      ),
      _buildPhase(
        'Crescimento Pós-Traumático',
        '3+ traumas + sanidade >40: 25% chance de superar tudo, ganhar +5 SAN, +0.3 RES, trait Pragmático',
        AppTheme.cyan,
      ),
      _buildPhase(
        'Resistência à Fadiga',
        'Sobreviver a fadiga 85+: 15% chance de +0.15 RES',
        AppTheme.yellow,
      ),
      _buildPhase(
        'Veterano da Torre',
        'A cada 10 andares conquistados: +0.3 FOR, +0.25 AGI, +0.1 Sorte',
        AppTheme.purple,
      ),
      const SizedBox(height: 12),

      _sectionTitle('BÔNUS DE MORAL ALTA'),
      _paragraph(
        'Quando a moral da cidadela está acima de 70, a população cresce inspirada:',
      ),
      _buildPhase(
        'Moral 70-85',
        '30% dos NPCs ganham +0.05-0.08 em atributo aleatório diariamente',
        AppTheme.green,
      ),
      _buildPhase(
        'Moral 85-100',
        '30% dos NPCs ganham +0.08-0.10 em atributo aleatório diariamente',
        AppTheme.cyan,
      ),
      _paragraph(
        'Moral baixa (<70) desativa este sistema. Manter a comunidade feliz é estratégico.',
      ),
      const SizedBox(height: 12),

      _sectionTitle('DESCOBERTA DE TALENTOS OCULTOS'),
      _paragraph(
        '15% dos NPCs possuem talentos ocultos que podem ser descobertos através de experiência e instalações:',
      ),
      _buildPhase(
        'Taxa Base',
        '2% chance por dia de descobrir talento (apenas NPCs adultos)',
        AppTheme.textSecondary,
      ),
      _paragraph('Fatores que aumentam descoberta:'),
      _buildingBonus(
        '5+ Andares Conquistados',
        '+3% descoberta',
        AppTheme.cyan,
      ),
      _buildingBonus('30+ Dias Sobrevividos', '+2% descoberta', AppTheme.green),
      _buildingBonus('10+ Inimigos Mortos', '+3% descoberta', AppTheme.red),
      _buildingBonus('Sorte > 8', '+2% descoberta', AppTheme.purple),
      _buildingBonus('Moral > 80', '+2% descoberta', AppTheme.green),
      _buildingBonus('Profissão Ativa', '+2% descoberta', AppTheme.yellow),
      _buildingBonus('Arena Construída', '+3% descoberta', AppTheme.orange),
      _buildingBonus('Biblioteca Construída', '+2% descoberta', AppTheme.cyan),
      _buildingBonus('Templo Construído', '+2% descoberta', AppTheme.purple),
      _paragraph(
        'Quando descoberto, o talento concede bônus imediatos e permanentes ao NPC, além de +5 fama e +2 moral para toda cidadela.',
      ),
      const SizedBox(height: 12),

      _sectionTitle('BÔNUS POR TALENTO DESCOBERTO'),
      _buildPhase(
        'Gênio do Combate',
        '+2 FOR, +2 AGI + 50% poder em combate',
        AppTheme.red,
      ),
      _buildPhase(
        'Toque Curativo',
        '+1.5 INT, +1 CAR + cura aliados após batalhas',
        AppTheme.green,
      ),
      _buildPhase(
        'Mente Estratégica',
        '+3 INT + reduz mortalidade do grupo em 15%',
        AppTheme.cyan,
      ),
      _buildPhase(
        'Líder Natural',
        '+3 CAR, +10 Lealdade + 20% moral do grupo',
        AppTheme.purple,
      ),
      _buildPhase(
        'Vontade de Ferro',
        '+15 SAN, +2 RES + imune a perda de sanidade',
        AppTheme.orange,
      ),
      _buildPhase(
        'Mestre da Forja',
        '+1.5 FOR, +1.5 INT + equipamentos 2x eficientes',
        AppTheme.yellow,
      ),
      _buildPhase(
        'Caminhante das Sombras',
        '+3 AGI, +1.5 Sorte + pode evadir qualquer combate',
        AppTheme.textDim,
      ),
      _buildPhase(
        'Herbalista',
        '+2 INT + produz medicamentos naturais',
        AppTheme.green,
      ),
      _buildPhase(
        'Sussurrador de Feras',
        '+2 CAR, +1 Sorte + chance de domar criaturas',
        AppTheme.cyan,
      ),
      _buildPhase(
        'Leitor de Runas',
        '+2.5 INT, +1.5 Sorte + revela segredos dos andares',
        AppTheme.purple,
      ),
      const SizedBox(height: 12),

      _sectionTitle('SINERGIA ESTRATÉGICA'),
      _paragraph('O sistema recompensa gestão inteligente da cidadela:'),
      _buildPhase(
        'Construções Diversificadas',
        'Cada tipo de edifício treina atributos diferentes - diversifique!',
        AppTheme.green,
      ),
      _buildPhase(
        'Moral Sustentada',
        'Mantenha moral alta para crescimento contínuo da população',
        AppTheme.cyan,
      ),
      _buildPhase(
        'Expedições Balanceadas',
        'Veteranos ficam mais fortes, mas precisam sobreviver primeiro',
        AppTheme.orange,
      ),
      _buildPhase(
        'Talentos Raros',
        'Arena + Biblioteca + Templo = ~11% chance diária de descoberta',
        AppTheme.purple,
      ),
      const SizedBox(height: 12),

      _sectionTitle('DESIGN EMERGENTE'),
      _paragraph('Este sistema cria narrativas únicas:'),
      _paragraph(
        '• Um NPC traumatizado que supera tudo e vira o mais forte\\n'
        '• Um veterano de 100 dias que se torna lenda viva\\n'
        '• Uma comunidade feliz que cresce exponencialmente\\n'
        '• Um talento descoberto que vira o ponto de virada',
      ),
      _paragraph(
        'Não há garantias, mas cada decisão importa. '
        'O jogador influencia, mas não controla completamente.',
      ),
    ];
  }

  Widget _buildingBonus(String building, String effect, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
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
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 9,
                  fontFamily: 'Courier',
                  color: AppTheme.textSecondary,
                ),
                children: [
                  TextSpan(
                    text: '$building: ',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(text: effect),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhase(String name, String desc, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 4, right: 8),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TerminalText(
                  name,
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
                TerminalText(desc, fontSize: 9, color: AppTheme.textSecondary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
