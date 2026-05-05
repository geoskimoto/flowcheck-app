import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/station.dart';
import '../../../core/providers/alerts_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/favorites_provider.dart';
import '../../../core/theme/app_theme.dart';

class StationBottomSheet extends ConsumerWidget {
  final Station station;
  final VoidCallback onDismiss;

  const StationBottomSheet({super.key, required this.station, required this.onDismiss});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isAuth = ref.watch(authProvider) == AuthStatus.authenticated;
    final favs = ref.watch(favoritesNotifierProvider);
    final alerts = ref.watch(alertSubscriptionsProvider);
    final isFav = favs.valueOrNull?.contains(station.stationNumber) ?? false;
    final isAlerted = alerts.valueOrNull?.contains(station.stationNumber) ?? false;
    final condColor = AppTheme.conditionColor(station.conditionLevel);

    return DraggableScrollableSheet(
      initialChildSize: 0.38,
      minChildSize: 0.2,
      maxChildSize: 0.6,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Station name + condition chip
            Row(children: [
              Expanded(
                child: Text(station.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ),
              _ConditionChip(label: station.conditionLabel, color: condColor),
            ]),
            const SizedBox(height: 4),
            Text(station.stationNumber, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),

            const SizedBox(height: 16),

            // CFS + percentile row
            Row(children: [
              _StatTile(
                label: 'Flow',
                value: station.currentDischargeCfs != null
                    ? '${station.currentDischargeCfs!.toStringAsFixed(0)} CFS'
                    : '—',
              ),
              const SizedBox(width: 24),
              _StatTile(
                label: 'Percentile',
                value: station.percentileRank != null
                    ? '${station.percentileRank!.toStringAsFixed(0)}th'
                    : '—',
              ),
            ]),

            const SizedBox(height: 20),

            // Action buttons
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.show_chart),
                  label: const Text('View Chart'),
                  onPressed: () {
                    Navigator.pop(context);
                    context.push('/station/${station.stationNumber}');
                  },
                ),
              ),
              if (isAuth) ...[
                const SizedBox(width: 10),
                _IconToggle(
                  icon: isFav ? Icons.bookmark : Icons.bookmark_outline,
                  color: isFav ? theme.colorScheme.primary : null,
                  tooltip: isFav ? 'Remove from watchlist' : 'Add to watchlist',
                  onTap: () => isFav
                      ? ref.read(favoritesNotifierProvider.notifier).remove(station.stationNumber)
                      : ref.read(favoritesNotifierProvider.notifier).add(station.stationNumber),
                ),
                const SizedBox(width: 6),
                _IconToggle(
                  icon: isAlerted ? Icons.notifications : Icons.notifications_outlined,
                  color: isAlerted ? const Color(0xFFD55E00) : null,
                  tooltip: isAlerted ? 'Remove flood alert' : 'Set flood alert (95th pct)',
                  onTap: () => isAlerted
                      ? ref.read(alertSubscriptionsProvider.notifier).unsubscribe(station.stationNumber)
                      : ref.read(alertSubscriptionsProvider.notifier).subscribe(station.stationNumber),
                ),
              ] else ...[
                const SizedBox(width: 10),
                TextButton(
                  onPressed: () => context.push('/auth'),
                  child: const Text('Sign in for alerts'),
                ),
              ],
            ]),
          ],
        ),
      ),
    );
  }
}

class _ConditionChip extends StatelessWidget {
  final String label;
  final Color color;
  const _ConditionChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 1),
        ),
        child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      );
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
      Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
    ]);
  }
}

class _IconToggle extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final String tooltip;
  final VoidCallback onTap;
  const _IconToggle({required this.icon, this.color, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) => IconButton(
        icon: Icon(icon, color: color),
        tooltip: tooltip,
        onPressed: onTap,
      );
}
