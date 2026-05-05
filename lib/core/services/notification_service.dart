import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../providers/api_providers.dart';

// Top-level handler required by FCM for background messages
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  // Background messages are displayed automatically by FCM when app is killed.
  // No action needed here unless you need custom background processing.
  debugPrint('FCM background: ${message.messageId}');
}

class NotificationService {
  final ApiClient _api;
  NotificationService(this._api);

  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

    // Request permission (Android 13+ / iOS)
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('FCM permission: ${settings.authorizationStatus}');

    // Register token with backend when it's available
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) await _registerToken(token);

    // Re-register on token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen(_registerToken);

    // Handle foreground messages — show a snackbar or in-app banner
    // (the calling widget layer can listen via onMessage stream directly)
    FirebaseMessaging.onMessage.listen((msg) {
      debugPrint('FCM foreground: ${msg.notification?.title}');
    });
  }

  Future<void> _registerToken(String token) async {
    try {
      await _api.post('/devices/register', data: {
        'fcm_token': token,
        'platform': 'android',
      });
    } catch (e) {
      debugPrint('FCM token registration failed: $e');
    }
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref.read(apiClientProvider));
});
