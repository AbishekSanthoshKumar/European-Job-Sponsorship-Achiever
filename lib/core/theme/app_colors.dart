import 'package:flutter/material.dart';

/// Dark-first palette tuned for a "mission control" feel.
/// Reference points: Linear, Raycast, Vercel dashboard.
class AppColors {
  const AppColors._();

  // ---- surfaces (dark) ----
  static const bg = Color(0xFF08090C);
  static const surface = Color(0xFF0E1014);
  static const surfaceAlt = Color(0xFF14171D);
  static const surfaceHigh = Color(0xFF1B1F27);
  static const border = Color(0xFF23272F);
  static const borderStrong = Color(0xFF2E333D);

  // ---- surfaces (light) ----
  static const bgLight = Color(0xFFF7F8FA);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surfaceAltLight = Color(0xFFF1F3F6);
  static const surfaceHighLight = Color(0xFFE8EBF0);
  static const borderLight = Color(0xFFDFE3E9);
  static const borderStrongLight = Color(0xFFC8CEd8);

  // ---- text (dark) ----
  static const textPrimary = Color(0xFFF2F4F8);
  static const textSecondary = Color(0xFF9BA3B2);
  static const textTertiary = Color(0xFF636B7A);

  // ---- text (light) ----
  static const textPrimaryLight = Color(0xFF0E1014);
  static const textSecondaryLight = Color(0xFF525A68);
  static const textTertiaryLight = Color(0xFF858D9A);

  // ---- brand ----
  /// European blue, brightened for dark surfaces.
  static const primary = Color(0xFF4C7DFF);
  static const primaryDim = Color(0xFF2E5BD9);
  static const primarySoft = Color(0x1A4C7DFF);

  /// EU-flag gold, used for streaks / highlights.
  static const accent = Color(0xFFFFC940);
  static const accentSoft = Color(0x1AFFC940);

  // ---- semantic ----
  static const success = Color(0xFF3ECF8E);
  static const successSoft = Color(0x1A3ECF8E);
  static const warning = Color(0xFFFFA53D);
  static const warningSoft = Color(0x1AFFA53D);
  static const danger = Color(0xFFFF5C5C);
  static const dangerSoft = Color(0x1AFF5C5C);
  static const info = Color(0xFF52B9FF);
  static const infoSoft = Color(0x1A52B9FF);
  static const purple = Color(0xFFA78BFA);
  static const purpleSoft = Color(0x1AA78BFA);

  /// Categorical series for charts — distinguishable in both themes.
  static const series = <Color>[
    Color(0xFF4C7DFF),
    Color(0xFF3ECF8E),
    Color(0xFFFFC940),
    Color(0xFFA78BFA),
    Color(0xFFFF8A5C),
    Color(0xFF52B9FF),
    Color(0xFFF472B6),
    Color(0xFF5EEAD4),
    Color(0xFFFBBF24),
    Color(0xFF94A3B8),
  ];

  /// Consistency-heatmap ramp, index 0 = no activity -> 4 = highest intensity.
  static const heat = <Color>[
    Color(0xFF161A21),
    Color(0xFF1B4D3A),
    Color(0xFF24785A),
    Color(0xFF31A87A),
    Color(0xFF3ECF8E),
  ];

  static const heatLight = <Color>[
    Color(0xFFE9ECF1),
    Color(0xFFBDE9D4),
    Color(0xFF86D9B4),
    Color(0xFF56C695),
    Color(0xFF2FA877),
  ];
}
