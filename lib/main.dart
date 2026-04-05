import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'core/config/firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_router.dart';
import 'features/settings/presentation/settings_screen.dart';
import 'providers/locale_provider.dart';
import 'services/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    // Register background FCM handler before the app is fully started
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('Firebase init skipped (not configured): $e');
  }
  if (!kIsWeb) {
    try {
      await MobileAds.instance.initialize();
    } catch (e) {
      debugPrint('AdMob init skipped: $e');
    }
  }
  runApp(const ProviderScope(child: ParkingHunterApp()));
}

class ParkingHunterApp extends ConsumerWidget {
  const ParkingHunterApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router    = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale    = ref.watch(localeProvider);
    final app = MaterialApp.router(
      title: 'Parking Hunter',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('he')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );

    // On web: wrap in iPhone frame
    if (kIsWeb) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: _PhoneFrame(child: app),
      );
    }

    return app;
  }
}

class _PhoneFrame extends StatelessWidget {
  final Widget child;
  const _PhoneFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    const phoneW = 390.0;
    const phoneH = 844.0;
    const frameThickness = 12.0;
    const cornerRadius = 50.0;
    const sideButtonW = 4.0;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Scale to fit screen while keeping aspect ratio
            final scaleW = (constraints.maxWidth - 80) / phoneW;
            final scaleH = (constraints.maxHeight - 60) / phoneH;
            final scale = scaleW < scaleH ? scaleW : scaleH;
            final w = phoneW * scale;
            final h = phoneH * scale;

            return SizedBox(
              width: w + (frameThickness * 2 + sideButtonW * 2) * scale,
              height: h + frameThickness * 2 * scale,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Phone body
                  Container(
                    width: w + frameThickness * 2 * scale,
                    height: h + frameThickness * 2 * scale,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(cornerRadius * scale),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.6),
                          blurRadius: 40,
                          spreadRadius: 10,
                          offset: const Offset(0, 10),
                        ),
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.05),
                          blurRadius: 1,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(frameThickness * scale),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular((cornerRadius - frameThickness) * scale),
                        child: SizedBox(
                          width: w,
                          height: h,
                          child: MediaQuery(
                            data: MediaQuery.of(context).copyWith(
                              size: Size(phoneW, phoneH),
                              devicePixelRatio: 1.0,
                              padding: const EdgeInsets.only(top: 44, bottom: 34),
                              viewPadding: const EdgeInsets.only(top: 44, bottom: 34),
                              viewInsets: EdgeInsets.zero,
                            ),
                            child: child,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Dynamic island / notch
                  Positioned(
                    top: frameThickness * scale + 10 * scale,
                    child: Container(
                      width: 120 * scale,
                      height: 34 * scale,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(20 * scale),
                      ),
                    ),
                  ),

                  // Side buttons (right — power)
                  Positioned(
                    right: 0,
                    top: h * 0.3,
                    child: Container(
                      width: sideButtonW * scale,
                      height: 70 * scale,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3A3A3A),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),

                  // Side buttons (left — volume up)
                  Positioned(
                    left: 0,
                    top: h * 0.25,
                    child: Container(
                      width: sideButtonW * scale,
                      height: 45 * scale,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3A3A3A),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),

                  // Side buttons (left — volume down)
                  Positioned(
                    left: 0,
                    top: h * 0.25 + 55 * scale,
                    child: Container(
                      width: sideButtonW * scale,
                      height: 45 * scale,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3A3A3A),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
