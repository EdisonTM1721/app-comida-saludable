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
    apiKey: 'AIzaSyDY4k8MHDDWZbl3HEyhDCnGh57g3PdAil4',
    appId: '1:373215790658:android:bc6063e1566bbd78180fdb',
    messagingSenderId: '373215790658',
    projectId: 'appemprendedores-b1f30',
    databaseURL: 'https://appemprendedores-b1f30-default-rtdb.firebaseio.com',
    storageBucket: 'appemprendedores-b1f30.firebasestorage.app',
  );

  // Configuración para Android

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB27lke87rlHh7wqgKzmYFc3oK0iLCzccc',
    appId: '1:373215790658:ios:5f4e5b97ca7ac218180fdb',
    messagingSenderId: '373215790658',
    projectId: 'appemprendedores-b1f30',
    databaseURL: 'https://appemprendedores-b1f30-default-rtdb.firebaseio.com',
    storageBucket: 'appemprendedores-b1f30.firebasestorage.app',
    androidClientId: '373215790658-391aovrs5s0t98cku9vnin9khfube95k.apps.googleusercontent.com',
    iosClientId: '373215790658-s10oie248kh406bpdsbopei3va47ed7i.apps.googleusercontent.com',
    iosBundleId: 'com.crearcos.emprendedor',
  );

  // Configuración para iOS

}