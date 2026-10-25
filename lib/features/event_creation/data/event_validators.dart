/// Etkinlik alanı sınırları. firestore.rules ile aynı olmalı.
abstract final class EventLimits {
  static const int titleMin = 3;
  static const int titleMax = 80;
  static const int descriptionMax = 1000;
  static const int districtMax = 40;
  static const int addressMin = 3;
  static const int addressMax = 200;
  static const int capacityMin = 1;
  static const int capacityMax = 100;
}

/// Etkinlik formu doğrulayıcıları. Null dönerse alan geçerlidir.
abstract final class EventValidators {
  static String? title(String? value) {
    final text = value?.trim() ?? '';
    if (text.length < EventLimits.titleMin) {
      return 'Başlık en az ${EventLimits.titleMin} karakter olmalı.';
    }
    if (text.length > EventLimits.titleMax) {
      return 'Başlık en fazla ${EventLimits.titleMax} karakter olabilir.';
    }
    return null;
  }

  static String? description(String? value) {
    final text = value?.trim() ?? '';
    if (text.length > EventLimits.descriptionMax) {
      return 'Açıklama en fazla ${EventLimits.descriptionMax} karakter olabilir.';
    }
    return null;
  }

  static String? district(String? value) {
    final text = value?.trim() ?? '';
    if (text.length > EventLimits.districtMax) {
      return 'İlçe en fazla ${EventLimits.districtMax} karakter olabilir.';
    }
    return null;
  }

  static String? address(String? value) {
    final text = value?.trim() ?? '';
    if (text.length < EventLimits.addressMin) {
      return 'Buluşma adresini yaz.';
    }
    if (text.length > EventLimits.addressMax) {
      return 'Adres en fazla ${EventLimits.addressMax} karakter olabilir.';
    }
    return null;
  }

  /// [minCapacity]: düzenlemede, onaylı katılımcı sayısının altına inilemez.
  static String? capacity(String? value, {int minCapacity = 1}) {
    final parsed = int.tryParse(value?.trim() ?? '');
    if (parsed == null) return 'Kapasiteyi sayı olarak yaz.';
    final lowest =
        minCapacity > EventLimits.capacityMin ? minCapacity : EventLimits.capacityMin;
    if (parsed < lowest) {
      return lowest > EventLimits.capacityMin
          ? 'Kapasite, onaylanan $minCapacity kişinin altına düşemez.'
          : 'Kapasite en az ${EventLimits.capacityMin} olmalı.';
    }
    if (parsed > EventLimits.capacityMax) {
      return 'Kapasite en fazla ${EventLimits.capacityMax} olabilir.';
    }
    return null;
  }

  /// Başlangıç zamanı gelecekte olmalı. Düzenlemede değişmediyse eski değer kabul edilir.
  static String? startsAt(
    DateTime? value, {
    DateTime? unchangedFrom,
    DateTime? now,
  }) {
    if (value == null) return 'Tarih ve saat seç.';
    if (unchangedFrom != null && value.isAtSameMomentAs(unchangedFrom)) {
      return null;
    }
    if (!value.isAfter(now ?? DateTime.now())) {
      return 'Başlangıç zamanı gelecekte olmalı.';
    }
    return null;
  }
}
