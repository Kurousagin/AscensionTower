import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tower_ascension/widgets/family_threee_widget.dart';
import '../providers/game_provider.dart';
import '../widgets/theme.dart';
import '../widgets/terminal_widgets.dart';
import '../models/npc.dart';
import '../models/citadel.dart';
import '../models/equipment.dart';
import '../models/game_event.dart';

class NpcDetailScreen extends StatefulWidget {
  final String npcId;
  const NpcDetailScreen({super.key, required this.npcId});

  @override
  State<NpcDetailScreen> createState() => _NpcDetailScreenState();
}

class _NpcDetailScreenState extends State<NpcDetailScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabs;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<GameProvider>(
      builder: (context, gp, _) {
        final npc = gp.allNpcs.firstWhereOrNull((n) => n.id == widget.npcId);
        if (npc == null) {
          return Scaffold(
            backgroundColor: AppTheme.bg,
            appBar: AppBar(backgroundColor: AppTheme.bg),
            body: const Center(
              child: TerminalText(
                'Habitante não encontrado.',
                color: AppTheme.textDim,
              ),
            ),
          );
        }

        final equipped = gp.equippedOn(npc.id);

        return Scaffold(
          backgroundColor: AppTheme.bg,
          appBar: _buildAppBar(npc),
          body: ScanlineOverlay(
            child: Column(
              children: [
                _buildHeader(npc, equipped, gp),
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabs,
                    children: [
                      _buildTabStats(npc, equipped, gp),
                      _buildTabLife(npc, gp),
                      _buildTabFamily(npc, gp),
                      _buildTabArena(npc, gp),
                      _buildTabTree(npc, gp),
                    ],
                  ),
                ),
                _buildActions(context, npc, gp),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── AppBar ─────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(Npc npc) {
    return AppBar(
      backgroundColor: AppTheme.bg,
      elevation: 0,
      iconTheme: const IconThemeData(color: AppTheme.textSecondary),
      bottom: PreferredSize(
        preferredSize: Size.zero,
        child: Container(height: 1, color: AppTheme.border),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TerminalText(
            npc.name.toUpperCase(),
            fontSize: 14,
            color: npc.alive ? AppTheme.cyan : AppTheme.textDim,
            fontWeight: FontWeight.bold,
          ),
          TerminalText(
            '${npc.origin.label} · G${npc.generation} · ${npc.age} anos',
            fontSize: 9,
            color: AppTheme.textDim,
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(
              color: npc.alive ? AppTheme.green : AppTheme.red,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
          child: TerminalText(
            npc.alive ? 'VIVO' : 'MORTO',
            fontSize: 9,
            color: npc.alive ? AppTheme.green : AppTheme.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ── Header com stats rápidos ───────────────────────────────

  Widget _buildHeader(Npc npc, List<Equipment> equipped, GameProvider gp) {
    final cp = npc.effectiveCombatPowerWithGear(equipped);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      color: AppTheme.bgCard,
      child: Row(
        children: [
          _headerStat('FAMA', npc.fame.toStringAsFixed(0), AppTheme.yellow),
          _headerDivider(),
          _headerStat(
            'LEALD.',
            '${npc.loyalty.toStringAsFixed(0)}%',
            npc.loyalty > 60
                ? AppTheme.green
                : npc.loyalty > 30
                ? AppTheme.yellow
                : AppTheme.red,
          ),
          _headerDivider(),
          _headerStat('CP', cp.toStringAsFixed(1), AppTheme.orange),
          _headerDivider(),
          _headerStat('DIAS', '${npc.daysSurvived}', AppTheme.cyan),
          _headerDivider(),
          _headerStat('ANDARES', '${npc.floorsCleared}', AppTheme.blue),
        ],
      ),
    );
  }

  Widget _headerStat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          TerminalText(
            value,
            fontSize: 13,
            color: color,
            fontWeight: FontWeight.bold,
          ),
          TerminalText(label, fontSize: 8, color: AppTheme.textDim),
        ],
      ),
    );
  }

  Widget _headerDivider() =>
      Container(width: 1, height: 28, color: AppTheme.border);

  // ── Tab bar ────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Container(
      color: AppTheme.bgCard,
      child: TabBar(
        controller: _tabs,
        indicatorColor: AppTheme.cyan,
        indicatorWeight: 2,
        labelColor: AppTheme.cyan,
        unselectedLabelColor: AppTheme.textDim,
        labelStyle: const TextStyle(
          fontFamily: 'FiraCode',
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'FiraCode',
          fontSize: 11,
        ),
        tabs: const [
          Tab(text: 'FICHA'),
          Tab(text: 'VIDA'),
          Tab(text: 'FAMÍLIA'),
          Tab(text: 'ARENA'),
          Tab(text: 'ÁRVORE'),
        ],
      ),
    );
  }

  // ── Tab: Ficha ─────────────────────────────────────────────

  Widget _buildTabStats(Npc npc, List<Equipment> equipped, GameProvider gp) {
    return ListView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.all(12),
      children: [
        // Atributos
        const CyanDivider(label: 'ATRIBUTOS'),
        StatBar(
          label: 'Força',
          value: npc.totalStrength(equipped),
          maxValue: 20,
        ),
        StatBar(
          label: 'Agil.',
          value: npc.totalAgility(equipped),
          maxValue: 20,
        ),
        StatBar(
          label: 'Intel.',
          value: npc.totalIntelligence(equipped),
          maxValue: 20,
        ),
        StatBar(
          label: 'Resist.',
          value: npc.totalEndurance(equipped),
          maxValue: 20,
        ),
        StatBar(
          label: 'Caris.',
          value: npc.totalCharisma(equipped),
          maxValue: 20,
        ),
        const SizedBox(height: 4),
        StatBar(
          label: 'Sanid.',
          value: npc.attributes.mentalStability,
          maxValue: 100,
          color: npc.attributes.mentalStability > 60
              ? AppTheme.green
              : npc.attributes.mentalStability > 30
              ? AppTheme.yellow
              : AppTheme.red,
        ),
        StatBar(
          label: 'Fadiga',
          value: npc.fatigue,
          maxValue: 100,
          color: npc.fatigue < 30
              ? AppTheme.green
              : npc.fatigue < 60
              ? AppTheme.yellow
              : AppTheme.red,
        ),

        // Personalidade
        const CyanDivider(label: 'PERSONALIDADE'),
        if (npc.traits.isEmpty)
          const TerminalText(
            'Nenhum traço definido.',
            fontSize: 10,
            color: AppTheme.textDim,
          )
        else
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: npc.traits
                .map((t) => _tag(t.label, AppTheme.purple))
                .toList(),
          ),

        // Talento
        if (npc.hiddenTalent != HiddenTalent.none) ...[
          const CyanDivider(label: 'TALENTO'),
          TerminalText(
            npc.talentDiscovered
                ? '${npc.hiddenTalent.label}: ${npc.hiddenTalent.description}'
                : '??? Talento ainda não revelado',
            fontSize: 11,
            color: npc.talentDiscovered ? AppTheme.purple : AppTheme.textDim,
          ),
        ],

        // Capacidades especiais
        if (npc.talentDiscovered && _hasSpecialCapabilities(npc)) ...[
          const CyanDivider(label: 'CAPACIDADES'),
          ..._buildCapabilities(npc),
        ],

        // Equipamentos
        const CyanDivider(label: 'EQUIPAMENTOS'),
        Row(
          children: [
            _EquipSlot(
              label: 'ARMA',
              icon: '⚔',
              equipment: equipped.firstWhereOrNull(
                (e) => e.slot == EquipmentSlot.weapon,
              ),
            ),
            const SizedBox(width: 8),
            _EquipSlot(
              label: 'ARMOR',
              icon: '🛡',
              equipment: equipped.firstWhereOrNull(
                (e) => e.slot == EquipmentSlot.armor,
              ),
            ),
            const SizedBox(width: 8),
            _EquipSlot(
              label: 'ACESS.',
              icon: '💍',
              equipment: equipped.firstWhereOrNull(
                (e) => e.slot == EquipmentSlot.accessory,
              ),
            ),
          ],
        ),

        // Social
        const CyanDivider(label: 'SOCIAL'),
        TerminalText(
          'Reputação: ${npc.fameLabel} (${npc.fame.toStringAsFixed(0)})',
          fontSize: 11,
          color: npc.fame >= 0 ? AppTheme.yellow : AppTheme.red,
        ),
        if (npc.betrayalRisk > 10) ...[
          const SizedBox(height: 4),
          TerminalText(
            'Risco de traição: ${npc.betrayalRisk.toStringAsFixed(0)}%',
            fontSize: 11,
            color: npc.betrayalRisk > 50 ? AppTheme.red : AppTheme.orange,
          ),
        ],
        if (npc.groupId != null) ...[
          const SizedBox(height: 4),
          Builder(
            builder: (_) {
              final group = gp.groups.firstWhereOrNull(
                (g) => g.id == npc.groupId,
              );
              return TerminalText(
                'Grupo: ${group?.name ?? "—"}',
                fontSize: 11,
                color: AppTheme.blue,
              );
            },
          ),
        ],

        // Vínculos
        if (npc.relationships.isNotEmpty) ...[
          const CyanDivider(label: 'VÍNCULOS'),
          ...npc.relationships.where((r) => r.affinity.abs() > 0.2).take(8).map(
            (r) {
              final target = gp.allNpcs.firstWhereOrNull(
                (n) => n.id == r.targetId,
              );
              if (target == null) return const SizedBox.shrink();
              final color = r.affinity > 0.6
                  ? AppTheme.green
                  : r.affinity > 0.2
                  ? AppTheme.yellow
                  : AppTheme.red;
              final icon = r.type == 'parceiro'
                  ? '♥'
                  : r.type == 'familiar'
                  ? '⌂'
                  : r.affinity > 0.3
                  ? '+'
                  : '−';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    TerminalText('$icon ', fontSize: 10, color: color),
                    Expanded(
                      child: TerminalText(
                        target.name,
                        fontSize: 11,
                        color: target.alive
                            ? AppTheme.textPrimary
                            : AppTheme.textDim,
                      ),
                    ),
                    if (!target.alive)
                      const TerminalText(
                        ' ✝',
                        fontSize: 10,
                        color: AppTheme.red,
                      ),
                    TerminalText(
                      '${(r.affinity * 100).toStringAsFixed(0)}%',
                      fontSize: 9,
                      color: AppTheme.textDim,
                    ),
                  ],
                ),
              );
            },
          ),
        ],

        // Traumas
        if (npc.traumas.isNotEmpty) ...[
          const CyanDivider(label: 'TRAUMAS'),
          ...npc.traumas.map(
            (t) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: TerminalText('⚠ $t', fontSize: 10, color: AppTheme.red),
            ),
          ),
        ],

        // Marcas psicológicas
        if (npc.psychologicalMarks.isNotEmpty) ...[
          const CyanDivider(label: 'MARCAS PSICOLÓGICAS'),
          ...npc.psychologicalMarks.map(
            (m) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: TerminalText('· $m', fontSize: 10, color: AppTheme.purple),
            ),
          ),
        ],

        const SizedBox(height: 16),
      ],
    );
  }

  // ── Tab: Vida ──────────────────────────────────────────────

  Widget _buildTabLife(Npc npc, GameProvider gp) {
    if (npc.history.isEmpty) {
      return const Center(
        child: TerminalText(
          'Nenhum registro ainda.',
          fontSize: 11,
          color: AppTheme.textDim,
        ),
      );
    }

    final entries = npc.history.reversed.toList();

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: entries.length,
      itemBuilder: (context, i) {
        final text = entries[i];
        final color = _historyColor(text);
        final icon = _historyIcon(text);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // linha vertical da timeline
              Column(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      border: Border.all(color: color.withValues(alpha: 0.5)),
                      borderRadius: BorderRadius.circular(2),
                      color: color.withValues(alpha: 0.08),
                    ),
                    child: Center(
                      child: TerminalText(icon, fontSize: 11, color: color),
                    ),
                  ),
                  if (i < entries.length - 1)
                    Container(width: 1, height: 16, color: AppTheme.border),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: TerminalText(
                    text,
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _historyColor(String text) {
    final t = text.toLowerCase();
    if (t.contains('mort') || t.contains('matat') || t.contains('assassin'))
      return AppTheme.red;
    if (t.contains('nasceu') || t.contains('nascim')) return AppTheme.green;
    if (t.contains('casou') || t.contains('parceiro') || t.contains('amor'))
      return AppTheme.pink;
    if (t.contains('traiu') || t.contains('traição')) return AppTheme.orange;
    if (t.contains('venceu') || t.contains('arena') || t.contains('duelo'))
      return AppTheme.yellow;
    if (t.contains('andar') || t.contains('torre') || t.contains('expedição'))
      return AppTheme.cyan;
    if (t.contains('preso') || t.contains('prisão')) return AppTheme.red;
    if (t.contains('trauma') || t.contains('colapso')) return AppTheme.purple;
    return AppTheme.textDim;
  }

  String _historyIcon(String text) {
    final t = text.toLowerCase();
    if (t.contains('mort') || t.contains('assassin')) return '✝';
    if (t.contains('nasceu')) return '◉';
    if (t.contains('casou') || t.contains('amor')) return '♥';
    if (t.contains('traiu')) return '!';
    if (t.contains('arena') || t.contains('duelo')) return '⚔';
    if (t.contains('andar') || t.contains('torre')) return '▲';
    if (t.contains('preso')) return '◈';
    if (t.contains('trauma') || t.contains('colapso')) return '~';
    return '·';
  }

  // ── Tab: Família ───────────────────────────────────────────

  Widget _buildTabFamily(Npc npc, GameProvider gp) {
    final partner = npc.partnerId != null
        ? gp.allNpcs.firstWhereOrNull((n) => n.id == npc.partnerId)
        : null;
    final parentA = npc.parentAId != null
        ? gp.allNpcs.firstWhereOrNull((n) => n.id == npc.parentAId)
        : null;
    final parentB = npc.parentBId != null
        ? gp.allNpcs.firstWhereOrNull((n) => n.id == npc.parentBId)
        : null;
    final children = npc.childrenIds
        .map((id) => gp.allNpcs.firstWhereOrNull((n) => n.id == id))
        .whereType<Npc>()
        .toList();

    final hasFamily =
        partner != null ||
        parentA != null ||
        parentB != null ||
        children.isNotEmpty;

    if (!hasFamily) {
      return const Center(
        child: TerminalText(
          'Nenhum vínculo familiar registrado.',
          fontSize: 11,
          color: AppTheme.textDim,
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (partner != null) ...[
          const CyanDivider(label: 'PARCEIRO(A)'),
          _familyCard(context, partner, '♥', AppTheme.pink),
        ],
        if (parentA != null || parentB != null) ...[
          const CyanDivider(label: 'PAIS'),
          if (parentA != null)
            _familyCard(context, parentA, '⌂', AppTheme.blue),
          if (parentB != null)
            _familyCard(context, parentB, '⌂', AppTheme.blue),
        ],
        if (children.isNotEmpty) ...[
          CyanDivider(label: 'FILHOS (${children.length})'),
          ...children.map((c) => _familyCard(context, c, '◉', AppTheme.green)),
        ],
      ],
    );
  }

  Widget _familyCard(
    BuildContext context,
    Npc relative,
    String icon,
    Color color,
  ) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => NpcDetailScreen(npcId: relative.id)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          border: Border.all(color: AppTheme.border),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            TerminalText(icon, fontSize: 14, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TerminalText(
                    relative.name,
                    fontSize: 13,
                    color: relative.alive
                        ? AppTheme.textPrimary
                        : AppTheme.textDim,
                    fontWeight: FontWeight.bold,
                  ),
                  TerminalText(
                    '${relative.origin.label} · ${relative.age} anos · ${relative.profession.label}',
                    fontSize: 10,
                    color: AppTheme.textDim,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: relative.alive ? AppTheme.green : AppTheme.red,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: TerminalText(
                    relative.alive ? 'VIVO' : 'MORTO',
                    fontSize: 8,
                    color: relative.alive ? AppTheme.green : AppTheme.red,
                  ),
                ),
                const SizedBox(height: 4),
                const TerminalText(
                  'ver ›',
                  fontSize: 9,
                  color: AppTheme.textDim,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab: Arena ─────────────────────────────────────────────

  Widget _buildTabArena(Npc npc, GameProvider gp) {
    final hasArena = gp.citadel.hasBuilding(BuildingType.arena);
    final arenaEvents = gp.events
        .where(
          (e) =>
              e.type == GameEventType.combat &&
              e.involvedNpcIds.contains(npc.id) &&
              (e.title.contains('Arena') || e.title.contains('Desafio')),
        )
        .toList()
        .reversed
        .toList();

    final title = _arenaTitle(npc.arenaWins);
    final total = npc.arenaWins + npc.arenaLosses;
    final winRate = total > 0
        ? (npc.arenaWins / total * 100).toStringAsFixed(0)
        : '—';

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (!hasArena)
          const TerminalText(
            'Arena não construída na cidadela.',
            fontSize: 11,
            color: AppTheme.textDim,
          )
        else ...[
          // Resumo
          TerminalCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TerminalText(
                        title.toUpperCase(),
                        fontSize: 10,
                        color: npc.arenaWins >= 10
                            ? AppTheme.yellow
                            : AppTheme.textDim,
                        fontWeight: FontWeight.bold,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          TerminalText(
                            '${npc.arenaWins}',
                            fontSize: 22,
                            color: AppTheme.green,
                            fontWeight: FontWeight.bold,
                          ),
                          const TerminalText(
                            ' V  ',
                            fontSize: 13,
                            color: AppTheme.textDim,
                          ),
                          TerminalText(
                            '${npc.arenaLosses}',
                            fontSize: 22,
                            color: AppTheme.red,
                            fontWeight: FontWeight.bold,
                          ),
                          const TerminalText(
                            ' D',
                            fontSize: 13,
                            color: AppTheme.textDim,
                          ),
                        ],
                      ),
                      TerminalText(
                        'Taxa de vitória: $winRate%',
                        fontSize: 10,
                        color: AppTheme.textSecondary,
                      ),
                    ],
                  ),
                ),
                // Barra de progresso para próximo título
                if (npc.arenaWins < 30) _buildTitleProgress(npc.arenaWins),
              ],
            ),
          ),

          if (arenaEvents.isNotEmpty) ...[
            const CyanDivider(label: 'HISTÓRICO DE DUELOS'),
            ...arenaEvents.map((e) {
              final isWinner = e.description.contains('${npc.name} venceu');
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.bgCard,
                  border: Border.all(
                    color: isWinner
                        ? AppTheme.green.withValues(alpha: 0.3)
                        : AppTheme.red.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    TerminalText(
                      isWinner ? 'V' : 'D',
                      fontSize: 14,
                      color: isWinner ? AppTheme.green : AppTheme.red,
                      fontWeight: FontWeight.bold,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TerminalText(
                            e.description,
                            fontSize: 11,
                            color: AppTheme.textPrimary,
                          ),
                          TerminalText(
                            'Dia ${e.day}',
                            fontSize: 9,
                            color: AppTheme.textDim,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: const TerminalText(
                'Nenhum duelo registrado ainda.',
                fontSize: 11,
                color: AppTheme.textDim,
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildTitleProgress(int wins) {
    final next = wins < 5
        ? 5
        : wins < 10
        ? 10
        : wins < 20
        ? 20
        : 30;
    final prev = wins < 5
        ? 0
        : wins < 10
        ? 5
        : wins < 20
        ? 10
        : 20;
    final pct = ((wins - prev) / (next - prev)).clamp(0.0, 1.0);
    final nextTitle = _arenaTitle(next);
    final filled = (pct * 8).round();
    final bar = '${'█' * filled}${'░' * (8 - filled)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        TerminalText('Próximo título:', fontSize: 9, color: AppTheme.textDim),
        TerminalText(nextTitle, fontSize: 9, color: AppTheme.yellow),
        const SizedBox(height: 4),
        TerminalText(bar, fontSize: 10, color: AppTheme.yellow),
        TerminalText('$wins/$next', fontSize: 8, color: AppTheme.textDim),
      ],
    );
  }

  // ── Barra de ações ─────────────────────────────────────────

  Widget _buildTabTree(Npc npc, GameProvider gp) {
    final hasFamily = npc.parentAId != null ||
        npc.parentBId != null ||
        npc.partnerId != null ||
        npc.childrenIds.isNotEmpty;

    if (!hasFamily) {
      return const Center(
        child: TerminalText(
          'Nenhum vínculo familiar para exibir.\nA árvore cresce com o tempo.',
          fontSize: 11,
          color: AppTheme.textDim,
          textAlign: TextAlign.center,
        ),
      );
    }

    return FamilyTreeWidget(
      focal: npc,
      allNpcs: gp.allNpcs,
      onNodeTap: (tapped) {
        if (tapped.id == npc.id) return;
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => NpcDetailScreen(npcId: tapped.id),
        ));
      },
    );
  }

  Widget _buildActions(BuildContext context, Npc npc, GameProvider gp) {
    if (!npc.alive) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.border)),
        color: AppTheme.bgCard,
      ),
      child: Row(
        children: [
          Expanded(
            child: TerminalButton(
              label: 'PROFISSÃO',
              icon: Icons.work_outline,
              color: AppTheme.blue,
              expanded: true,
              onPressed: () => _showProfessionDialog(context, npc, gp),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TerminalButton(
              label: 'PUNIR',
              icon: Icons.gavel,
              color: AppTheme.red,
              expanded: true,
              onPressed: gp.citadel.hasBuilding(BuildingType.prison)
                  ? () => _showPunishDialog(context, npc, gp)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  // ── Dialog: Designar profissão ─────────────────────────────

  void _showProfessionDialog(BuildContext context, Npc npc, GameProvider gp) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: AppTheme.blue),
        ),
        title: const TerminalText(
          'DESIGNAR PROFISSÃO',
          fontSize: 14,
          color: AppTheme.blue,
          fontWeight: FontWeight.bold,
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: Profession.values.map((p) {
              final active = npc.profession == p;
              return GestureDetector(
                onTap: () {
                  gp.assignProfession(npc.id, p);
                  Navigator.pop(ctx);
                  setState(() {});
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: active ? AppTheme.blue : AppTheme.border,
                    ),
                    borderRadius: BorderRadius.circular(3),
                    color: active ? AppTheme.blue.withValues(alpha: 0.1) : null,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TerminalText(
                          p.label,
                          fontSize: 12,
                          color: active ? AppTheme.blue : AppTheme.textPrimary,
                        ),
                      ),
                      if (active)
                        const TerminalText(
                          '✓',
                          fontSize: 12,
                          color: AppTheme.blue,
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TerminalButton(
            label: 'CANCELAR',
            color: AppTheme.textDim,
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  // ── Dialog: Punir ──────────────────────────────────────────

  void _showPunishDialog(BuildContext context, Npc npc, GameProvider gp) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: AppTheme.red),
        ),
        title: const TerminalText(
          'PUNIR HABITANTE',
          fontSize: 14,
          color: AppTheme.red,
          fontWeight: FontWeight.bold,
        ),
        content: TerminalText(
          'Enviar ${npc.name} para a prisão?\nIsso afetará a moral da cidadela e a lealdade de aliados.',
          fontSize: 11,
          color: AppTheme.textSecondary,
        ),
        actions: [
          TerminalButton(
            label: 'CANCELAR',
            color: AppTheme.textDim,
            onPressed: () => Navigator.pop(ctx),
          ),
          TerminalButton(
            label: 'PRENDER',
            icon: Icons.lock,
            color: AppTheme.red,
            onPressed: () {
              Navigator.pop(ctx);
              final result = gp.arrestNpc(npc.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppTheme.bgCard,
                  content: TerminalText(
                    result,
                    fontSize: 12,
                    color: AppTheme.red,
                  ),
                ),
              );
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────

  Widget _tag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(2),
      ),
      child: TerminalText(label, fontSize: 9, color: color),
    );
  }

  String _arenaTitle(int wins) {
    if (wins >= 30) return 'Imortal da Arena';
    if (wins >= 20) return 'Campeão Lendário';
    if (wins >= 10) return 'Campeão da Arena';
    if (wins >= 5) return 'Lutador Destaque';
    return 'Gladiador';
  }
}

// ── Widgets auxiliares ─────────────────────────────────────────────────────

class _EquipSlot extends StatelessWidget {
  final String label;
  final String icon;
  final Equipment? equipment;
  const _EquipSlot({
    required this.label,
    required this.icon,
    required this.equipment,
  });

  @override
  Widget build(BuildContext context) {
    final eq = equipment;
    final rarityColor = eq == null
        ? AppTheme.border
        : switch (eq.rarity) {
            EquipmentRarity.common => AppTheme.textDim,
            EquipmentRarity.uncommon => AppTheme.green,
            EquipmentRarity.rare => AppTheme.blue,
            EquipmentRarity.epic => AppTheme.purple,
            EquipmentRarity.legendary => AppTheme.yellow,
            // ignore: unreachable_switch_case
            _ => AppTheme.textDim,
          };

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: rarityColor.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(3),
          color: rarityColor.withValues(alpha: 0.04),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 10)),
                const SizedBox(width: 4),
                TerminalText(label, fontSize: 7, color: AppTheme.textDim),
              ],
            ),
            const SizedBox(height: 4),
            if (eq == null)
              const TerminalText('—', fontSize: 8, color: AppTheme.textDim)
            else ...[
              TerminalText(
                eq.name,
                fontSize: 8,
                color: rarityColor,
                fontWeight: FontWeight.bold,
              ),
              const SizedBox(height: 2),
              TerminalText(
                eq.bonusSummary,
                fontSize: 7,
                color: AppTheme.textSecondary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

bool _hasSpecialCapabilities(Npc npc) {
  final a = npc.attributes;
  return a.canHealAfterBattle ||
      a.canEvadeCombat ||
      a.canCraftMedicine ||
      a.canTameCreatures ||
      a.canRevealSecrets ||
      a.immuneToSanityLoss ||
      a.equipmentBonusMultiplier > 1.0 ||
      a.combatPowerMultiplier > 1.0 ||
      a.groupMortalityReduction > 0 ||
      a.groupMoraleBonus > 0 ||
      a.groupSynergyBonus > 0;
}

List<Widget> _buildCapabilities(Npc npc) {
  final a = npc.attributes;
  final caps = <(String, String, Color)>[];
  if (a.canHealAfterBattle)
    caps.add(('✚', 'Cura aliados após batalha', AppTheme.green));
  if (a.canEvadeCombat) caps.add(('◈', 'Pode evadir combate', AppTheme.blue));
  if (a.canCraftMedicine) caps.add(('⚗', 'Cria medicamentos', AppTheme.green));
  if (a.canTameCreatures) caps.add(('⬡', 'Domina criaturas', AppTheme.yellow));
  if (a.canRevealSecrets)
    caps.add(('◉', 'Revela segredos da Torre', AppTheme.purple));
  if (a.immuneToSanityLoss)
    caps.add(('◇', 'Imune à perda de sanidade', AppTheme.cyan));
  if (a.equipmentBonusMultiplier > 1.0) {
    caps.add((
      '⚒',
      'Equipamentos ${a.equipmentBonusMultiplier.toStringAsFixed(1)}x',
      AppTheme.orange,
    ));
  }
  if (a.combatPowerMultiplier > 1.0) {
    caps.add((
      '⚡',
      'Combate ${a.combatPowerMultiplier.toStringAsFixed(1)}x',
      AppTheme.red,
    ));
  }
  if (a.groupMortalityReduction > 0) {
    caps.add((
      '☯',
      '−${(a.groupMortalityReduction * 100).toStringAsFixed(0)}% mortalidade',
      AppTheme.green,
    ));
  }
  if (a.groupMoraleBonus > 0) {
    caps.add((
      '♦',
      '+${(a.groupMoraleBonus * 100).toStringAsFixed(0)}% moral do grupo',
      AppTheme.yellow,
    ));
  }
  if (a.groupSynergyBonus > 0) {
    caps.add((
      '∞',
      '+${(a.groupSynergyBonus * 100).toStringAsFixed(0)}% sinergia',
      AppTheme.cyan,
    ));
  }

  return caps
      .map(
        (c) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              TerminalText('${c.$1} ', fontSize: 10, color: c.$3),
              Expanded(
                child: TerminalText(
                  c.$2,
                  fontSize: 10,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      )
      .toList();
}
