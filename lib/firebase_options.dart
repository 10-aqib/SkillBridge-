import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCQNu8Jmd7bkQp49JJmonaF_Lt1gTUS5JU',
    appId: '1:140302201182:web:073d234509f47e5b855fcf',
    messagingSenderId: '140302201182',
    projectId: 'skill-bridge-c68c3',
    authDomain: 'skill-bridge-c68c3.firebaseapp.com',
    storageBucket: 'skill-bridge-c68c3.firebasestorage.app',
    measurementId: 'G-KFZGJ1LPGT',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBWPvl9svHl-lpIKM-p3jBmEn5sUB_xQ3Y',
    appId: '1:140302201182:android:8f9f729bf8451680855fcf',
    messagingSenderId: '140302201182',
    projectId: 'skill-bridge-c68c3',
    storageBucket: 'skill-bridge-c68c3.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyARkgL5YcK_IcunRmSYzS27L4ML_2TUAfQ',
    appId: '1:140302201182:ios:d171589de8ebc72e855fcf',
    messagingSenderId: '140302201182',
    projectId: 'skill-bridge-c68c3',
    storageBucket: 'skill-bridge-c68c3.firebasestorage.app',
    iosBundleId: 'com.skillbridge.skillBridge',
  );
}
