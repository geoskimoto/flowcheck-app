import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/models/current_water_year.dart';
import '../../../core/models/forecast.dart';
import '../../../core/models/water_year_stat.dart';

class WaterYearChart extends StatelessWidget {
  final List<dynamic> statsJson;
  final String stationName;
  final double? currentPercentile;
  final Forecast? forecast;
  final List<CurrentWyPoint> currentSeries;

  const WaterYearChart({
    super.key,
    required this.statsJson,
    required this.stationName,
    this.currentPercentile,
    this.forecast,
    this.currentSeries = const [],
  });

  List<FlSpot> _currentSpots() {
    if (currentSeries.isEmpty) return const [];
    final pts = [...currentSeries]..sort((a, b) => a.dayOfWy.compareTo(b.dayOfWy));
    return pts.map((p) => FlSpot(p.dayOfWy.toDouble(), p.discharge)).toList();
  }

  // Day-of-water-year (Oct 1 = 1), mirroring the backend's
  // water_year_service so forecast points align with the stats x-axis.
  static int _dayOfWy(DateTime d) {
    final wyStartYear = d.month >= 10 ? d.year : d.year - 1;
    final wyStart = DateTime.utc(wyStartYear, 10, 1);
    return d.toUtc().difference(wyStart).inDays + 1;
  }

  // Forecast points -> spots, truncated at a water-year wrap (a forecast
  // spanning Sep 30 -> Oct 1 would otherwise jump backwards on the x-axis).
  List<FlSpot> _forecastSpots() {
    final f = forecast;
    if (f == null || f.points.isEmpty) return const [];
    final spots = <FlSpot>[];
    int? prev;
    for (final p in f.points) {
      final x = _dayOfWy(p.date);
      if (prev != null && x < prev) break;
      prev = x;
      spots.add(FlSpot(x.toDouble(), p.value));
    }
    return spots;
  }

