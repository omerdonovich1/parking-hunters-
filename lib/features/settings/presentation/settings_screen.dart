import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/map_provider.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final radius = ref.watch(nearbyRadiusProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/profile'),
        ),
      ),
      body: ListView(
        children: [
          _sectionHeader('Map'),
          ListTile(
            leading: const Icon(Icons.radar),
            title: const Text('Search Radius'),
            subtitle: Text('${radius.toStringAsFixed(1)} km'),
            trailing: SizedBox(
              width: 180,
              child: Slider(
                value: radius,
                min: 0.5,
                max: 5.0,
                divisions: 9,
                label: '${radius.toStringAsFixed(1)} km',
                activeColor: AppTheme.primaryColor,
                onChanged: (value) =>
                    ref.read(nearbyRadiusProvider.notifier).state = value,
              ),
            ),
          ),
          const Divider(),
          _sectionHeader('Appearance'),
          RadioListTile<ThemeMode>(
            title: const Text('System default'),
            secondary: const Icon(Icons.brightness_auto),
            value: ThemeMode.system,
            groupValue: themeMode,
            activeColor: AppTheme.primaryColor,
            onChanged: (v) =>
                ref.read(themeModeProvider.notifier).state = v!,
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Light'),
            secondary: const Icon(Icons.light_mode),
            value: ThemeMode.light,
            groupValue: themeMode,
            activeColor: AppTheme.primaryColor,
            onChanged: (v) =>
                ref.read(themeModeProvider.notifier).state = v!,
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Dark'),
            secondary: const Icon(Icons.dark_mode),
            value: ThemeMode.dark,
            groupValue: themeMode,
            activeColor: AppTheme.primaryColor,
            onChanged: (v) =>
                ref.read(themeModeProvider.notifier).state = v!,
          ),
          const Divider(),
          _sectionHeader('Account'),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Sign Out',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure you want to sign out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        'Sign Out',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await ref.read(authServiceProvider).signOut();
                if (context.mounted) context.go('/auth');
              }
            },
          ),
          const Divider(),
          _sectionHeader('About'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Parking Hunter'),
            subtitle: Text('Version 1.0.0 · MVP Build'),
          ),
          const ListTile(
            leading: Icon(Icons.shield_outlined),
            title: Text('Privacy Policy'),
            subtitle: Text('Your location data is used only to show nearby spots'),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade500,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
