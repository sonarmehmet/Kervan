import 'package:cloud_firestore/cloud_firestore.dart';

/// `userStats/{uid}`: yalnızca toplamlar. Kimin puan verdiği hiçbir yerde tutulmaz/gösterilmez.
class UserStats {
  const UserStats({
    this.organizerSum = 0,
    this.organizerCount = 0,
    this.participantSum = 0,
    this.participantCount = 0,
  });

  static const UserStats empty = UserStats();

  /// Anonimliği korumak için ortalama, en az bu kadar puan olunca gösterilir
  /// (tek puanda puanı verenin kim olduğu tahmin edilebilir).
  static const int minRatingsToShow = 3;

  final int organizerSum;
  final int organizerCount;
  final int participantSum;
  final int participantCount;

  factory UserStats.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) return empty;
    int read(String key) => (data[key] as num?)?.toInt() ?? 0;
    return UserStats(
      organizerSum: read('organizerSum'),
      organizerCount: read('organizerCount'),
      participantSum: read('participantSum'),
      participantCount: read('participantCount'),
    );
  }

  /// Düzenleyen olarak ortalama; yeterli puan yoksa `null`.
  double? get organizerAverage => _average(organizerSum, organizerCount);

  /// Katılımcı olarak ortalama; yeterli puan yoksa `null`.
  double? get participantAverage => _average(participantSum, participantCount);

  static double? _average(int sum, int count) =>
      count >= minRatingsToShow ? sum / count : null;
}

/// "4.6" biçimi (Türkçe ondalık ayırıcı).
String formatRating(double value) => value.toStringAsFixed(1).replaceAll('.', ',');
