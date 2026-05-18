class ForecastPoint {
  final DateTime date;
  final double value; // discharge in CFS

  const ForecastPoint({required this.date, required this.value});

  factory ForecastPoint.fromJson(Map<String, dynamic> json) => ForecastPoint(
        date: DateTime.parse(json['date'] as String).toUtc(),
        value: (json['value'] as num).toDouble(),
      );
}

class Forecast {
  final String stationNumber;
  final String nwrfcCode;
  final String source;
  final String runDate;
  final List<ForecastPoint> points;

  const Forecast({
    required this.stationNumber,
    required this.nwrfcCode,
    required this.source,
    required this.runDate,
    required this.points,
  });

  factory Forecast.fromJson(Map<String, dynamic> json) => Forecast(
        stationNumber: json['station_number'] as String,
        nwrfcCode: json['nwrfc_code'] as String,
        source: json['source'] as String,
        runDate: json['run_date'] as String,
        points: (json['points'] as List<dynamic>)
            .map((e) => ForecastPoint.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
