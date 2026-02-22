import 'package:flutter/material.dart';
import 'theme.dart';

class TerminalText extends StatelessWidget {
  final String text;
  final Color? color;
  final double? fontSize;
  final FontWeight? fontWeight;
  final TextAlign? textAlign;
  final int? maxLines;

  const TerminalText(this.text, {super.key, this.color, this.fontSize, this.fontWeight, this.textAlign, this.maxLines});

  @override
  Widget build(BuildContext context) {
    return Text(text,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: maxLines != null ? TextOverflow.ellipsis : null,
        style: TextStyle(
          fontFamily: 'FiraCode',
          fontSize: fontSize ?? 11,
          color: color ?? AppTheme.textPrimary,
          fontWeight: fontWeight,
          height: 1.5,
        ));
  }
}

class CyanDivider extends StatelessWidget {
  final String? label;
  const CyanDivider({super.key, this.label});

  @override
  Widget build(BuildContext context) {
    if (label == null) {
      return Container(height: 1, color: AppTheme.border, margin: const EdgeInsets.symmetric(vertical: 8));
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Expanded(child: Container(height: 1, color: AppTheme.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: TerminalText('[ $label ]', color: AppTheme.cyan, fontSize: 10, fontWeight: FontWeight.bold),
        ),
        Expanded(child: Container(height: 1, color: AppTheme.border)),
      ]),
    );
  }
}

class StatBar extends StatelessWidget {
  final String label;
  final double value;
  final double maxValue;
  final Color? color;
  final bool showValue;

  const StatBar({super.key, required this.label, required this.value, this.maxValue = 10, this.color, this.showValue = true});

  @override
  Widget build(BuildContext context) {
    final pct = (value / maxValue).clamp(0.0, 1.0);
    final barColor = color ?? (pct > 0.6 ? AppTheme.cyan : pct > 0.3 ? AppTheme.yellow : AppTheme.red);
    final barWidth = 12;
    final filled = (pct * barWidth).round();
    final empty = barWidth - filled;
    final bar = '${'█' * filled}${'░' * empty}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(children: [
        SizedBox(width: 36, child: TerminalText(label, fontSize: 9, color: AppTheme.textSecondary)),
        TerminalText(bar, fontSize: 9, color: barColor),
        if (showValue)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: TerminalText(value.toStringAsFixed(1), fontSize: 9, color: barColor),
          ),
      ]),
    );
  }
}

class ResourceBar extends StatelessWidget {
  final String label;
  final double value;
  final IconData? icon;
  final Color? color;

  const ResourceBar({super.key, required this.label, required this.value, this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      if (icon != null) Icon(icon, size: 12, color: color ?? AppTheme.textSecondary),
      if (icon != null) const SizedBox(width: 4),
      TerminalText('$label:', fontSize: 9, color: AppTheme.textSecondary),
      const SizedBox(width: 4),
      TerminalText(value.toStringAsFixed(0), fontSize: 10, color: color ?? AppTheme.cyan, fontWeight: FontWeight.bold),
    ]);
  }
}

class TerminalCard extends StatelessWidget {
  final String? title;
  final Widget child;
  final Color? borderColor;
  final EdgeInsets? padding;
  final VoidCallback? onTap;

  const TerminalCard({super.key, this.title, required this.child, this.borderColor, this.padding, this.onTap});

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        border: Border.all(color: borderColor ?? AppTheme.border, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: padding ?? const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null) ...[
            TerminalText('// $title', color: AppTheme.cyan, fontSize: 10, fontWeight: FontWeight.bold),
            const SizedBox(height: 8),
          ],
          child,
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: card);
    }
    return card;
  }
}

class TerminalButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final bool expanded;
  final IconData? icon;

  const TerminalButton({super.key, required this.label, this.onPressed, this.color, this.expanded = false, this.icon});

  @override
  Widget build(BuildContext context) {
    final btn = OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: color ?? AppTheme.cyan,
        side: BorderSide(color: (color ?? AppTheme.cyan).withValues(alpha: onPressed != null ? 1.0 : 0.3)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      child: Row(
        mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[Icon(icon, size: 14), const SizedBox(width: 6)],
          Text('[ $label ]',
              style: TextStyle(
                fontFamily: 'FiraCode',
                fontSize: 10,
                letterSpacing: 1,
                color: (color ?? AppTheme.cyan).withValues(alpha: onPressed != null ? 1.0 : 0.3),
              )),
        ],
      ),
    );
    return expanded ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}

class TerminalEventTile extends StatelessWidget {
  final String tag;
  final String title;
  final String? description;
  final Color tagColor;
  final bool isMajor;

  const TerminalEventTile({
    super.key,
    required this.tag,
    required this.title,
    this.description,
    this.tagColor = AppTheme.textSecondary,
    this.isMajor = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                border: Border.all(color: tagColor.withValues(alpha: 0.5)),
                borderRadius: BorderRadius.circular(2),
              ),
              child: TerminalText(tag, fontSize: 8, color: tagColor, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: TerminalText(
                title,
                fontSize: isMajor ? 11 : 10,
                color: isMajor ? AppTheme.textPrimary : AppTheme.textSecondary,
                fontWeight: isMajor ? FontWeight.bold : null,
                maxLines: 1,
              ),
            ),
          ]),
          if (description != null)
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 2),
              child: TerminalText(description!, fontSize: 9, color: AppTheme.textDim),
            ),
        ],
      ),
    );
  }
}

class ScanlineOverlay extends StatelessWidget {
  final Widget child;
  const ScanlineOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      child,
      Positioned.fill(
        child: IgnorePointer(
          child: CustomPaint(painter: _ScanlinePainter()),
        ),
      ),
    ]);
  }
}

class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.03)
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
