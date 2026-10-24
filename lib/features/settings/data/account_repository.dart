import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/services/firebase_providers.dart';

/// Hesap silme. Sunucu tarafı (C: functions/src/account) profili, engelleri, bildirimleri ve
/// Auth kaydını siler; kullanıcının aktif etkinliklerini iptal eder.
class AccountRepository {
  AccountRepository(this._functions);

  final FirebaseFunctions _functions;

  Future<void> deleteAccount() async {
    await _functions.httpsCallable(FunctionNames.deleteAccount).call<void>();
  }
}

final accountRepositoryProvider = Provider<AccountRepository>(
  (ref) => AccountRepository(ref.watch(functionsProvider)),
);
