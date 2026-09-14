import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Circular progress indicator with a value in the middle.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 140,
    this.strokeWidth = 10,
    this.color,
    this.centerTop,
    this.centerBottom,
    this.trackColor,
  });

  /// 0..1
  final double progress;
  final double size;
  final double strokeWidth;
  final Color? color;
  final Color? trackColor;
  final String? centerTop;
  final String? centerBottom;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = color ?? theme.colorScheme.primary;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _RingPainter(
              progress: progress.clamp(0.0, 1.0),
              color: accent,
              trackColor:
                  trackColor ?? theme.colorScheme.surfaceContainerHigh,
              strokeWidth: strokeWidth,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (centerTop != null)
                Text(
                  centerTop!,
                  style: AppTheme.mono(
                    size: size * 0.20,
                    weight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: -1,
                  ),
                ),
              if (centerBottom != null) ...[
                const SizedBox(height: 2),
                Text(
                  centerBottom!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 0.8,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.width - strokeWidth) / 2;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = trackColor;

    final fill = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = color;

    canvas.drawCircle(center, radius, track);

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        fill,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.trackColor != trackColor ||
      old.strokeWidth != strokeWidth;
}

/// Multi-segment ring where each category contributes an arc.
class SegmentedRing extends StatelessWidget {
  const SegmentedRing({
    super.key,
    required this.segments,
    this.size = 140,
    this.strokeWidth = 10,
    this.centerTop,
    this.centerBottom,
  });

  final List<RingSegment> segments;
  final double size;
  final double strokeWidth;
  final String? centerTop;
  final String? centerBottom;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _SegmentPainter(
              segments: segments,
              trackColor: theme.colorScheme.surfaceContainerHigh,
              strokeWidth: strokeWidth,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (centerTop != null)
                Text(
                  centerTop!,
                  style: AppTheme.mono(
                    size: size * 0.19,
                    weight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: -1,
                  ),
                ),
              if (centerBottom != null)
                Text(
                  centerBottom!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class RingSegment {
  const RingSegment({
    required this.weight,
    required this.progress,
    required this.color,
  });

  /// Relative share of the circle.
  final double weight;

  /// 0..1 completion within this segment.
  final double progress;
  final Color color;
}

class _SegmentPainter extends CustomPainter {
  const _SegmentPainter({
    required this.segments,
    required this.trackColor,
    required this.strokeWidth,
  });

  final List<RingSegment> segments;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = trackColor,
    );

    final totalWeight =
        segments.fold<double>(0, (sum, s) => sum + s.weight);
    if (totalWeight <= 0) return;

    // small gap between segments so they read as distinct
    const gap = 0.03;
    var start = -math.pi / 2;

    for (final s in segments) {
      final share = s.weight / totalWeight;
      final sweep = 2 * math.pi * share - gap;
      if (sweep <= 0) continue;

      final filled = sweep * s.progress.clamp(0.0, 1.0);
      if (filled > 0) {
        canvas.drawArc(
          rect,
          start,
          filled,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth
            ..strokeCap = StrokeCap.round
            ..color = s.color,
        );
      }
      start += sweep + gap;
    }
  }

  @override
  bool shouldRepaint(_SegmentPainter old) => true;
}
