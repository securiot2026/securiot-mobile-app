import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_theme.dart';

/// Summary tile (pattern from Astryx "Service Monitoring Dashboard"):
/// icon + label + big value, with an optional sparkline. Color is never the
/// only cue: the icon and the text label always carry the meaning. Read as a
/// single semantics node, "label: value".
class StatusTile extends StatelessWidget {
  const StatusTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color = AppColors.marca,
    this.trend,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  /// Optional recent values, drawn as a sparkline. Needs at least 2 points.
  final List<double>? trend;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '$label: $value',
      child: ExcludeSemantics(
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppSpacing.minTouchTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 18, color: color),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          label,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    value,
                    style: AppTheme.dataText(
                      color: AppColors.texto,
                      weight: FontWeight.w700,
                    ).copyWith(fontSize: 24),
                  ),
                  if (trend != null && trend!.length >= 2) ...[
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      height: 24,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: SparklinePainter(trend!, color),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SparklinePainter extends CustomPainter {
  SparklinePainter(this.values, this.color);

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final range = (max - min) == 0 ? 1.0 : max - min;
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final y = size.height - (values[i] - min) / range * size.height;
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(SparklinePainter old) =>
      old.values != values || old.color != color;
}
