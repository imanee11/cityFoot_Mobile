import 'package:flutter/material.dart';

// ── Static constants (same in both modes) ────────────────────────────────────
const Color primary        = Color(0xFFEC6313);
const Color tertiary       = Color(0xFFEE8B60);
const Color errorRed       = Color(0xFFEF4343);
const Color successGreen   = Color(0xFF4CAF50);
const Color authBackground = Color(0xFF111B44);

// Light-mode fallbacks (used outside widget tree, e.g. MaterialApp theme seed)
const Color primaryBackground    = Color(0xFFEEF1F5);
const Color secondaryBackground  = Color(0xFFFFFFFF);
const Color primaryText          = Color(0xFF14181B);
const Color secondaryText        = Color(0xFF676C7E);
const Color borderInput          = Color(0xFFD3D5DE);
const Color circleColor          = Color(0xFFE7E8EF);
const Color alternate            = Color(0xFFE7E8EF);
const Color secondary            = Color(0xFF1B1F32);

// ── ThemeExtension — use WColors.of(context) inside widget trees ─────────────
class WColors extends ThemeExtension<WColors> {
  const WColors({
    required this.primaryBackground,
    required this.secondaryBackground,
    required this.primaryText,
    required this.secondaryText,
    required this.borderInput,
    required this.circleColor,
    required this.alternate,
    required this.secondary,
    required this.cardBorder,
  });

  final Color primaryBackground;
  final Color secondaryBackground;
  final Color primaryText;
  final Color secondaryText;
  final Color borderInput;
  final Color circleColor;
  final Color alternate;
  final Color secondary;
  final Color cardBorder;

  // ── Light palette ─────────────────────────────────────────────────────────
  static const light = WColors(
    primaryBackground:   Color(0xFFEEF1F5),
    secondaryBackground: Color(0xFFFFFFFF),
    primaryText:         Color(0xFF14181B),
    secondaryText:       Color(0xFF676C7E),
    borderInput:         Color(0xFFD3D5DE),
    circleColor:         Color(0xFFE7E8EF),
    alternate:           Color(0xFFE7E8EF),
    secondary:           Color(0xFF1B1F32),
    cardBorder:          Color(0x00000000), // transparent in light
  );

  // ── Dark palette (from FlutterFlow dark theme) ────────────────────────────
  static const dark = WColors(
    primaryBackground:   Color(0xFF0D173F),
    secondaryBackground: Color(0xFF111B44),
    primaryText:         Color(0xFFFFFFFF),
    secondaryText:       Color(0xFF94A3B8),
    borderInput:         Color(0xFF323B5D),
    circleColor:         Color(0xFF152461),
    alternate:           Color(0xFF152461),
    secondary:           Color(0xFFF8FAFC),
    cardBorder:          Color(0xFF323B5D),
  );

  static WColors of(BuildContext context) =>
      Theme.of(context).extension<WColors>()!;

  @override
  WColors copyWith({
    Color? primaryBackground,
    Color? secondaryBackground,
    Color? primaryText,
    Color? secondaryText,
    Color? borderInput,
    Color? circleColor,
    Color? alternate,
    Color? secondary,
    Color? cardBorder,
  }) =>
      WColors(
        primaryBackground:   primaryBackground   ?? this.primaryBackground,
        secondaryBackground: secondaryBackground ?? this.secondaryBackground,
        primaryText:         primaryText         ?? this.primaryText,
        secondaryText:       secondaryText       ?? this.secondaryText,
        borderInput:         borderInput         ?? this.borderInput,
        circleColor:         circleColor         ?? this.circleColor,
        alternate:           alternate           ?? this.alternate,
        secondary:           secondary           ?? this.secondary,
        cardBorder:          cardBorder          ?? this.cardBorder,
      );

  @override
  WColors lerp(WColors? other, double t) {
    if (other == null) return this;
    return WColors(
      primaryBackground:   Color.lerp(primaryBackground,   other.primaryBackground,   t)!,
      secondaryBackground: Color.lerp(secondaryBackground, other.secondaryBackground, t)!,
      primaryText:         Color.lerp(primaryText,         other.primaryText,         t)!,
      secondaryText:       Color.lerp(secondaryText,       other.secondaryText,       t)!,
      borderInput:         Color.lerp(borderInput,         other.borderInput,         t)!,
      circleColor:         Color.lerp(circleColor,         other.circleColor,         t)!,
      alternate:           Color.lerp(alternate,           other.alternate,           t)!,
      secondary:           Color.lerp(secondary,           other.secondary,           t)!,
      cardBorder:          Color.lerp(cardBorder,          other.cardBorder,          t)!,
    );
  }
}
