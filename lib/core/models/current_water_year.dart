/// One day of the in-progress water year's observed discharge.
class CurrentWyPoint {
  final int dayOfWy; // 1 = Oct 1
  final double discharge; // CFS

  const CurrentWyPoint({required this.dayOfWy, required this.discharge});

  factory CurrentWyPoint.fromJson(Map<String, dynamic> json) => CurrentWyPoint(
        dayOfWy: (json['day_of_wy'] as num).toInt(),
        discharge: (json['discharge'] as num).toDouble(),
      );
}
