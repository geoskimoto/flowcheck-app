import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_providers.dart';
import 'auth_provider.dart';

final favoritesProvider = FutureProvider<List<String>>((ref) async {
  final authStatus = ref.watch(authProvider);
  if (authStatus != AuthStatus.authenticated) return [];
  final client = ref.watch(apiClientProvider);
  final resp = await client.get('/favorites/');
  final list = resp.data as List<dynamic>;
  return list.map((e) => e['station_number'] as String).toList();
});

class FavoritesNotifier extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() async {
    final authStatus = ref.watch(authProvider);
    if (authStatus != AuthStatus.authenticated) return [];
    final client = ref.watch(apiClientProvider);
    final resp = await client.get('/favorites/');
    final list = resp.data as List<dynamic>;
    return list.map((e) => e['station_number'] as String).toList();
  }

  Future<void> add(String stationNumber) async {
    final client = ref.read(apiClientProvider);
    await client.post('/favorites/', data: {'station_number': stationNumber});
    ref.invalidateSelf();
  }

  Future<void> remove(String stationNumber) async {
    final client = ref.read(apiClientProvider);
    await client.delete('/favorites/$stationNumber');
    ref.invalidateSelf();
  }

  bool contains(String stationNumber) {
    return state.valueOrNull?.contains(stationNumber) ?? false;
  }
}

final favoritesNotifierProvider = AsyncNotifierProvider<FavoritesNotifier, List<String>>(FavoritesNotifier.new);
