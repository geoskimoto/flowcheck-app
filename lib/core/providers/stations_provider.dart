import 'package:flutter_riverpod/flutter_riverpod.dart';
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
