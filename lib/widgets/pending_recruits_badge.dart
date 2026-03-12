// lib/widgets/pending_recruits_badge.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tower_ascension/models/citadel.dart';
import 'package:tower_ascension/models/floor_inhabitant.dart';
import 'package:tower_ascension/providers/game_provider.dart';
import 'package:tower_ascension/services/game_engine.dart';

class PendingRecruitsBadge extends StatelessWidget {
  final int count;
  final Widget child;
  const PendingRecruitsBadge({
    super.key,
    required this.count,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return child;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(top: -4, right: -4, child: _BadgeDot(count: count)),
      ],
    );
  }
}

class _BadgeDot extends StatefulWidget {
  final int count;
  const _BadgeDot({required this.count});

  @override
  State<_BadgeDot> createState() => _BadgeDotState();
}

class _BadgeDotState extends State<_BadgeDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);
  late final Animation<double> _scale = Tween<double>(
    begin: 1.0,
    end: 1.18,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: const Color(0xFF66DD88),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF0F0F14), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF66DD88).withOpacity(0.5),
              blurRadius: 6,
            ),
          ],
        ),
        child: Center(
          child: Text(
            widget.count > 9 ? '9+' : '${widget.count}',
            style: const TextStyle(
              color: Color(0xFF0F0F14),
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class PendingRecruitsBanner extends StatefulWidget {
  final List<FloorInhabitant> recruits;
  final VoidCallback onTap;
  final bool hasRefuge;
  const PendingRecruitsBanner({
    super.key,
    required this.recruits,
    required this.onTap,
    required this.hasRefuge,
  });

  @override
  State<PendingRecruitsBanner> createState() => _PendingRecruitsBannerState();
}

class _PendingRecruitsBannerState extends State<PendingRecruitsBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  )..forward();
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, -1),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.recruits.isEmpty) return const SizedBox.shrink();
    final count = widget.recruits.length;
    final names = widget.recruits.take(2).map((r) => r.name).join(', ');
    final moreText = count > 2 ? ' +${count - 2}' : '';
    return SlideTransition(
      position: _slide,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1F15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF66DD88).withOpacity(0.4)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF66DD88).withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              _PulsingIcon(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.hasRefuge
                          ? '$count survivor(s) aguardando recrutamento'
                          : '$count survivor(s) encontrado(s)',
                      style: const TextStyle(
                        color: Color(0xFF66DD88),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      widget.hasRefuge
                          ? '$names$moreText — toque para recrutar'
                          : '$names$moreText — construa o Abrigo de Viajantes',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF66DD88),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PulsingIcon extends StatefulWidget {
  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);
  late final Animation<double> _opacity = Tween<double>(
    begin: 0.5,
    end: 1.0,
  ).animate(_c);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF66DD88).withOpacity(0.15),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF66DD88).withOpacity(0.4)),
        ),
        child: const Icon(
          Icons.person_add_outlined,
          size: 18,
          color: Color(0xFF66DD88),
        ),
      ),
    );
  }
}

class RecruitListSheet extends StatefulWidget {
  final GameEngine engine;
  const RecruitListSheet({super.key, required this.engine});

  @override
  State<RecruitListSheet> createState() => _RecruitListSheetState();
}

class _RecruitListSheetState extends State<RecruitListSheet> {
  @override
  Widget build(BuildContext context) {
    final gp = context.read<GameProvider>();
    // Snapshot da lista para evitar modificações durante o build
    final recruits = List<FloorInhabitant>.from(widget.engine.pendingRecruits);
    final hasRefuge = widget.engine.citadel.hasBuilding(
      BuildingType.wayfareresRefuge,
    );
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F14),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: Color(0xFF66DD88), width: 1.5)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              const Icon(
                Icons.people_outline,
                color: Color(0xFF66DD88),
                size: 20,
              ),
              const SizedBox(width: 10),
              const Text(
                'SURVIVORS AGUARDANDO',
                style: TextStyle(
                  color: Color(0xFF66DD88),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF66DD88).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${recruits.length}',
                  style: const TextStyle(
                    color: Color(0xFF66DD88),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (!hasRefuge) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.construction, size: 14, color: Colors.amber),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Construa o Abrigo de Viajantes para confirmar recrutamentos.',
                      style: TextStyle(color: Colors.amber, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (recruits.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Nenhum survivor aguardando.',
                  style: TextStyle(
                    color: Colors.white30,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          else
            ...recruits.map(
              (r) => _RecruitRow(
                recruit: r,
                hasRefuge: hasRefuge,
                onRecruit: () {
                  final msg = gp.confirmRecruitSurvivor(r.id);
                  final isError =
                      msg.contains('não encontrado') || msg.contains('Requer');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(msg),
                      backgroundColor: isError
                          ? Colors.red.shade900
                          : const Color(0xFF1A2A1A),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                  if (!isError) {
                    if (gp.pendingRecruits.isEmpty) {
                      Navigator.pop(context);
                    } else {
                      setState(() {});
                    }
                  }
                },
                onReject: () {
                  gp.rejectRecruit(r.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Survivor dispensado.'),
                      backgroundColor: Color(0xFF2A1A1A),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 3),
                    ),
                  );
                  if (gp.pendingRecruits.isEmpty) {
                    Navigator.pop(context);
                  } else {
                    setState(() {});
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _RecruitRow extends StatelessWidget {
  final FloorInhabitant recruit;
  final bool hasRefuge;
  final VoidCallback onRecruit;
  final VoidCallback? onReject;
  const _RecruitRow({
    required this.recruit,
    required this.hasRefuge,
    required this.onRecruit,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final stats = recruit.survivorStats;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF141420),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF66DD88).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF66DD88).withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF66DD88).withOpacity(0.3),
              ),
            ),
            child: const Icon(
              Icons.person_outline,
              color: Color(0xFF66DD88),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recruit.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (stats != null)
                  Text(
                    'POW ${stats.combatPower.toStringAsFixed(1)} · INT ${stats.intelligence.toStringAsFixed(1)} · RES ${stats.endurance.toStringAsFixed(1)}',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 10.5,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (hasRefuge) ...[
            TextButton(
              onPressed: onRecruit,
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF66DD88).withOpacity(0.15),
                foregroundColor: const Color(0xFF66DD88),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: const Color(0xFF66DD88).withOpacity(0.4),
                  ),
                ),
                minimumSize: Size.zero,
              ),
              child: const Text(
                'Recrutar',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 6),
            TextButton(
              onPressed: onReject,
              child: const Text(
                'Dispensar',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ] else
            const Icon(Icons.lock_outline, color: Colors.amber, size: 18),
        ],
      ),
    );
  }
}
