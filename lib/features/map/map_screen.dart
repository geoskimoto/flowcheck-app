import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/models/station.dart';
import '../../core/providers/stations_provider.dart';
import '../../core/theme/app_theme.dart';
import 'widgets/station_bottom_sheet.dart';

class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  // PNW bounding box center
  static const _initialCenter = LatLng(46.5, -120.5);
  static const _initialZoom = 6.5;

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

  @override
  Widget build(BuildContext context) => FlutterMap(
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
            userAgentPackageName: 'com.geoskimoto.flowcheck',
          ),
          MarkerLayer(markers: markers),
        ],
      );
}

class _MapWithMarkers extends ConsumerStatefulWidget {
  final List<Station> stations;
  const _MapWithMarkers({required this.stations});

  @override
  ConsumerState<_MapWithMarkers> createState() => _MapWithMarkersState();
}

class _MapWithMarkersState extends ConsumerState<_MapWithMarkers> {
  Station? _selected;

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

  @override
  Widget build(BuildContext context) {
    final markers = widget.stations.map((s) => _buildMarker(s)).toList();
    return _BaseMap(markers: markers);
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
