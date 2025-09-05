import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

// Configuración de Firebase para diferentes plataformas
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
            'reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macOS.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for Windows.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for Linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCtrraHknTFTgOMKevOz8KCGc83RBQ6RYs',
    appId: '1:373215790658:android:c4908a4c655a25a5180fdb',
    messagingSenderId: '373215790658',
    projectId: 'appemprendedores-b1f30',
    databaseURL: 'https://appemprendedores-b1f30-default-rtdb.firebaseio.com',
    storageBucket: 'appemprendedores-b1f30.firebasestorage.app',
  );

  // Configuración para Android

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB27lke87rlHh7wqgKzmYFc3oK0iLCzccc',
    appId: '1:373215790658:ios:f4c8623f44d50f82180fdb',
    messagingSenderId: '373215790658',
    projectId: 'appemprendedores-b1f30',
    databaseURL: 'https://appemprendedores-b1f30-default-rtdb.firebaseio.com',
    storageBucket: 'appemprendedores-b1f30.firebasestorage.app',
    androidClientId: '373215790658-391aovrs5s0t98cku9vnin9khfube95k.apps.googleusercontent.com',
    iosClientId: '373215790658-7pu3usn1t2i3c8k0fb7t4620fg4kt7a6.apps.googleusercontent.com',
    iosBundleId: 'com.example.emprendedor',
  );

  // Configuración para iOS

}