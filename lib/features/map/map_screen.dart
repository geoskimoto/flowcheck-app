import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/models/station.dart';
import '../../core/providers/stations_provider.dart';
import '../../core/theme/app_theme.dart';
import 'widgets/station_bottom_sheet.dart';

class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  // Western US bounding box center (matches expanded backend coverage).
  static const _initialCenter = LatLng(43.5, -116.0);
  static const _initialZoom = 5.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stationsAsync = ref.watch(stationsProvider);

    return Scaffold(
      body: stationsAsync.when(
        loading: () => const Stack(children: [
          _BaseMap(markers: []),
          Center(child: CircularProgressIndicator()),
        ]),
        error: (e, _) => Stack(children: [
          const _BaseMap(markers: []),
          Center(
            child: Card(
              margin: const EdgeInsets.all(24),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.wifi_off, size: 48),
                  const SizedBox(height: 8),
                  const Text('Could not load gauge data', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('$e', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(stationsProvider),
                    child: const Text('Retry'),
                  ),
                ]),
              ),
            ),
          ),
        ]),
        data: (stations) => _MapWithMarkers(stations: stations),
      ),
    );
  }
}

class _BaseMap extends StatelessWidget {
  final List<Marker> markers;
  const _BaseMap({required this.markers});

  // Cluster only when the map is busy; below this many visible markers,
  // show them individually (no grouping).
  static const _clusterThreshold = 1000;

  @override
  Widget build(BuildContext context) {
    final cluster = markers.length >= _clusterThreshold;
    return FlutterMap(
      options: const MapOptions(
        initialCenter: MapScreen._initialCenter,
        initialZoom: MapScreen._initialZoom,
        minZoom: 4,
        maxZoom: 16,
        interactionOptions: InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.StreamCast',
        ),
        if (cluster)
          MarkerClusterLayerWidget(
            options: MarkerClusterLayerOptions(
              markers: markers,
              maxClusterRadius: 50,
              size: const Size(44, 44),
              padding: const EdgeInsets.all(50),
              disableClusteringAtZoom: 12,
              // Let each Marker's own GestureDetector handle taps so the
              // existing tap -> station bottom sheet still works.
              markerChildBehavior: true,
              builder: (context, clusterMarkers) {
                final scheme = Theme.of(context).colorScheme;
                return Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.primary,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 4),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '${clusterMarkers.length}',
                      style: TextStyle(
                        color: scheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          )
        else
          MarkerLayer(markers: markers),
      ],
    );
  }
}

String _conditionLabel(ConditionLevel level) => switch (level) {
      ConditionLevel.unknown => 'Unknown',
      ConditionLevel.low => 'Low',
      ConditionLevel.belowNormal => 'Below normal',
      ConditionLevel.normal => 'Normal',
      ConditionLevel.elevated => 'Elevated',
      ConditionLevel.flood => 'Flood',
    };

class _MapWithMarkers extends ConsumerStatefulWidget {
  final List<Station> stations;
  const _MapWithMarkers({required this.stations});

  @override
  ConsumerState<_MapWithMarkers> createState() => _MapWithMarkersState();
}

class _MapWithMarkersState extends ConsumerState<_MapWithMarkers> {
  Station? _selected;
  String _query = '';
  final Set<String> _states = {};
  final Set<ConditionLevel> _levels = {};
  // Most gauges have no percentile data ("Unknown"); hide them by default.
  bool _showUnknown = false;
  // Show only gauges that have an NWRFC forecast (on by default).
  bool _onlyForecast = true;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<String> get _availableStates =>
      widget.stations.map((s) => s.state).toSet().toList()..sort();

