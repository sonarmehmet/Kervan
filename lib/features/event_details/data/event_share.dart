import '../../../core/config/app_config.dart';
import '../../../core/utils/date_formatters.dart';
import 'event.dart';

/// Etkinlik paylaşım metni. Yalnızca herkese açık bilgiler (tam adres ASLA paylaşılmaz).
/// [baseUrl] doluysa (`--dart-define=SHARE_BASE_URL=...`) etkinlik bağlantısı eklenir.
String buildShareText(Event event, {String baseUrl = AppConfig.shareBaseUrl}) {
  final lines = <String>[
    '${event.title}',
    '${DateFormatters.eventDateTime(event.startsAt)} · ${event.locationLabel}',
    'Rota\'da birlikte katılalım!',
  ];
  final link = eventLink(event.id, baseUrl: baseUrl);
  if (link != null) lines.add(link);
  return lines.join('\n');
}

/// Etkinlik bağlantısı; taban adres yoksa `null`.
String? eventLink(String eventId, {String baseUrl = AppConfig.shareBaseUrl}) {
  final base = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
  if (base.isEmpty) return null;
  return '$base/events/$eventId';
}

String _utcStamp(DateTime time) {
  final t = time.toUtc();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${t.year.toString().padLeft(4, '0')}${two(t.month)}${two(t.day)}'
      'T${two(t.hour)}${two(t.minute)}${two(t.second)}Z';
}

/// Google Takvim "etkinlik ekle" bağlantısı (ek eklenti gerekmez). Konum olarak yalnızca
/// herkese açık şehir/ilçe yazılır; tam adres takvime konmaz.
Uri calendarUri(
  Event event, {
  Duration duration = const Duration(hours: 2),
  String baseUrl = AppConfig.shareBaseUrl,
}) {
  final link = eventLink(event.id, baseUrl: baseUrl);
  final details = <String>[
    if (event.description.isNotEmpty) event.description,
    'Düzenleyen: ${event.ownerName}',
    if (link != null) link,
  ].join('\n\n');
  return Uri.https('calendar.google.com', '/calendar/render', <String, String>{
    'action': 'TEMPLATE',
    'text': event.title,
    'dates': '${_utcStamp(event.startsAt)}/${_utcStamp(event.startsAt.add(duration))}',
    'details': details,
    'location': event.locationLabel,
  });
}
