class Station {
  final String stationNumber;
  final String name;
  final double latitude;
  final double longitude;
  final String state;
  final bool isActive;
  final double? currentDischargeCfs;
  final double? percentileRank;
  final String? conditionBand;
  final String conditionLabel;

  const Station({
    required this.stationNumber,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.state,
    required this.isActive,
    this.currentDischargeCfs,
    this.percentileRank,
    this.conditionBand,
    this.conditionLabel = 'Unknown',
  });

  factory Station.fromJson(Map<String, dynamic> json) => Station(
        stationNumber: json['station_number'] as String,
        name: json['name'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        state: json['state'] as String,
        isActive: json['is_active'] as bool? ?? true,
        currentDischargeCfs: (json['current_discharge_cfs'] as num?)?.toDouble(),
        percentileRank: (json['percentile_rank'] as num?)?.toDouble(),
        conditionBand: json['condition_band'] as String?,
        conditionLabel: json['condition_label'] as String? ?? 'Unknown',
      );

  ConditionLevel get conditionLevel {
    final pct = percentileRank;
    if (pct == null) return ConditionLevel.unknown;
    if (pct < 25) return ConditionLevel.low;
    if (pct < 75) return ConditionLevel.normal;
    if (pct < 95) return ConditionLevel.elevated;
    return ConditionLevel.flood;
  }
}

enum ConditionLevel { unknown, low, normal, elevated, flood }