  List<Station> get _filtered {
    final q = _query.trim().toLowerCase();
    // Guard: only apply the forecast filter if the API actually reports
    // the flag (an un-updated deployed API returns it for none — don't
    // blank the whole map in that case).
    final forecastFilterActive =
        _onlyForecast && widget.stations.any((s) => s.hasForecast);
    return widget.stations.where((s) {
      if (q.isNotEmpty &&
          !s.name.toLowerCase().contains(q) &&
          !s.stationNumber.toLowerCase().contains(q)) {
        return false;
      }
      if (forecastFilterActive && !s.hasForecast) return false;
      if (!_showUnknown && s.conditionLevel == ConditionLevel.unknown) {
        return false;
      }
      if (_states.isNotEmpty && !_states.contains(s.state)) return false;
      if (_levels.isNotEmpty && !_levels.contains(s.conditionLevel)) {
        return false;
      }
      return true;
    }).toList();
  }

  int get _activeFilterCount => _states.length + _levels.length;

  void _onMarkerTap(Station station) {
    setState(() => _selected = station);
    _showBottomSheet(station);
  }

  void _showBottomSheet(Station station) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StationBottomSheet(
        station: station,
        onDismiss: () => setState(() => _selected = null),
      ),
    );
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) {
          void toggleState(String s) => setSheet(() {
                _states.contains(s) ? _states.remove(s) : _states.add(s);
              });
          void toggleLevel(ConditionLevel l) => setSheet(() {
                _levels.contains(l) ? _levels.remove(l) : _levels.add(l);
              });
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Filters',
                        style: Theme.of(ctx).textTheme.titleLarge),
                    const Spacer(),
                    TextButton(
                      onPressed: () => setSheet(() {
                        _states.clear();
                        _levels.clear();
                        _showUnknown = false; // back to default
                        _onlyForecast = true; // back to default
                      }),
                      child: const Text('Clear all'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('State', style: Theme.of(ctx).textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _availableStates
                      .map((s) => FilterChip(
                            label: Text(s),
                            selected: _states.contains(s),
                            onSelected: (_) => toggleState(s),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 16),
                Text('Condition',
                    style: Theme.of(ctx).textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: ConditionLevel.values
                      .where((l) => l != ConditionLevel.unknown)
                      .map((l) => FilterChip(
                            avatar: CircleAvatar(
                                backgroundColor: AppTheme.conditionColor(l),
                                radius: 7),
                            label: Text(_conditionLabel(l)),
                            selected: _levels.contains(l),
                            onSelected: (_) => toggleLevel(l),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text('Only stations with forecasts'),
                  subtitle: const Text('Gauges that have an NWRFC forecast'),
                  value: _onlyForecast,
                  onChanged: (v) => setSheet(() => _onlyForecast = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text('Show unknown-condition gauges'),
                  subtitle: const Text('Gauges without current percentile data'),
                  value: _showUnknown,
                  onChanged: (v) => setSheet(() => _showUnknown = v),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ).whenComplete(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final markers = filtered.map((s) => _buildMarker(s)).toList();
    final theme = Theme.of(context);

    return Stack(
      children: [
        _BaseMap(markers: markers),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Column(
              children: [
                Material(
                  elevation: 3,
                  borderRadius: BorderRadius.circular(12),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      const Icon(Icons.search, size: 20),
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          decoration: const InputDecoration(
                            hintText: 'Search site ID or name',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 14, horizontal: 8),
                          ),
                          onChanged: (v) => setState(() => _query = v),
                        ),
                      ),
                      if (_query.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _query = '');
                          },
                        ),
                      Badge(
                        isLabelVisible: _activeFilterCount > 0,
                        label: Text('$_activeFilterCount'),
                        child: IconButton(
                          icon: const Icon(Icons.tune),
                          tooltip: 'Filters',
                          onPressed: _openFilterSheet,
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${filtered.length} of ${widget.stations.length} gauges',
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Marker _buildMarker(Station station) {
    final color = AppTheme.conditionColor(station.conditionLevel);
    final isSelected = _selected?.stationNumber == station.stationNumber;

    return Marker(
      point: LatLng(station.latitude, station.longitude),
      width: isSelected ? 32 : 24,
      height: isSelected ? 32 : 24,
      child: GestureDetector(
        onTap: () => _onMarkerTap(station),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? Colors.white : Colors.white54,
              width: isSelected ? 2.5 : 1.5,
            ),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6, spreadRadius: 1),
            ],
          ),
        ),
      ),
    );
  }
}
