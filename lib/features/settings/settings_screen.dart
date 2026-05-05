import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authStatus = ref.watch(authProvider);
    final isAuth = authStatus == AuthStatus.authenticated;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(children: [
        const _SectionHeader('Account'),
        if (isAuth)
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign Out'),
            onTap: () async {
              await ref.read(authProvider.notifier).logout();
            },
          )
        else
          ListTile(
            leading: const Icon(Icons.login),
            title: const Text('Sign In / Register'),
            subtitle: const Text('Save watchlist and receive flood alerts'),
            onTap: () => context.push('/auth'),
          ),

        const Divider(),
        const _SectionHeader('About'),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('FlowCheck'),
          subtitle: const Text('v1.0.0 • USGS streamflow data'),
        ),
        ListTile(
          leading: const Icon(Icons.water),
          title: const Text('Data Source'),
          subtitle: const Text('USGS National Water Information System'),
        ),
      ]),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(
          title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
      );
}
