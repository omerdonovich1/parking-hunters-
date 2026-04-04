import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/map_provider.dart';
import '../../../providers/locale_provider.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final radius = ref.watch(nearbyRadiusProvider);
    final themeMode = ref.watch(themeModeProvider);
    final s = ref.watch(appStringsProvider);
    final locale = ref.watch(localeProvider);
    final isHebrew = locale.languageCode == 'he';

    return Scaffold(
      appBar: AppBar(
        title: Text(s.settingsTitle),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/profile'),
        ),
      ),
      body: ListView(
        children: [
          _sectionHeader(s.sectionMap),
          ListTile(
            leading: const Icon(Icons.radar),
            title: Text(s.searchRadius),
            subtitle: Text(s.kmLabel(radius)),
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
          _sectionHeader(s.sectionAppearance),
          RadioListTile<ThemeMode>(
            title: Text(s.systemDefault),
            secondary: const Icon(Icons.brightness_auto),
            value: ThemeMode.system,
            groupValue: themeMode,
            activeColor: AppTheme.primaryColor,
            onChanged: (v) =>
                ref.read(themeModeProvider.notifier).state = v!,
          ),
          RadioListTile<ThemeMode>(
            title: Text(s.light),
            secondary: const Icon(Icons.light_mode),
            value: ThemeMode.light,
            groupValue: themeMode,
            activeColor: AppTheme.primaryColor,
            onChanged: (v) =>
                ref.read(themeModeProvider.notifier).state = v!,
          ),
          RadioListTile<ThemeMode>(
            title: Text(s.dark),
            secondary: const Icon(Icons.dark_mode),
            value: ThemeMode.dark,
            groupValue: themeMode,
            activeColor: AppTheme.primaryColor,
            onChanged: (v) =>
                ref.read(themeModeProvider.notifier).state = v!,
          ),
          const Divider(),
          _sectionHeader(s.sectionLanguage),
          ListTile(
            leading: const Text('🌐', style: TextStyle(fontSize: 24)),
            title: Text(s.sectionLanguage),
            subtitle: Text(isHebrew ? s.langHebrew : s.langEnglish),
            trailing: _LangToggle(isHebrew: isHebrew),
          ),
          const Divider(),
          _sectionHeader(s.sectionAccount),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(
              s.signOut,
              style: const TextStyle(color: Colors.red),
            ),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(s.signOut),
                  content: Text(s.confirmSignOut),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(s.cancel),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(
                        s.signOut,
                        style: const TextStyle(color: Colors.red),
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
          _sectionHeader(s.sectionAbout),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(s.appName),
            subtitle: Text(s.version),
          ),
          ListTile(
            leading: const Icon(Icons.shield_outlined),
            title: Text(s.privacyPolicy),
            subtitle: Text(s.privacySubtitle),
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

// ── Language toggle pill ──────────────────────────────────────────────────────
class _LangToggle extends ConsumerWidget {
  final bool isHebrew;
  const _LangToggle({required this.isHebrew});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LangPill(
            label: 'EN',
            active: !isHebrew,
            onTap: () => ref.read(localeProvider.notifier).state = const Locale('en'),
          ),
          _LangPill(
            label: 'עב',
            active: isHebrew,
            onTap: () => ref.read(localeProvider.notifier).state = const Locale('he'),
          ),
        ],
      ),
    );
  }
}

class _LangPill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _LangPill({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppTheme.orange : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : Colors.white54,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
