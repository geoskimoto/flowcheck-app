import 'package:flutter/material.dart';
import 'package:streamcast/core/models/station.dart';

class AppTheme {
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1976D2),
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          type: BottomNavigationBarType.fixed,
        ),
      );

  // Colorblind-safe condition palette (Okabe-Ito inspired)
  // Cool = high water, warm = low water (flipped per product decision).
  static Color conditionColor(ConditionLevel level) => switch (level) {
        ConditionLevel.unknown => const Color(0xFF9E9E9E),     // grey
        ConditionLevel.low => const Color(0xFFD55E00),         // vermilion (low/drought)
        ConditionLevel.belowNormal => const Color(0xFFE69F00), // amber
        ConditionLevel.normal => const Color(0xFF009E73),      // teal green
        ConditionLevel.elevated => const Color(0xFF56B4E9),    // sky blue
        ConditionLevel.flood => const Color(0xFF0072B2),       // deep blue (high/flood)
      };

  static Color conditionColorFromBand(String? band) => switch (band) {
        'p0_4' || 'p5_10' || 'p11_25' => conditionColor(ConditionLevel.low),
        'p26_50' => conditionColor(ConditionLevel.belowNormal),
        'p51_75' => conditionColor(ConditionLevel.normal),
        'p76_85' || 'p86_90' || 'p91_95' || 'p76_100' =>
          conditionColor(ConditionLevel.elevated),
        'p96_98' || 'p99_100' => conditionColor(ConditionLevel.flood),
        _ => conditionColor(ConditionLevel.unknown),
      };

  // Chart band colors with opacity for filled areas
  static const Color chartQ10Q25Fill = Color(0x3356B4E9);
  static const Color chartQ25Q75Fill = Color(0x4409E73A); // fixed below
  static const Color chartQ75Q90Fill = Color(0x33E69F00);
  static const Color chartCurrentYear = Color(0xFFD55E00);
  static const Color chartMedian = Color(0xFF009E73);
}
