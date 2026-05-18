import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/station.dart';
import '../../core/providers/stations_provider.dart';
import '../../core/theme/app_theme.dart';
import 'widgets/water_year_chart.dart';

class StationScreen extends ConsumerWidget {
  final String stationNumber;
  const StationScreen({super.key, required this.stationNumber});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stationAsync = ref.watch(stationDetailProvider(stationNumber));
    final statsAsync = ref.watch(waterYearStatsProvider(stationNumber));

    return Scaffold(
      appBar: AppBar(
        title: stationAsync.when(
          data: (s) => Text(s.name, overflow: TextOverflow.ellipsis),
          loading: () => const Text('Loading...'),
          error: (_, _s) => Text(stationNumber),
        ),
      ),
      body: stationAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(message: '$e', onRetry: () => ref.invalidate(stationDetailProvider(stationNumber))),
        data: (station) => Column(
          children: [
            // Condition header bar
            Container(
              width: double.infinity,
              color: AppTheme.conditionColor(station.conditionLevel).withValues(alpha: 0.15),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(children: [
                Container(
                  width: 12, height: 12,
                  decoration: BoxDecoration(
                    color: AppTheme.conditionColor(station.conditionLevel),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  station.conditionLabel,
                  style: TextStyle(
                    color: AppTheme.conditionColor(station.conditionLevel),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (station.currentDischargeCfs != null)
                  Text(
                    '${station.currentDischargeCfs!.toStringAsFixed(0)} CFS',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                if (station.percentileRank != null) ...[
                  const SizedBox(width: 12),
                  Text(
                    '${station.percentileRank!.toStringAsFixed(0)}th pct',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ]),
            ),

            // Water year chart
            Expanded(
              child: statsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _s) => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Water year chart unavailable for this station.', textAlign: TextAlign.center),
                  ),
                ),
                data: (rawStats) => WaterYearChart(
                  statsJson: rawStats,
                  stationName: station.name,
                  currentPercentile: station.percentileRank,
                  forecast:
                      ref.watch(forecastProvider(stationNumber)).valueOrNull,
                ),
              ),
            ),

            // Station metadata footer
            _MetadataFooter(station: station),
          ],
        ),
      ),
    );
  }
}

class _MetadataFooter extends StatelessWidget {
  final Station station;
  const _MetadataFooter({required this.station});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _MetaItem(label: 'Station', value: station.stationNumber),
        _MetaItem(label: 'State', value: station.state),
        if (station.basin != null) _MetaItem(label: 'Basin', value: station.basin!),
      ]),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final String label;
  final String value;
  const _MetaItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(children: [
      Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
      Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
    ]);
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 8),
          const Text('Failed to load station'),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ]),
      );
}
