import 'package:flutter/material.dart';

/// Shared SecurIoT brand palette — the 7-token dark system from DESIGN.md,
/// shared verbatim with the Landing Page and Web App surfaces.
class AppColors {
  const AppColors._();

  static const Color marca = Color(0xFF1FD3C4);
  static const Color senal = Color(0xFF6C7CE8);
  static const Color verificado = Color(0xFF22DD66);
  static const Color alerta = Color(0xFFFF5C6C);
  static const Color noche = Color(0xFF0B0E14);
  static const Color texto = Color(0xFFEEF0F4);
  static const Color textoMute = Color(0xFF8B93A3);

  /// Card/panel surface one step lighter than [noche] — visual separation
  /// without a floating white card (DESIGN.md "Cards").
  static const Color surfaceCard = Color(0xFF141B26);

  // Status extension (DESIGN.md "Color"): offline is neutral, never colored;
  // severity is a single red differentiated by icon + label, never a shade.
  static const Color statusOnline = verificado;
  static const Color statusOffline = textoMute;
  static const Color severityLow = alerta;
  static const Color severityMedium = alerta;
  static const Color severityHigh = alerta;
  static const Color destructive = alerta;
}
