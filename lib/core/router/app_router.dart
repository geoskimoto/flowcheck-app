import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/map/map_screen.dart';
import '../../features/station/station_screen.dart';
import '../../features/watchlist/watchlist_screen.dart';
import '../../features/alerts/alerts_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/auth/auth_screen.dart';
import 'shell_scaffold.dart';

final routerProvider = Provider<GoRouter>((ref) => GoRouter(
    initialLocation: '/map',
    redirect: (_, _s) => null,
    routes: [
      ShellRoute(
        builder: (_, _s, child) => ShellScaffold(child: child),
        routes: [
          GoRoute(path: '/map', builder: (_, _s) => const MapScreen()),
          GoRoute(path: '/watchlist', builder: (_, _s) => const WatchlistScreen()),
          GoRoute(path: '/alerts', builder: (_, _s) => const AlertsScreen()),
          GoRoute(path: '/settings', builder: (_, _s) => const SettingsScreen()),
        ],
      ),
      GoRoute(
        path: '/station/:id',
        builder: (_, state) => StationScreen(stationNumber: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/auth',
        builder: (_, _s) => const AuthScreen(),
      ),
    ],
  ));
