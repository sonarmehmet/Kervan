import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../event_creation/data/event_repository.dart';

/// Etkinliğin tam adresi. Yalnızca sahip ve onaylı katılımcı için çağır
/// (başkası için Firestore izin hatası verir).
/// Harita entegrasyonu eklendiğinde enlem/boylam da burada yönetilecek.
final eventAddressProvider = FutureProvider.family<String?, String>(
  (ref, eventId) => ref.watch(eventRepositoryProvider).getAddress(eventId),
);
