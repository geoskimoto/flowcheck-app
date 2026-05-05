import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/station.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/favorites_provider.dart';
import '../../core/providers/stations_provider.dart';
import '../../core/theme/app_theme.dart';

class WatchlistScreen extends ConsumerWidget {
  const WatchlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authStatus = ref.watch(authProvider);

    if (authStatus == AuthStatus.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (authStatus == AuthStatus.unauthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('Watchlist')),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.bookmark_outline, size: 64),
            const SizedBox(height: 16),
            const Text('Sign in to save your watchlist across devices'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.push('/auth'),
              child: const Text('Sign In'),
            ),
          ]),
        ),
      );
    }

    final favsAsync = ref.watch(favoritesNotifierProvider);
    final stationsAsync = ref.watch(stationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Watchlist'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(favoritesNotifierProvider),
          ),
        ],
      ),
      body: favsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (favStationNumbers) {
          if (favStationNumbers.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.map_outlined, size: 64),
                  SizedBox(height: 16),
                  Text('No stations saved yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('Tap a gauge pin on the map and hit the bookmark icon to add it here.', textAlign: TextAlign.center),
                ]),
              ),
            );
          }

          return stationsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error loading station data: $e')),
            data: (allStations) {
              final stations = allStations
                  .where((s) => favStationNumbers.contains(s.stationNumber))
                  .toList();

              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(favoritesNotifierProvider),
                child: ListView.builder(
                  itemCount: stations.length,
                  itemBuilder: (_, i) => _WatchlistTile(station: stations[i]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _WatchlistTile extends ConsumerWidget {
  final Station station;
  const _WatchlistTile({required this.station});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = AppTheme.conditionColor(station.conditionLevel);

    return ListTile(
      onTap: () => context.push('/station/${station.stationNumber}'),
      leading: Container(
        width: 14, height: 14,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      title: Text(station.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(station.stationNumber, style: const TextStyle(fontSize: 11)),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
          if (station.currentDischargeCfs != null)
            Text('${station.currentDischargeCfs!.toStringAsFixed(0)} CFS',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          if (station.percentileRank != null)
            Text('${station.percentileRank!.toStringAsFixed(0)}th pct',
                style: TextStyle(fontSize: 11, color: color)),
        ]),
        IconButton(
          icon: const Icon(Icons.bookmark, size: 20),
          onPressed: () => ref.read(favoritesNotifierProvider.notifier).remove(station.stationNumber),
          tooltip: 'Remove from watchlist',
        ),
      ]),
    );
  }
}
