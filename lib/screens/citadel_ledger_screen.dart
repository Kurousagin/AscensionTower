// lib/screens/citadel_ledger_screen.dart
//
// REGISTRO OFICIAL DA CIDADELA
// Substitui o EventLogScreen antigo.
// ─ Exibe somente registros permanentes e relevantes (CitadelRecord)
// ─ Eventos menores (craft, treino rotineiro) ficam só no Toast
// ─ Limpeza automática: GameEngine mantém apenas os últimos N eventos brutos

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/citadel_record.dart';
import '../widgets/theme.dart';
import '../widgets/terminal_widgets.dart';

class CitadelLedgerScreen extends StatefulWidget {
  const CitadelLedgerScreen({super.key});

  @override
  State<CitadelLedgerScreen> createState() => _CitadelLedgerScreenState();
}

class _CitadelLedgerScreenState extends State<CitadelLedgerScreen>
    with SingleTickerProviderStateMixin {
  RecordCategory? _filter;
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gp, _) {
        return ScanlineOverlay(
          child: Column(
            children: [
              _buildHeader(gp),
              _buildTabs(),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [_buildLedgerTab(gp), _buildStatsTab(gp)],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────
  // HEADER
  // ─────────────────────────────────────────

  Widget _buildHeader(GameProvider gp) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 3, height: 20, color: AppTheme.cyan),
              const SizedBox(width: 8),
              TerminalText(
                'REGISTRO OFICIAL DA CIDADELA',
                fontSize: 11,
                color: AppTheme.cyan,
                fontWeight: FontWeight.bold,
              ),
              const Spacer(),
              TerminalText(
                'DIA ${gp.engine.state.currentDay}',
                fontSize: 9,
                color: AppTheme.textDim,
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildFilterBar(),
          const SizedBox(height: 2),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // FILTER BAR
  // ─────────────────────────────────────────

  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filterChip('TODOS', null),
          _filterChip('ORDEM', RecordCategory.decree),
          _filterChip('CRIME', RecordCategory.crime),
          _filterChip('OBITO', RecordCategory.death),
          _filterChip('NASCIMENTO', RecordCategory.birth),
          _filterChip('CONSTRUCAO', RecordCategory.construction),
          _filterChip('CONQUISTA', RecordCategory.towerConquest),
          _filterChip('DECRETO', RecordCategory.political),
          _filterChip('HONRARIA', RecordCategory.honor),
          _filterChip('PUNICAO', RecordCategory.punishment),
          _filterChip('⚔ Guerra', RecordCategory.war),
          _filterChip('📖 Lore', RecordCategory.lore),
        ],
      ),
    );
  }

  Widget _filterChip(String label, RecordCategory? value) {
    final active = _filter == value;
    final color = value != null
        ? Color(int.parse(value.colorHex.replaceFirst('#', '0xFF')))
        : AppTheme.cyan;
    return Padding(
      padding: const EdgeInsets.only(right: 5, bottom: 8),
      child: GestureDetector(
        onTap: () => setState(() => _filter = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            border: Border.all(
              color: active ? color : AppTheme.border,
              width: active ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(2),
            color: active ? color.withValues(alpha: 0.12) : null,
          ),
          child: TerminalText(
            label,
            fontSize: 7,
            color: active ? color : AppTheme.textDim,
            fontWeight: active ? FontWeight.bold : null,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // TABS
  // ─────────────────────────────────────────

  Widget _buildTabs() {
    return Container(
      color: AppTheme.bgCard,
      child: TabBar(
        controller: _tabs,
        indicatorColor: AppTheme.cyan,
        indicatorWeight: 1.5,
        labelPadding: const EdgeInsets.symmetric(horizontal: 16),
        tabs: [_tab('REGISTROS'), _tab('RESUMO')],
      ),
    );
  }

  Widget _tab(String label) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: TerminalText(label, fontSize: 9, color: AppTheme.textSecondary),
  );

  // ─────────────────────────────────────────
  // LEDGER TAB
  // ─────────────────────────────────────────

  Widget _buildLedgerTab(GameProvider gp) {
    var records = gp.citadelRecords.reversed.toList();
    if (_filter != null) {
      records = records.where((r) => r.category == _filter).toList();
    }

    if (records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TerminalText(
              '[ SEM REGISTROS ]',
              fontSize: 10,
              color: AppTheme.textDim,
            ),
            const SizedBox(height: 6),
            TerminalText(
              'Nenhum evento de relevancia foi documentado.',
              fontSize: 8,
              color: AppTheme.textDim,
            ),
          ],
        ),
      );
    }

    // Agrupa por dia
    final byDay = <int, List<CitadelRecord>>{};
    for (final r in records) {
      byDay.putIfAbsent(r.day, () => []).add(r);
    }
    final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: days.length,
      itemBuilder: (context, i) {
        final day = days[i];
        return _buildDaySection(day, byDay[day]!, gp);
      },
    );
  }

  Widget _buildDaySection(
    int day,
    List<CitadelRecord> records,
    GameProvider gp,
  ) {
    final weekNum = (day / 7).ceil();
    String label;
    if (weekNum < 4) {
      label = 'Semana $weekNum';
    } else {
      final m = weekNum ~/ 4;
      final rw = weekNum % 4;
      if (m < 12) {
        label = rw > 0 ? 'Mes $m, Sem $rw' : 'Mes $m';
      } else {
        final y = m ~/ 12;
        final rm = m % 12;
        label = 'Ano $y, Mes $rm';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(child: Container(height: 1, color: AppTheme.border)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: TerminalText(
                  '$label  —  Dia $day',
                  fontSize: 8,
                  color: AppTheme.textDim,
                ),
              ),
              Expanded(child: Container(height: 1, color: AppTheme.border)),
            ],
          ),
        ),
        ...records.map((r) => _buildRecordCard(r, gp)),
      ],
    );
  }

  Widget _buildRecordCard(CitadelRecord record, GameProvider gp) {
    final color = Color(
      int.parse(record.category.colorHex.replaceFirst('#', '0xFF')),
    );
    final isLore = record.category == RecordCategory.lore;
    final isGuerra = record.category == RecordCategory.war;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        border: Border.all(
          color: isLore
              ? AppTheme.blue
              : isGuerra
              ? AppTheme.red
              : AppTheme.border,
        ),
      ),
      foregroundDecoration: BoxDecoration(
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header da linha
          Container(
            padding: const EdgeInsets.fromLTRB(10, 7, 10, 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.06),
              border: Border(bottom: BorderSide(color: AppTheme.border)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    border: Border.all(color: color.withValues(alpha: 0.6)),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: TerminalText(
                    record.category.label,
                    fontSize: 7,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      if (isLore) ...[
                        const Text('📖', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 4),
                      ] else if (isGuerra) ...[
                        const Text('⚔', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: TerminalText(
                          record.title,
                          fontSize: 10,
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (record.isSigned) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppTheme.yellow.withValues(alpha: 0.5),
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: TerminalText(
                      '✦ OFICIAL',
                      fontSize: 7,
                      color: AppTheme.yellow,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Corpo do registro
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TerminalText(
                  record.body,
                  fontSize: 9,
                  color: AppTheme.textSecondary,
                ),
                if (record.verdict != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.08),
                      border: Border.all(color: color.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Row(
                      children: [
                        TerminalText(
                          'VEREDICTO: ',
                          fontSize: 8,
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                        Expanded(
                          child: TerminalText(
                            record.verdict!,
                            fontSize: 8,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (record.involvedIds.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _buildInvolvedNpcs(record.involvedIds, gp),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvolvedNpcs(List<String> ids, GameProvider gp) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: ids.map((id) {
        final npc = gp.engine.npcs.firstWhereOrNull((n) => n.id == id);
        if (npc == null) return const SizedBox.shrink();
        final alive = npc.alive;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            border: Border.all(
              color: alive
                  ? AppTheme.border
                  : AppTheme.red.withValues(alpha: 0.4),
            ),
            borderRadius: BorderRadius.circular(2),
          ),
          child: TerminalText(
            alive ? npc.name : '✝ ${npc.name}',
            fontSize: 7,
            color: alive ? AppTheme.textSecondary : AppTheme.red,
          ),
        );
      }).toList(),
    );
  }

  // ─────────────────────────────────────────
  // STATS TAB
  // ─────────────────────────────────────────

  Widget _buildStatsTab(GameProvider gp) {
    final records = gp.citadelRecords;
    final engine = gp.engine;

    final Map<RecordCategory, int> counts = {};
    for (final r in records) {
      counts[r.category] = (counts[r.category] ?? 0) + 1;
    }

    final topCriminals = <String, int>{};
    for (final r in records.where((r) => r.category == RecordCategory.crime)) {
      for (final id in r.involvedIds) {
        topCriminals[id] = (topCriminals[id] ?? 0) + 1;
      }
    }
    final sortedCriminals = topCriminals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _statSection('SUMARIO DA CIDADELA', [
          _statRow('Total de registros', '${records.length}', AppTheme.cyan),
          _statRow(
            'Mortos registrados',
            '${engine.state.totalDeaths}',
            AppTheme.red,
          ),
          _statRow(
            'Nascimentos',
            '${engine.state.totalBirths}',
            AppTheme.green,
          ),
          _statRow(
            'Andares conquistados',
            '${engine.state.highestFloorCleared}',
            AppTheme.yellow,
          ),
          _statRow('Populacao atual', '${engine.population}', AppTheme.cyan),
        ]),
        const SizedBox(height: 16),
        _statSection('REGISTROS POR CATEGORIA', [
          for (final cat in RecordCategory.values)
            if ((counts[cat] ?? 0) > 0)
              _statRow(
                cat.label,
                '${counts[cat]}',
                Color(int.parse(cat.colorHex.replaceFirst('#', '0xFF'))),
              ),
        ]),
        if (sortedCriminals.isNotEmpty) ...[
          const SizedBox(height: 16),
          _statSection('FICHA CRIMINAL', [
            for (final entry in sortedCriminals.take(5)) ...[
              Builder(
                builder: (ctx) {
                  final npc = engine.npcs.firstWhereOrNull(
                    (n) => n.id == entry.key,
                  );
                  if (npc == null) return const SizedBox.shrink();
                  return _statRow(
                    npc.name + (npc.alive ? '' : ' ✝'),
                    '${entry.value} ocorrencia(s)',
                    npc.alive ? AppTheme.red : AppTheme.textDim,
                  );
                },
              ),
            ],
          ]),
        ],
      ],
    );
  }

  Widget _statSection(String title, List<Widget> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppTheme.border)),
          ),
          child: TerminalText(
            title,
            fontSize: 9,
            color: AppTheme.cyan,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        ...rows,
      ],
    );
  }

  Widget _statRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          TerminalText(label, fontSize: 9, color: AppTheme.textSecondary),
          const Spacer(),
          TerminalText(
            value,
            fontSize: 9,
            color: valueColor,
            fontWeight: FontWeight.bold,
          ),
        ],
      ),
    );
  }
}

// helper
extension _ListWhereOrNull<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}
