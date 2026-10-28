import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../core/services/firebase_providers.dart';
import '../../authentication/data/auth_repository.dart';
import '../../event_details/data/event.dart';
import '../../../core/constants/event_categories.dart';
import 'event_filter.dart';

/// Etkinlik listeleme sorguları. Gereken indexler firestore.indexes.json içindedir.
class EventQueryRepository {
  EventQueryRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _events =>
      _firestore.collection(FirestorePaths.events);

  /// Gelecekteki aktif etkinlikler, başlangıç zamanına göre artan sırada.
  Stream<List<Event>> watchDiscover(EventFilter filter, {required int limit}) {
    Query<Map<String, dynamic>> query = _events.where('status', isEqualTo: 'active');
    if (filter.city != null) {
      query = query.where('city', isEqualTo: filter.city);
    }
    // Grup süzgeci istemcide uygulanır (kategori listesi büyük); tek kategori sunucuda.
    if (filter.categoryId != null && filter.groupId == null) {
      query = query.where('category', isEqualTo: filter.categoryId);
    }

    var from = DateTime.now();
    final until = filter.until;
    final date = filter.date;
    if (date != null) {
      final dayStart = DateTime(date.year, date.month, date.day);
      if (dayStart.isAfter(from)) from = dayStart;
    }
    query = query.where(
      'startsAt',
      isGreaterThanOrEqualTo: Timestamp.fromDate(from),
    );
    if (until != null) {
      query = query.where('startsAt', isLessThan: Timestamp.fromDate(until));
    }

    return query
        .orderBy('startsAt')
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Event.fromFirestore).toList());
  }

  /// Kullanıcının oluşturduğu etkinlikler (en yeni başlangıç önce).
  Stream<List<Event>> watchOwned(String uid) {
    return _events
        .where('ownerId', isEqualTo: uid)
        .orderBy('startsAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Event.fromFirestore).toList());
  }

  /// Kullanıcının onaylı katılımcı olduğu etkinlikler.
  /// `participants` koleksiyon grubundan kendi kayıtları okunur, sonra etkinlikler çekilir.
  Stream<List<Event>> watchJoined(String uid) {
    return _firestore
        .collectionGroup(FirestorePaths.participants)
        .where('userId', isEqualTo: uid)
        .snapshots()
        .asyncMap((snapshot) async {
      final ids = snapshot.docs
          .map((doc) => doc.reference.parent.parent?.id)
          .whereType<String>()
          .toList();
      final docs = await Future.wait(ids.map((id) => _events.doc(id).get()));
      final events = docs
          .where((doc) => doc.exists)
          .map(Event.fromFirestore)
          .toList()
        ..sort((a, b) => b.startsAt.compareTo(a.startsAt));
      return events;
    });
  }
}

final eventQueryRepositoryProvider = Provider<EventQueryRepository>(
  (ref) => EventQueryRepository(ref.watch(firestoreProvider)),
);

/// Keşif filtresi. Değiştirirken sayfalamayı da sıfırla:
/// `discoverLimitProvider` değerini `discoverPageSize`a çek.
final discoverFilterProvider = StateProvider<EventFilter>(
  (ref) => const EventFilter(),
);

const int discoverPageSize = 20;

/// Ekranda gösterilecek en fazla etkinlik sayısı ("Daha fazla göster" ile artar).
final discoverLimitProvider = StateProvider<int>((ref) => discoverPageSize);

/// Kategori grubu süzgeci istemcide uygulandığı için o durumda daha çok etkinlik çekilir.
const int groupFilterFetchLimit = 100;

final discoverEventsProvider = StreamProvider<List<Event>>((ref) {
  final filter = ref.watch(discoverFilterProvider);
  final limit = ref.watch(discoverLimitProvider);
  final effective = filter.groupId != null && limit < groupFilterFetchLimit
      ? groupFilterFetchLimit
      : limit;
  return ref
      .watch(eventQueryRepositoryProvider)
      .watchDiscover(filter, limit: effective)
      .map((events) => applyGroupFilter(events, filter.groupId));
});

/// Ana sayfa şeritleri için: seçili şehirdeki yaklaşan etkinlikler (en fazla [homeFetchLimit]).
const int homeFetchLimit = 100;

final homeEventsProvider = StreamProvider<List<Event>>((ref) {
  final city = ref.watch(discoverFilterProvider.select((f) => f.city));
  return ref
      .watch(eventQueryRepositoryProvider)
      .watchDiscover(EventFilter(city: city), limit: homeFetchLimit);
});

final ownedEventsProvider = StreamProvider<List<Event>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream<List<Event>>.value(const <Event>[]);
  return ref.watch(eventQueryRepositoryProvider).watchOwned(user.uid);
});

final joinedEventsProvider = StreamProvider<List<Event>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream<List<Event>>.value(const <Event>[]);
  return ref.watch(eventQueryRepositoryProvider).watchJoined(user.uid);
});

/// [groupId] verilmişse yalnızca o kategori grubundaki etkinlikleri bırakır.
List<Event> applyGroupFilter(List<Event> events, String? groupId) {
  if (groupId == null) return events;
  return events
      .where((event) => EventCategory.byId(event.category).group.id == groupId)
      .toList();
}
