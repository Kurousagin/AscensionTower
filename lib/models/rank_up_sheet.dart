// lib/screens/rank_up_sheet.dart
//
// RankUpSheet — widgets e bottom sheets do sistema de promoção de rank.
// Extraído de NpcDetailScreen para manter responsabilidade única.

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import '../providers/game_provider.dart';
import '../models/npc.dart';
import '../widgets/theme.dart';
import '../widgets/terminal_widgets.dart';

// Cores de rank — espelhadas de NpcDetailScreen para evitar dependência circular
Color rankColor(NpcRank rank) {
  switch (rank) {
    case NpcRank.ssr:
      return const Color(0xFFECC94B);
    case NpcRank.sr:
      return const Color(0xFF00B4D8);
    case NpcRank.r:
      return const Color(0xFF48BB78);
    case NpcRank.n:
      return const Color(0xFF718096);
  }
}

// ── Seção de rank inline ───────────────────────────────────

Widget buildRankSection(BuildContext context, Npc npc, GameProvider gp) {
  final color = rankColor(npc.rank);
  // Só mostra estrelas se o NPC já tem alguma — evita ☆☆☆☆☆ em NPCs novos
  final starsStr = npc.stars > 0
      ? '${'★' * npc.stars}${'☆' * (5 - npc.stars)}'
      : '';
  return Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      border: Border.all(color: color.withValues(alpha: 0.3)),
      borderRadius: BorderRadius.circular(4),
      color: color.withValues(alpha: 0.05),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                border: Border.all(
                  color: color.withValues(alpha: 0.8),
                  width: npc.isPromoted ? 1.5 : 1.0,
                ),
                borderRadius: BorderRadius.circular(3),
                color: color.withValues(alpha: 0.1),
              ),
              child: TerminalText(
                '${npc.rank.label}${npc.isPromoted ? '*' : ''}',
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 10),
            if (npc.stars > 0)
              TerminalText(
                starsStr,
                fontSize: 14,
                color: const Color(0xFFECC94B),
              ),
            if (npc.stars == 0)
              TerminalText(
                'Sem estrelas',
                fontSize: 9,
                color: AppTheme.textDim,
              ),
            const Spacer(),
            if (npc.isPromoted)
              TerminalText('promovido', fontSize: 8, color: AppTheme.textDim),
          ],
        ),
        const SizedBox(height: 6),
        TerminalText(
          npc.rank == NpcRank.ssr && npc.stars == 5
              ? 'Teto absoluto atingido.'
              : npc.isPromoted
              ? 'Este NPC atingiu o limite de promoções.'
              : npc.stars < 5
              ? 'Sacrifique 1 NPC ${npc.rank.label} para ganhar uma estrela.'
              : 'Pronto para promoção. Requer 3 NPCs ${npc.rank.label}★★★★★.',
          fontSize: 9,
          color: AppTheme.textSecondary,
        ),
      ],
    ),
  );
}

// ── Bottom sheet: adicionar estrela ───────────────────────