  @override
  Widget build(BuildContext context) {
    final stats = statsJson
        .map((e) => WaterYearStat.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.dayOfWy.compareTo(b.dayOfWy));

    if (stats.isEmpty) {
      return const Center(child: Text('No historical data available.'));
    }

    final forecastSpots = _forecastSpots();
    final currentSpots = _currentSpots();
    final peak = [
      stats.map((s) => s.q90).reduce(max),
      if (forecastSpots.isNotEmpty)
        forecastSpots.map((s) => s.y).reduce(max),
      if (currentSpots.isNotEmpty) currentSpots.map((s) => s.y).reduce(max),
    ].reduce(max);
    final maxVal = peak * 1.1;
    final minVal = 0.0;

    // Build spot lists for each band
    final q10Spots = _toSpots(stats, (s) => s.q10);
    final q25Spots = _toSpots(stats, (s) => s.q25);
    final q50Spots = _toSpots(stats, (s) => s.q50);
    final q75Spots = _toSpots(stats, (s) => s.q75);
    final q90Spots = _toSpots(stats, (s) => s.q90);

    // Month labels for x-axis (day of water year → month)
    final monthLabels = _wyMonthLabels();

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      child: Column(
        children: [
          Expanded(
            child: LineChart(
              LineChartData(
                minX: 1,
                maxX: stats.last.dayOfWy.toDouble(),
                minY: minVal,
                maxY: maxVal,
                clipData: const FlClipData.all(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: maxVal / 5,
                  getDrawingHorizontalLine: (_) => FlLine(color: Colors.white10, strokeWidth: 0.5),
                  getDrawingVerticalLine: (_) => FlLine(color: Colors.white10, strokeWidth: 0.5),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    axisNameWidget: const Text('Flow (CFS)', style: TextStyle(fontSize: 10)),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 52,
                      interval: maxVal / 5,
                      getTitlesWidget: (val, _) => Text(
                        _formatCfs(val),
                        style: const TextStyle(fontSize: 9),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: 30,
                      getTitlesWidget: (val, _) {
                        final label = monthLabels[val.round()];
                        if (label == null) return const SizedBox.shrink();
                        return Text(label, style: const TextStyle(fontSize: 9));
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [
                  // Q10–Q25 band (low flow, blue)
                  _bandLine(q10Spots, const Color(0x4456B4E9)),
                  _bandLine(q25Spots, const Color(0x4456B4E9), belowColor: const Color(0x2256B4E9)),
                  // Q25–Q75 band (normal, green)
                  _bandLine(q25Spots, const Color(0x44009E73)),
                  _bandLine(q75Spots, const Color(0x44009E73), belowColor: const Color(0x22009E73)),
                  // Q75–Q90 band (elevated, amber)
                  _bandLine(q75Spots, const Color(0x44E69F00)),
                  _bandLine(q90Spots, const Color(0x44E69F00), belowColor: const Color(0x22E69F00)),
                  // Median line
                  LineChartBarData(
                    spots: q50Spots,
                    color: const Color(0xFF009E73),
                    barWidth: 1.5,
                    dotData: const FlDotData(show: false),
                    dashArray: [4, 4],
                  ),
                  // NWRFC forecast (vermilion, solid) — appended after the
                  // bands so the betweenBarsData indices above are unaffected.
                  if (forecastSpots.isNotEmpty)
                    LineChartBarData(
                      spots: forecastSpots,
                      color: const Color(0xFFD55E00),
                      barWidth: 2.5,
                      dotData: const FlDotData(show: false),
                    ),
                  // Current water year observed flow (bold blue) — the
                  // primary series, drawn on top.
                  if (currentSpots.isNotEmpty)
                    LineChartBarData(
                      spots: currentSpots,
                      color: const Color(0xFF0072B2),
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                    ),
                ],
                betweenBarsData: [
                  // Q10–Q25 fill
                  BetweenBarsData(fromIndex: 0, toIndex: 1, color: const Color(0x2256B4E9)),
                  // Q25–Q75 fill
                  BetweenBarsData(fromIndex: 2, toIndex: 3, color: const Color(0x2200A073)),
                  // Q75–Q90 fill
                  BetweenBarsData(fromIndex: 4, toIndex: 5, color: const Color(0x22E69F00)),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => Colors.black87,
                    getTooltipItems: (spots) => spots.map((s) => LineTooltipItem(
                      '${_formatCfs(s.y)} CFS',
                      const TextStyle(color: Colors.white, fontSize: 11),
                    )).toList(),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _Legend(
            hasForecast: forecastSpots.isNotEmpty,
            hasCurrent: currentSpots.isNotEmpty,
          ),
        ],
      ),
    );
  }

  static LineChartBarData _bandLine(
    List<FlSpot> spots,
    Color color, {
    Color? belowColor,
  }) =>
      LineChartBarData(
        spots: spots,
        color: color,
        barWidth: 1,
        dotData: const FlDotData(show: false),
        belowBarData: belowColor != null
            ? BarAreaData(show: true, color: belowColor)
            : BarAreaData(show: false),
      );

  static List<FlSpot> _toSpots(List<WaterYearStat> stats, double Function(WaterYearStat) fn) =>
      stats.map((s) => FlSpot(s.dayOfWy.toDouble(), fn(s))).toList();

  static String _formatCfs(double val) {
    if (val >= 100000) return '${(val / 1000).toStringAsFixed(0)}k';
    if (val >= 10000) return '${(val / 1000).toStringAsFixed(1)}k';
    if (val >= 1000) return '${(val / 1000).toStringAsFixed(1)}k';
    return val.toStringAsFixed(0);
  }

  // Maps day-of-water-year to month abbreviation label
  static Map<int, String> _wyMonthLabels() => {
        1: 'Oct',
        32: 'Nov',
        62: 'Dec',
        93: 'Jan',
        124: 'Feb',
        152: 'Mar',
        183: 'Apr',
        213: 'May',
        244: 'Jun',
        274: 'Jul',
        305: 'Aug',
        335: 'Sep',
      };
}

class _Legend extends StatelessWidget {
  final bool hasForecast;
  final bool hasCurrent;
  const _Legend({this.hasForecast = false, this.hasCurrent = false});

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 12,
        runSpacing: 4,
        alignment: WrapAlignment.center,
        children: [
          const _LegendItem(color: Color(0x6656B4E9), label: 'Low (10–25th)'),
          const _LegendItem(color: Color(0x66009E73), label: 'Normal (25–75th)'),
          const _LegendItem(color: Color(0x66E69F00), label: 'Elevated (75–90th)'),
          const _LegendItem(color: Color(0xFF009E73), label: 'Median', dashed: true),
          if (hasCurrent)
            const _LegendItem(color: Color(0xFF0072B2), label: 'Current water year'),
          if (hasForecast)
            const _LegendItem(color: Color(0xFFD55E00), label: 'NWRFC forecast'),
        ],
      );
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool dashed;
  const _LegendItem({required this.color, required this.label, this.dashed = false});

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 20,
          height: dashed ? 2 : 10,
          decoration: dashed
              ? null
              : BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
          color: dashed ? color : null,
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10)),
      ]);
}
