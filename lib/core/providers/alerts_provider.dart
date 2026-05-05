import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_providers.dart';
import 'auth_provider.dart';

class AlertSubscriptionsNotifier extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() async {
    final authStatus = ref.watch(authProvider);
    if (authStatus != AuthStatus.authenticated) return [];
    final client = ref.watch(apiClientProvider);
    final resp = await client.get('/alerts/subscriptions/');
    final list = resp.data as List<dynamic>;
    return list.map((e) => e['station_number'] as String).toList();
  }

  Future<void> subscribe(String stationNumber) async {
    final client = ref.read(apiClientProvider);
    await client.post('/alerts/subscriptions/', data: {'station_number': stationNumber});
    ref.invalidateSelf();
  }

  Future<void> unsubscribe(String stationNumber) async {
    final client = ref.read(apiClientProvider);
    await client.delete('/alerts/subscriptions/$stationNumber');
    ref.invalidateSelf();
  }

  bool isSubscribed(String stationNumber) {
    return state.valueOrNull?.contains(stationNumber) ?? false;
  }
}

final alertSubscriptionsProvider =
    AsyncNotifierProvider<AlertSubscriptionsNotifier, List<String>>(AlertSubscriptionsNotifier.new);
