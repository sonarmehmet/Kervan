import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/config/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR');

  try {
    // Yapılandırma `flutterfire configure` ile eklenen yerel dosyalardan okunur
    // (android/app/google-services.json, ios/Runner/GoogleService-Info.plist).
    if (kIsWeb) {
      if (AppConfig.webApiKey.isEmpty || AppConfig.webProjectId.isEmpty) {
        throw StateError(
          'Web için Firebase ayarı yok. `bash scripts/run_web.sh` ile başlat '
          '(web_firebase.env dosyasını doldur).',
        );
      }
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: AppConfig.webApiKey,
          appId: AppConfig.webAppId,
          messagingSenderId: AppConfig.webMessagingSenderId,
          projectId: AppConfig.webProjectId,
          authDomain: AppConfig.webAuthDomain,
          storageBucket: AppConfig.webStorageBucket,
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
  } catch (error) {
    runApp(_FirebaseSetupErrorApp(error: error));
    return;
  }

  runApp(const ProviderScope(child: RotaApp()));
}

/// Firebase yapılandırması yoksa çökmek yerine ne yapılacağını gösterir.
class _FirebaseSetupErrorApp extends StatelessWidget {
  const _FirebaseSetupErrorApp({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Firebase yapılandırması bulunamadı',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Proje klasöründe `flutterfire configure` komutunu çalıştırıp '
                  'uygulamayı yeniden başlat. Ayrıntılar README.md dosyasında.',
                ),
                const SizedBox(height: 12),
                Text('Hata: $error', style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
