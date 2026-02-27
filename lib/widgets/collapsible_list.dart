// lib/widgets/collapsible_list.dart
//
// Widget genérico de lista recolhível.
// Mostra `initialCount` itens e exibe botão "+ ver mais / recolher".
//
// USO BÁSICO:
//   CollapsibleList(
//     items: npcs,
//     initialCount: 5,
//     itemBuilder: (npc, i) => NpcCard(npc: npc),
//   )
//
// COM TÍTULO:
//   CollapsibleList(
//     label: 'Expedicionários',
//     items: npcs,
//     initialCount: 5,
//     itemBuilder: (npc, i) => NpcCard(npc: npc),
//   )

import 'package:flutter/material.dart';
import 'theme.dart';
import 'terminal_widgets.dart';

class CollapsibleList<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(T item, int index) itemBuilder;
  final int initialCount;
  final String? label; // título opcional acima da lista
  final EdgeInsets? padding;
  final bool startExpanded; // começa expandido se true

  const CollapsibleList({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.initialCount = 5,
    this.label,
    this.padding,
    this.startExpanded = false,
  });

  @override
  State<CollapsibleList<T>> createState() => _CollapsibleListState<T>();
}

class _CollapsibleListState<T> extends State<CollapsibleList<T>> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded =
        widget.startExpanded || widget.items.length <= widget.initialCount;
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.items.length;
    final showButton = total > widget.initialCount;
    final visibleCount = _expanded
        ? total
        : widget.initialCount.clamp(0, total);
    final hiddenCount = total - widget.initialCount;

return Padding(
  padding: widget.padding ?? EdgeInsets.zero,
  child: SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          // ── Título opcional ───────────────────
          if (widget.label != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(width: 2, height: 12, color: AppTheme.cyan),
                  const SizedBox(width: 6),
                  TerminalText(
                    widget.label!.toUpperCase(),
                    fontSize: 8,
                    color: AppTheme.textDim,
                    fontWeight: FontWeight.bold,
                  ),
                  const SizedBox(width: 8),
                  TerminalText(
                    '($total)',
                    fontSize: 8,
                    color: AppTheme.textDim,
                  ),
                ],
              ),
            ),

          // ── Itens visíveis ────────────────────
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: visibleCount,
            itemBuilder: (context, i) => widget.itemBuilder(widget.items[i], i),
          ),

          // ── Botão expandir/recolher ───────────
          if (showButton)
            _ExpandButton(
              expanded: _expanded,
              hiddenCount: hiddenCount,
              onTap: () => setState(() => _expanded = !_expanded),
            ),
        ],
      ),
    ));
  }
}

class _ExpandButton extends StatelessWidget {
  final bool expanded;
  final int hiddenCount;
  final VoidCallback onTap;

  const _ExpandButton({
    required this.expanded,
    required this.hiddenCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          border: Border.all(color: AppTheme.border),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TerminalText(
              expanded ? '▲  RECOLHER' : '▼  VER MAIS  (+$hiddenCount)',
              fontSize: 8,
              color: AppTheme.cyan,
              fontWeight: FontWeight.bold,
            ),
          ],
        ),
      ),
    );
  }
}
