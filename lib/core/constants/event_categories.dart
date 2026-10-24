import 'package:flutter/material.dart';

/// Etkinlik kategorisi. `id` Firestore'a yazılan değerdir, DEĞİŞTİRME.
/// Profildeki ilgi alanları da aynı kimlikleri kullanır.
class EventCategory {
  const EventCategory(this.id, this.label, this.icon);

  final String id;
  final String label;
  final IconData icon;

  static const EventCategory sport =
      EventCategory('sport', 'Spor', Icons.sports_soccer);
  static const EventCategory yoga =
      EventCategory('yoga', 'Yoga', Icons.self_improvement);
  static const EventCategory walking =
      EventCategory('walking', 'Yürüyüş', Icons.directions_walk);
  static const EventCategory hiking =
      EventCategory('hiking', 'Doğa yürüyüşü', Icons.hiking);
  static const EventCategory cycling =
      EventCategory('cycling', 'Bisiklet', Icons.directions_bike);
  static const EventCategory coffee =
      EventCategory('coffee', 'Kahve ve sohbet', Icons.local_cafe);
  static const EventCategory games =
      EventCategory('games', 'Oyun', Icons.sports_esports);
  static const EventCategory music =
      EventCategory('music', 'Müzik', Icons.music_note);
  static const EventCategory art =
      EventCategory('art', 'Sanat', Icons.palette);
  static const EventCategory learning =
      EventCategory('learning', 'Öğrenme', Icons.school);
  static const EventCategory volunteering =
      EventCategory('volunteering', 'Gönüllülük', Icons.volunteer_activism);
  static const EventCategory other =
      EventCategory('other', 'Diğer', Icons.category);

  static const List<EventCategory> all = <EventCategory>[
    sport,
    yoga,
    walking,
    hiking,
    cycling,
    coffee,
    games,
    music,
    art,
    learning,
    volunteering,
    other,
  ];

  /// Bilinmeyen kimlikte `other` döner (eski/hatalı veriye karşı güvenli).
  static EventCategory byId(String id) {
    for (final category in all) {
      if (category.id == id) return category;
    }
    return other;
  }

  static bool isValidId(String id) => all.any((category) => category.id == id);
}
