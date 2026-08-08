import 'package:flutter/material.dart';

/// Guild Modernist Tonal Layers & Elevation System
class AppShadows {
  // Level 1: Flat background, no shadow
  static List<BoxShadow> get level1 => [];

  // Level 2: Surface cards & inputs (2dp shadow — rgba(0,0,0,0.06) + rgba(0,0,0,0.1))
  static List<BoxShadow> get level2 => const [
        BoxShadow(
          color: Color(0x0F000000), // 6% alpha
          offset: Offset(0, 1),
          blurRadius: 2,
        ),
        BoxShadow(
          color: Color(0x1A000000), // 10% alpha
          offset: Offset(0, 1),
          blurRadius: 3,
        ),
      ];

  // Level 3: Modals, bottom sheets, focus dialogs (8dp shadow)
  static List<BoxShadow> get level3 => const [
        BoxShadow(
          color: Color(0x14000000), // 8% alpha
          offset: Offset(0, 4),
          blurRadius: 12,
        ),
        BoxShadow(
          color: Color(0x1F000000), // 12% alpha
          offset: Offset(0, 2),
          blurRadius: 6,
        ),
      ];

  // Backward compatibility mappings to Guild Modernist tiers
  static List<BoxShadow> get shadowSm => level2;
  static List<BoxShadow> get shadowMd => level2;
  static List<BoxShadow> get shadowLg => level3;
  static List<BoxShadow> get shadowXl => level3;
}
