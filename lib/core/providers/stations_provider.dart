import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/current_water_year.dart';
import '../models/forecast.dart';
import '../models/station.dart';
import 'api_providers.dart';

final stationsProvider = FutureProvider<List<Station>>((ref) async {
  final client = ref.watch(apiClientProvider);
  final resp = await client.get('/stations/');
  final list = resp.data as List<dynamic>;
  return list.map((e) => Station.fromJson(e as Map<String, dynamic>)).toList();
});

final stationDetailProvider = FutureProvider.family<Station, String>((ref, stationNumber) async {
  final client = ref.watch(apiClientProvider);
  final resp = await client.get('/stations/$stationNumber');
  return Station.fromJson(resp.data as Map<String, dynamic>);
});

final waterYearStatsProvider = FutureProvider.family<List<dynamic>, String>((ref, stationNumber) async {
  final client = ref.watch(apiClientProvider);
  final resp = await client.get('/stations/$stationNumber/water-year-stats');
  return resp.data as List<dynamic>;
});

/// Observed discharge for the in-progress water year. Supplementary to the
/// chart — any failure (404/503/none) yields [] so the bands still render.
final currentWaterYearProvider =
    FutureProvider.family<List<CurrentWyPoint>, String>((ref, stationNumber) async {
  final client = ref.watch(apiClientProvider);
  try {
    final resp = await client.get('/stations/$stationNumber/current-water-year');
    return (resp.data as List<dynamic>)
        .map((e) => CurrentWyPoint.fromJson(e as Map<String, dynamic>))
        .toList();
  } on DioException {
    return const [];
  }
});

/// NWRFC forecast for a station. Returns null when the station has no
/// forecast mapping (backend responds 404) — not an error state.
final forecastProvider =
    FutureProvider.family<Forecast?, String>((ref, stationNumber) async {
  final client = ref.watch(apiClientProvider);
  try {
    final resp = await client.get('/stations/$stationNumber/forecast');
    return Forecast.fromJson(resp.data as Map<String, dynamic>);
  } on DioException catch (e) {
    if (e.response?.statusCode == 404) return null;
    rethrow;
  }
});
