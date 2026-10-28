import 'dart:typed_data';

import 'recurrence.dart';

/// Etkinlik formundan gelen değerler (oluşturma ve düzenleme için ortak).
class EventInput {
  const EventInput({
    required this.title,
    required this.description,
    required this.category,
    required this.city,
    required this.district,
    required this.startsAt,
    required this.capacity,
    required this.address,
    this.recurrence = Recurrence.none,
    this.occurrences = 1,
    this.groupId,
    this.groupName,
    this.durationMinutes,
    this.costNote = '',
    this.terms = '',
    this.imageUrl,
    this.newImage,
  });

  final String title;
  final String description;
  final String category;
  final String city;
  final String district;
  final DateTime startsAt;
  final int capacity;

  /// Tam adres: yalnızca sahip ve onaylı katılımcılar görür (`private/location`).
  final String address;

  /// Yalnızca oluşturmada: tekrar kuralı ve toplam etkinlik sayısı.
  final Recurrence recurrence;
  final int occurrences;

  /// Yalnızca oluşturmada: etkinliğin ait olduğu grup (grup sahibi seçebilir).
  final String? groupId;
  final String? groupName;

  final int? durationMinutes;
  final String costNote;
  final String terms;

  /// Korunacak mevcut fotoğraf bağlantısı (düzenlemede). `null` ve [newImage] yoksa fotoğraf kalkar.
  final String? imageUrl;

  /// Yeni seçilen fotoğraf (JPEG baytları). Varsa yüklenir ve [imageUrl] yerine geçer.
  final Uint8List? newImage;
}