void showAddStarSheet(BuildContext context, Npc target, GameProvider gp) {
  final starsNeeded = 5 - target.stars;
  final candidates =
      gp.aliveNpcs
          .where(
            (n) => n.id != target.id && n.rank == target.rank && !n.isFavorite,
          )
          .toList()
        ..sort((a, b) => b.attributes.average.compareTo(a.attributes.average));

  if (candidates.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nenhum NPC disponível para sacrifício.')),
    );
    return;
  }

  final selected = <String>{};

  showModalBottomSheet(
    context: context,
    backgroundColor: AppTheme.bgCard,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      side: BorderSide(color: AppTheme.border),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        expand: false,
        builder: (ctx, scroll) => Column(
          children: [
            Center(
              child: Container(
                width: 36,
                height: 3,
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TerminalText(
                    'ADICIONAR ESTRELA — ${target.name}',
                    fontSize: 13,
                    color: const Color(0xFFECC94B),
                    fontWeight: FontWeight.bold,
                  ),
                  const SizedBox(height: 4),
                  TerminalText(
                    'Selecione até $starsNeeded NPC${starsNeeded > 1 ? 's' : ''} '
                    '${target.rank.label} para sacrificar. '
                    '${selected.length}/$starsNeeded selecionado${selected.length != 1 ? 's' : ''}.',
                    fontSize: 9,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(height: 4),
                  // Preview das estrelas após sacrifício
                  Row(
                    children: [
                      TerminalText(
                        '${'★' * target.stars}${'☆' * (5 - target.stars)}',
                        fontSize: 12,
                        color: AppTheme.textDim,
                      ),
                      if (selected.isNotEmpty) ...[
                        const TerminalText(
                          '  →  ',
                          fontSize: 10,
                          color: AppTheme.textDim,
                        ),
                        TerminalText(
                          '${'★' * (target.stars + selected.length)}${'☆' * (5 - target.stars - selected.length)}',
                          fontSize: 12,
                          color: const Color(0xFFECC94B),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Container(height: 1, color: AppTheme.border),
            Expanded(
              child: ListView.builder(
                controller: scroll,
                itemCount: candidates.length,
                itemBuilder: (ctx, i) {
                  final c = candidates[i];
                  final isSelected = selected.contains(c.id);
                  final canSelect = isSelected || selected.length < starsNeeded;
                  return GestureDetector(
                    onTap: canSelect
                        ? () => setState(
                            () => isSelected
                                ? selected.remove(c.id)
                                : selected.add(c.id),
                          )
                        : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.red.withValues(alpha: 0.1)
                            : !canSelect
                            ? AppTheme.bgCard.withValues(alpha: 0.5)
                            : null,
                        border: Border(
                          bottom: BorderSide(color: AppTheme.border),
                          left: BorderSide(
                            color: isSelected
                                ? AppTheme.red
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TerminalText(
                                  c.name,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: !canSelect && !isSelected
                                      ? AppTheme.textDim
                                      : AppTheme.textPrimary,
                                ),
                                TerminalText(
                                  '${c.rank.label}${'★' * c.stars} · '
                                  'Média ${c.attributes.average.toStringAsFixed(1)} · '
                                  '${c.profession.label}',
                                  fontSize: 8,
                                  color: AppTheme.textDim,
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.close,
                              size: 16,
                              color: AppTheme.red,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppTheme.border)),
              ),
              child: TerminalButton(
                label: selected.isEmpty
                    ? 'SELECIONE OS SACRIFICADOS'
                    : selected.length == 1
                    ? 'SACRIFICAR 1 NPC (+1★)'
                    : 'SACRIFICAR ${selected.length} NPCs (+${selected.length}★)',
                icon: Icons.auto_awesome,
                color: selected.isNotEmpty ? AppTheme.red : AppTheme.textDim,
                expanded: true,
                onPressed: selected.isEmpty
                    ? null
                    : () {
                        Navigator.pop(ctx);
                        String lastResult = '';
                        for (final id in selected.toList()) {
                          lastResult = gp.addStar(target.id, id);
                        }
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(lastResult)));
                      },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
// ── Bottom sheet: promover rank ────────────────────────────

void showPromotionSheet(BuildContext context, Npc target, GameProvider gp) {
  final candidates =
      gp.aliveNpcs
          .where(
            (n) =>
                n.id != target.id &&
                n.rank == target.rank &&
                n.stars == 5 &&
                !n.isFavorite,
          )
          .toList()
        ..sort((a, b) => b.attributes.average.compareTo(a.attributes.average));

  if (candidates.length < 3) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Necessário 3 NPCs ${target.rank.label}★★★★★. '
          'Disponíveis: ${candidates.length}.',
        ),
      ),
    );
    return;
  }

  final selected = <String>{};
  final newRank = NpcRank.values[target.rank.index + 1];

  showModalBottomSheet(
    context: context,
    backgroundColor: AppTheme.bgCard,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      side: BorderSide(color: AppTheme.border),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        final chance = calcPromotionChance(target, selected, gp);
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (ctx, scroll) => Column(
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 3,
                  margin: const EdgeInsets.only(top: 10, bottom: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TerminalText(
                      'PROMOVER — ${target.name}',
                      fontSize: 13,
                      color: const Color(0xFFECC94B),
                      fontWeight: FontWeight.bold,
                    ),
                    const SizedBox(height: 4),
                    TerminalText(
                      '${target.rank.label}★★★★★  →  ${newRank.label}★',
                      fontSize: 10,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(height: 4),
                    TerminalText(
                      'Selecione 3 NPCs ${target.rank.label}★★★★★ para sacrificar.',
                      fontSize: 9,
                      color: AppTheme.textDim,
                    ),
                    if (selected.length == 3) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.casino_outlined,
                            size: 12,
                            color: AppTheme.yellow,
                          ),
                          const SizedBox(width: 4),
                          TerminalText(
                            'Chance de sucesso: ${(chance * 100).toStringAsFixed(0)}%',
                            fontSize: 10,
                            color: chance >= 0.6
                                ? AppTheme.green
                                : chance >= 0.35
                                ? AppTheme.yellow
                                : AppTheme.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      TerminalText(
                        'Falha: sacrificados se vão. ${target.name} volta ao 4★.',
                        fontSize: 8,
                        color: AppTheme.red,
                      ),
                    ],
                  ],
                ),
              ),
              Container(height: 1, color: AppTheme.border),
              Expanded(
                child: ListView.builder(
                  controller: scroll,
                  itemCount: candidates.length,
                  itemBuilder: (ctx, i) {
                    final c = candidates[i];
                    final isSelected = selected.contains(c.id);
                    final canSelect = isSelected || selected.length < 3;
                    return GestureDetector(
                      onTap: canSelect
                          ? () => setState(
                              () => isSelected
                                  ? selected.remove(c.id)
                                  : selected.add(c.id),
                            )
                          : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.red.withValues(alpha: 0.1)
                              : !canSelect
                              ? AppTheme.bgCard.withValues(alpha: 0.5)
                              : null,
                          border: Border(
                            bottom: BorderSide(color: AppTheme.border),
                            left: BorderSide(
                              color: isSelected
                                  ? AppTheme.red
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TerminalText(
                                    c.name,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: !canSelect && !isSelected
                                        ? AppTheme.textDim
                                        : AppTheme.textPrimary,
                                  ),
                                  TerminalText(
                                    '${c.rank.label}★★★★★ · '
                                    'Média ${c.attributes.average.toStringAsFixed(1)}',
                                    fontSize: 8,
                                    color: AppTheme.textDim,
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.close,
                                size: 16,
                                color: AppTheme.red,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppTheme.border)),
                ),
                child: TerminalButton(
                  label: selected.length < 3
                      ? 'SELECIONE 3 SACRIFICADOS (${selected.length}/3)'
                      : 'INICIAR RITUAL',
                  icon: Icons.auto_awesome,
                  color: selected.length == 3 ? AppTheme.red : AppTheme.textDim,
                  expanded: true,
                  onPressed: selected.length != 3
                      ? null
                      : () {
                          Navigator.pop(ctx);
                          confirmPromotion(
                            context,
                            target,
                            selected.toList(),
                            gp,
                          );
                        },
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

double calcPromotionChance(
  Npc target,
  Set<String> selectedIds,
  GameProvider gp,
) {
  if (selectedIds.length != 3) return 0;
  final sacrifices = selectedIds
      .map((id) => gp.aliveNpcs.firstWhereOrNull((n) => n.id == id))
      .whereType<Npc>()
      .toList();
  if (sacrifices.length != 3) return 0;
  final targetAvg = target.attributes.average;
  final sacrificeAvg =
      sacrifices.fold(0.0, (s, n) => s + n.attributes.average) / 3;
  final ratio = (sacrificeAvg / targetAvg.clamp(1, 9999)).clamp(0.5, 2.0);
  final (min, max) = switch (target.rank) {
    NpcRank.n => (0.50, 0.85),
    NpcRank.r => (0.35, 0.70),
    NpcRank.sr => (0.20, 0.50),
    _ => (0.0, 0.0),
  };
  return (min + (max - min) * ((ratio - 0.5) / 1.5)).clamp(min, max);
}

void confirmPromotion(
  BuildContext context,
  Npc target,
  List<String> sacrificeIds,
  GameProvider gp,
) {
  final names = sacrificeIds
      .map((id) => gp.aliveNpcs.firstWhereOrNull((n) => n.id == id)?.name ?? id)
      .join(', ');
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppTheme.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: const BorderSide(color: AppTheme.red),
      ),
      title: const TerminalText(
        'CONFIRMAR RITUAL',
        fontSize: 14,
        color: AppTheme.red,
        fontWeight: FontWeight.bold,
      ),
      content: TerminalText(
        '$names serão consumidos permanentemente.\n\n'
        'Mesmo em caso de falha, eles desaparecem.\n\n'
        'Tem certeza?',
        fontSize: 10,
        color: AppTheme.textPrimary,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const TerminalText('CANCELAR', color: AppTheme.textDim),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(ctx);
            final result = gp.attemptPromotion(target.id, sacrificeIds);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result),
                backgroundColor: result.startsWith('SUCESSO')
                    ? AppTheme.green.withValues(alpha: 0.9)
                    : AppTheme.red.withValues(alpha: 0.9),
                duration: const Duration(seconds: 4),
              ),
            );
          },
          child: const TerminalText(
            'SACRIFICAR',
            color: AppTheme.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}
