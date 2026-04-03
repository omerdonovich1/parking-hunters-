import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError('DefaultFirebaseOptions not configured for this platform.');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD0rpxUpfnfiQc5yXmkdmTDLv41uBEhB0I',
    appId: '1:859365520944:web:placeholder',
    messagingSenderId: '859365520944',
    projectId: 'parking-hunter-12345',
    storageBucket: 'parking-hunter-12345.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD0rpxUpfnfiQc5yXmkdmTDLv41uBEhB0I',
    appId: '1:859365520944:ios:13388fba23dca189015ff5',
    messagingSenderId: '859365520944',
    projectId: 'parking-hunter-12345',
    storageBucket: 'parking-hunter-12345.firebasestorage.app',
    iosBundleId: 'com.parkinghunter.parkingHunter',
    iosClientId: '859365520944-k2of66h1lbu2eehtlbko1q6nt3mn2fia.apps.googleusercontent.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCbeO2izRCR3OGhItRb8s-H6R7LGQcxayk',
    appId: '1:859365520944:android:7f6058b84a1ea379015ff5',
    messagingSenderId: '859365520944',
    projectId: 'parking-hunter-12345',
    storageBucket: 'parking-hunter-12345.firebasestorage.app',
  );
}
