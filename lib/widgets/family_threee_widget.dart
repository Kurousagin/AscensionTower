import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import '../models/npc.dart';
import '../widgets/theme.dart';
import '../widgets/terminal_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FamilyTreeWidget
//
// Renderiza até 3 gerações em torno do NPC focal:
//   Avós → Pais → [NPC + Parceiro] → Filhos
//
// Uso:
//   FamilyTreeWidget(focal: npc, allNpcs: gp.allNpcs, onNodeTap: (npc) { ... })
// ─────────────────────────────────────────────────────────────────────────────

class FamilyTreeWidget extends StatefulWidget {
  final Npc focal;
  final List<Npc> allNpcs;
  final void Function(Npc)? onNodeTap;

  const FamilyTreeWidget({
    super.key,
    required this.focal,
    required this.allNpcs,
    this.onNodeTap,
  });

  @override
  State<FamilyTreeWidget> createState() => _FamilyTreeWidgetState();
}

class _FamilyTreeWidgetState extends State<FamilyTreeWidget> {
  final TransformationController _transform = TransformationController();
  String? _hoveredId;

  @override
  void initState() {
    super.initState();
    // Centraliza a view no NPC focal ao abrir
    WidgetsBinding.instance.addPostFrameCallback((_) => _centerOnFocal());
  }

