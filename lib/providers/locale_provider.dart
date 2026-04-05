import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/l10n/app_strings.dart';

/// Current app locale — toggled between EN and HE.
final localeProvider = StateProvider<Locale>((ref) => const Locale('en'));

/// Convenience: resolved AppStrings object based on current locale.
final appStringsProvider = Provider<AppStrings>((ref) {
  final locale = ref.watch(localeProvider);
  return AppStrings(isHebrew: locale.languageCode == 'he');
});
