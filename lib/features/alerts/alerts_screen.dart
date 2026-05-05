import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/alerts_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/stations_provider.dart';
import '../../core/theme/app_theme.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authStatus = ref.watch(authProvider);

    if (authStatus != AuthStatus.authenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('Flood Alerts')),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.notifications_outlined, size: 64),
            const SizedBox(height: 16),
            const Text('Sign in to receive flood alerts'),
            const SizedBox(height: 16),
            FilledButton(onPressed: () => context.push('/auth'), child: const Text('Sign In')),
          ]),
        ),
      );
    }

    final alertsAsync = ref.watch(alertSubscriptionsProvider);
    final stationsAsync = ref.watch(stationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Flood Alerts')),
      body: alertsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (subscribedStations) {
          if (subscribedStations.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.notifications_none, size: 64),
                  SizedBox(height: 16),
                  Text('No alert subscriptions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('Tap the bell icon on a station to get notified when flow exceeds the 95th percentile.',
                      textAlign: TextAlign.center),
                ]),
              ),
            );
          }

          return stationsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _s) => const SizedBox.shrink(),
            data: (allStations) {
              final stations = allStations.where((s) => subscribedStations.contains(s.stationNumber)).toList();
              return ListView.builder(
                itemCount: stations.length,
                itemBuilder: (_, i) {
                  final s = stations[i];
                  final color = AppTheme.conditionColor(s.conditionLevel);
                  return ListTile(
                    onTap: () => context.push('/station/${s.stationNumber}'),
                    leading: Icon(Icons.notifications, color: color),
                    title: Text(s.name),
                    subtitle: Text('Alert when ≥ 95th percentile'),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      if (s.percentileRank != null)
                        Chip(
                          label: Text('${s.percentileRank!.toStringAsFixed(0)}th'),
                          backgroundColor: color.withValues(alpha: 0.2),
                          labelStyle: TextStyle(color: color, fontSize: 11),
                          padding: EdgeInsets.zero,
                        ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => ref.read(alertSubscriptionsProvider.notifier).unsubscribe(s.stationNumber),
                      ),
                    ]),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
