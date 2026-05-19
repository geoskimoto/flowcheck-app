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
  // Detail-only field (present on /stations/{id}, null on the list endpoint).
  final String? basin;
  // True if the backend has an NWRFC forecast mapping for this station.
  final bool hasForecast;

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
    this.basin,
    this.hasForecast = false,
  });

  factory Station.fromJson(Map<String, dynamic> json) => Station(
        // Null-safe: the production API can return null for state (and
        // historically other fields). A single null must not crash the
        // whole map — degrade gracefully instead.
        stationNumber: (json['station_number'] as String?) ?? '',
        name: (json['name'] as String?) ?? 'Unknown station',
        latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
        state: (json['state'] as String?) ?? '',
        isActive: json['is_active'] as bool? ?? true,
        currentDischargeCfs: (json['current_discharge_cfs'] as num?)?.toDouble(),
        percentileRank: (json['percentile_rank'] as num?)?.toDouble(),
        conditionBand: json['condition_band'] as String?,
        conditionLabel: json['condition_label'] as String? ?? 'Unknown',
        basin: json['basin'] as String?,
        hasForecast: json['has_forecast'] as bool? ?? false,
      );

  ConditionLevel get conditionLevel {
    final pct = percentileRank;
    if (pct == null) return ConditionLevel.unknown;
    if (pct < 25) return ConditionLevel.low;
    if (pct < 50) return ConditionLevel.belowNormal;
    if (pct < 75) return ConditionLevel.normal;
    if (pct < 95) return ConditionLevel.elevated;
    return ConditionLevel.flood;
  }
}

// Ordered low→high flow. Colors are assigned cool = high water
// (see AppTheme.conditionColor).
enum ConditionLevel { unknown, low, belowNormal, normal, elevated, flood }
