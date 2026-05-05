class WaterYearStat {
  final int dayOfWy;
  final double q10;
  final double q25;
  final double q50;
  final double q75;
  final double q90;
  final double mean;

  const WaterYearStat({
    required this.dayOfWy,
    required this.q10,
    required this.q25,
    required this.q50,
    required this.q75,
    required this.q90,
    required this.mean,
  });

  factory WaterYearStat.fromJson(Map<String, dynamic> json) => WaterYearStat(
        dayOfWy: json['day_of_wy'] as int,
        q10: (json['q10'] as num).toDouble(),
        q25: (json['q25'] as num).toDouble(),
        q50: (json['q50'] as num).toDouble(),
        q75: (json['q75'] as num).toDouble(),
        q90: (json['q90'] as num).toDouble(),
        mean: (json['mean'] as num).toDouble(),
      );
}
