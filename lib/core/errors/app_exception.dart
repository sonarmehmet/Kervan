/// Kullanıcıya olduğu gibi gösterilebilecek (Türkçe) mesaj taşıyan uygulama hatası.
class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => 'AppException: $message';
}