  @override
  void didUpdateWidget(FamilyTreeWidget old) {
    super.didUpdateWidget(old);
    if (old.focal.id != widget.focal.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _centerOnFocal());
    }
  }

  void _centerOnFocal() {
    if (!mounted) return;
    final size = MediaQuery.of(context).size;
    final layout = _buildLayout();
    final focalNode = layout.firstWhereOrNull((n) => n.npc.id == widget.focal.id);
    if (focalNode == null) return;
    final cx = focalNode.x + _kNodeW / 2;
    final cy = focalNode.y + _kNodeH / 2;
    final tx = size.width / 2 - cx;
    final ty = size.height * 0.4 - cy;
    _transform.value = Matrix4.identity()..translate(tx, ty);
  }

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  // ── Layout ──────────────────────────────────────────────────

  List<_NodeData> _buildLayout() {
    final all = widget.allNpcs;
    final focal = widget.focal;
    final nodes = <_NodeData>[];

    Npc? find(String? id) =>
        id == null ? null : all.firstWhereOrNull((n) => n.id == id);

    final parentA = find(focal.parentAId);
    final parentB = find(focal.parentBId);
    final partner = find(focal.partnerId);
    final children = focal.childrenIds
        .map((id) => find(id))
        .whereType<Npc>()
        .toList();

    // Avós (geração -2)
    final grandparents = <Npc>[];
    if (parentA != null) {
      final gpA = find(parentA.parentAId);
      final gpB = find(parentA.parentBId);
      if (gpA != null) grandparents.add(gpA);
      if (gpB != null) grandparents.add(gpB);
    }
    if (parentB != null) {
      final gpA = find(parentB.parentAId);
      final gpB = find(parentB.parentBId);
      if (gpA != null && !grandparents.any((g) => g.id == gpA.id))
        grandparents.add(gpA);
      if (gpB != null && !grandparents.any((g) => g.id == gpB.id))
        grandparents.add(gpB);
    }

    // ── Posicionamento por linha ──────────────────────────────
    const double rowH = _kNodeH + _kRowGap;
    const double colW = _kNodeW + _kColGap;

    // Linha 0 — avós
    final gpCount = grandparents.length;
    for (int i = 0; i < gpCount; i++) {
      final x = (i - (gpCount - 1) / 2.0) * colW;
      nodes.add(_NodeData(npc: grandparents[i], x: x, y: 0, role: _Role.ancestor));
    }

    // Linha 1 — pais
    final parents = <Npc>[];
    if (parentA != null) parents.add(parentA);
    if (parentB != null) parents.add(parentB);
    final pCount = parents.length;
    for (int i = 0; i < pCount; i++) {
      final x = (i - (pCount - 1) / 2.0) * colW;
      nodes.add(_NodeData(npc: parents[i], x: x, y: rowH, role: _Role.parent));
    }

    // Linha 2 — focal + parceiro
    final focalX = partner != null ? -colW / 2 : 0.0;
    nodes.add(_NodeData(npc: focal, x: focalX, y: rowH * 2, role: _Role.focal));
    if (partner != null) {
      nodes.add(_NodeData(
          npc: partner, x: colW / 2, y: rowH * 2, role: _Role.partner));
    }

    // Linha 3 — filhos
    final cCount = children.length;
    for (int i = 0; i < cCount; i++) {
      final x = (i - (cCount - 1) / 2.0) * colW;
      nodes.add(
          _NodeData(npc: children[i], x: x, y: rowH * 3, role: _Role.child));
    }

    return nodes;
  }

  // ── Conexões ────────────────────────────────────────────────

  List<_EdgeData> _buildEdges(List<_NodeData> nodes) {
    final edges = <_EdgeData>[];
    final focal = widget.focal;
    final all = widget.allNpcs;

    Npc? find(String? id) =>
        id == null ? null : all.firstWhereOrNull((n) => n.id == id);

    _NodeData? nodeOf(String id) =>
        nodes.firstWhereOrNull((n) => n.npc.id == id);

    final focalNode = nodeOf(focal.id);
    if (focalNode == null) return edges;

    // Pai → focal
    for (final pid in [focal.parentAId, focal.parentBId]) {
      if (pid == null) continue;
      final pNode = nodeOf(pid);
      if (pNode != null) {
        edges.add(_EdgeData(from: pNode, to: focalNode, type: _EdgeType.parent));
      }
    }

    // Avós → pais
    for (final parentId in [focal.parentAId, focal.parentBId]) {
      if (parentId == null) continue;
      final parent = find(parentId);
      if (parent == null) continue;
      final pNode = nodeOf(parentId);
      if (pNode == null) continue;
      for (final gpId in [parent.parentAId, parent.parentBId]) {
        if (gpId == null) continue;
        final gpNode = nodeOf(gpId);
        if (gpNode != null) {
          edges.add(_EdgeData(from: gpNode, to: pNode, type: _EdgeType.parent));
        }
      }
    }

    // Focal → filhos
    for (final childId in focal.childrenIds) {
      final cNode = nodeOf(childId);
      if (cNode != null) {
        edges.add(_EdgeData(from: focalNode, to: cNode, type: _EdgeType.child));
      }
    }

    // Focal ↔ parceiro
    if (focal.partnerId != null) {
      final partnerNode = nodeOf(focal.partnerId!);
      if (partnerNode != null) {
        edges.add(
            _EdgeData(from: focalNode, to: partnerNode, type: _EdgeType.partner));
      }
    }

    return edges;
  }

  // ── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final layout = _buildLayout();
    final edges = _buildEdges(layout);

    // Bounding box para o canvas
    double minX = 0, maxX = 0, minY = 0, maxY = 0;
    for (final n in layout) {
      if (n.x < minX) minX = n.x;
      if (n.x + _kNodeW > maxX) maxX = n.x + _kNodeW;
      if (n.y < minY) minY = n.y;
      if (n.y + _kNodeH > maxY) maxY = n.y + _kNodeH;
    }
    final canvasW = (maxX - minX + _kNodeW * 2).clamp(400.0, 2000.0);
    final canvasH = (maxY - minY + _kNodeH * 2).clamp(400.0, 1400.0);
    final offsetX = -minX + _kNodeW;
    final offsetY = -minY + _kNodeH;

    return InteractiveViewer(
      transformationController: _transform,
      boundaryMargin: const EdgeInsets.all(200),
      minScale: 0.4,
      maxScale: 2.0,
      child: SizedBox(
        width: canvasW,
        height: canvasH,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Linhas de conexão
            Positioned.fill(
              child: CustomPaint(
                painter: _EdgePainter(
                  edges: edges,
                  offsetX: offsetX,
                  offsetY: offsetY,
                ),
              ),
            ),
            // Nós
            ...layout.map((node) => Positioned(
                  left: node.x + offsetX,
                  top: node.y + offsetY,
                  child: _NodeCard(
                    node: node,
                    isFocal: node.npc.id == widget.focal.id,
                    isHovered: _hoveredId == node.npc.id,
                    onTap: () {
                      setState(() => _hoveredId = node.npc.id);
                      widget.onNodeTap?.call(node.npc);
                    },
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Nó individual
// ─────────────────────────────────────────────────────────────────────────────

class _NodeCard extends StatelessWidget {
  final _NodeData node;
  final bool isFocal;
  final bool isHovered;
  final VoidCallback onTap;

  const _NodeCard({
    required this.node,
    required this.isFocal,
    required this.isHovered,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final npc = node.npc;
    final borderColor = isFocal
        ? AppTheme.cyan
        : node.role == _Role.partner
            ? AppTheme.pink
            : node.role == _Role.ancestor
                ? AppTheme.textDim
                : npc.alive
                    ? AppTheme.border
                    : AppTheme.red.withValues(alpha: 0.4);

    final bgColor = isFocal
        ? AppTheme.cyan.withValues(alpha: 0.10)
        : node.role == _Role.partner
            ? AppTheme.pink.withValues(alpha: 0.06)
            : AppTheme.bgCard;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: _kNodeW,
        height: _kNodeH,
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(
            color: isHovered ? AppTheme.cyan : borderColor,
            width: isFocal ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(4),
          boxShadow: isFocal
              ? [
                  BoxShadow(
                    color: AppTheme.cyan.withValues(alpha: 0.15),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nome
            TerminalText(
              npc.name,
              fontSize: isFocal ? 11 : 10,
              color: npc.alive
                  ? isFocal
                      ? AppTheme.cyan
                      : AppTheme.textPrimary
                  : AppTheme.textDim,
              fontWeight: isFocal ? FontWeight.bold : null,
              maxLines: 1,
            ),
            const SizedBox(height: 2),
            // Geração + idade
            TerminalText(
              'G${npc.generation} · ${npc.age}a',
              fontSize: 8,
              color: AppTheme.textDim,
            ),
            // Status
            Row(children: [
              Container(
                width: 5,
                height: 5,
                margin: const EdgeInsets.only(right: 4, top: 2),
                decoration: BoxDecoration(
                  color: npc.alive ? AppTheme.green : AppTheme.red,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: TerminalText(
                  npc.alive ? npc.profession.label : 'Falecido',
                  fontSize: 8,
                  color: npc.alive ? AppTheme.textSecondary : AppTheme.red,
                  maxLines: 1,
                ),
              ),
            ]),
            // Fama (só se relevante)
            if (npc.fame >= 5 || npc.fame <= -5)
              TerminalText(
                npc.fameLabel,
                fontSize: 8,
                color: npc.fame > 0 ? AppTheme.yellow : AppTheme.orange,
                maxLines: 1,
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Painter das arestas
// ─────────────────────────────────────────────────────────────────────────────

class _EdgePainter extends CustomPainter {
  final List<_EdgeData> edges;
  final double offsetX;
  final double offsetY;

  const _EdgePainter({
    required this.edges,
    required this.offsetX,
    required this.offsetY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final edge in edges) {
      final paint = Paint()
        ..strokeWidth = edge.type == _EdgeType.partner ? 1.0 : 1.5
        ..style = PaintingStyle.stroke
        ..color = switch (edge.type) {
          _EdgeType.partner => AppTheme.pink.withValues(alpha: 0.5),
          _EdgeType.parent => AppTheme.border,
          _EdgeType.child => AppTheme.cyan.withValues(alpha: 0.4),
        };

      if (edge.type == _EdgeType.partner) {
        paint.strokeWidth = 1;
        // linha tracejada para parceiro
        _drawDashed(canvas, paint, edge);
      } else {
        _drawCurved(canvas, paint, edge);
      }
    }
  }

  void _drawCurved(Canvas canvas, Paint paint, _EdgeData edge) {
    final fromCX = edge.from.x + offsetX + _kNodeW / 2;
    final fromCY = edge.from.y + offsetY + _kNodeH;
    final toCX = edge.to.x + offsetX + _kNodeW / 2;
    final toCY = edge.to.y + offsetY;

    final path = Path()
      ..moveTo(fromCX, fromCY)
      ..cubicTo(
        fromCX, fromCY + _kRowGap * 0.5,
        toCX, toCY - _kRowGap * 0.5,
        toCX, toCY,
      );
    canvas.drawPath(path, paint);
  }

  void _drawDashed(Canvas canvas, Paint paint, _EdgeData edge) {
    final x1 = edge.from.x + offsetX + _kNodeW;
    final y1 = edge.from.y + offsetY + _kNodeH / 2;
    final x2 = edge.to.x + offsetX;
    final y2 = edge.to.y + offsetY + _kNodeH / 2;

    const dashLen = 4.0;
    const gapLen = 3.0;
    final total = (x2 - x1).abs();
    double drawn = 0;
    double x = x1;

    while (drawn < total) {
      final end = (x + dashLen).clamp(x1.min(x2), x1.max(x2));
      canvas.drawLine(Offset(x, y1), Offset(end, y2), paint);
      x += dashLen + gapLen;
      drawn += dashLen + gapLen;
    }
  }

  @override
  bool shouldRepaint(_EdgePainter old) =>
      old.edges != edges ||
      old.offsetX != offsetX ||
      old.offsetY != offsetY;
}

// ─────────────────────────────────────────────────────────────────────────────
// Data classes internas
// ─────────────────────────────────────────────────────────────────────────────

const double _kNodeW = 110;
const double _kNodeH = 72;
const double _kRowGap = 52;
const double _kColGap = 18;

enum _Role { focal, partner, parent, ancestor, child }

enum _EdgeType { parent, child, partner }

class _NodeData {
  final Npc npc;
  final double x;
  final double y;
  final _Role role;
  const _NodeData({
    required this.npc,
    required this.x,
    required this.y,
    required this.role,
  });
}

class _EdgeData {
  final _NodeData from;
  final _NodeData to;
  final _EdgeType type;
  const _EdgeData({required this.from, required this.to, required this.type});
}

extension _DoubleExt on double {
  double min(double other) => this < other ? this : other;
  double max(double other) => this > other ? this : other;
}