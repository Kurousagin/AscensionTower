// lib/widgets/ambient_appbar.dart
//
// AmbientAppBar — AppBar que reflete o AmbientState atual
// com cor de destaque e indicador visual sutil do estado.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/ambient_state.dart';
import 'theme.dart';

class AmbientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const AmbientAppBar({
    super.key,
    required this.title,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final gp = context.watch<GameProvider>();
    final state = gp.isLoading ? AmbientState.normal : resolveAmbientState(gp);
    final accent = state.accentColor;

    return AnimatedContainer(
      duration: const Duration(seconds: 2),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: AppTheme.bg,
        border: Border(
          bottom: BorderSide(
            color: accent.withOpacity(0.6),
            width: 1,
          ),
        ),
      ),
      child: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            // Indicador do estado (só aparece em estados não-normais)
            if (state != AmbientState.normal) ...[
              AnimatedContainer(
                duration: const Duration(seconds: 1),
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accent.withOpacity(0.6),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ],
            Text(
              title,
              style: TextStyle(
                fontFamily: 'FiraCode',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: accent,
                letterSpacing: 2,
              ),
            ),
            const Spacer(),
            // Info do jogo
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                border: Border.all(
                  color: accent.withOpacity(0.4),
                ),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                '${gp.timeDisplay} | Andar ${gp.state.highestFloorCleared} | ${gp.population} hab.',
                style: TextStyle(
                  fontFamily: 'FiraCode',
                  fontSize: 8,
                  color: accent.withOpacity(0.8),
                ),
              ),
            ),
          ],
        ),
        actions: actions,
      ),
    );
  }
}