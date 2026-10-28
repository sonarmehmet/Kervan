import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../event_details/data/event.dart';
import '../data/location_providers.dart';

/// Etkinlik konumu kartı. Herkes şehir/ilçeyi görür; tam adresi yalnızca
/// etkinlik sahibi ve onaylı katılımcılar görür ([canViewAddress]).
/// Adres görünüyorsa harita uygulamasında açma düğmesi çıkar (API anahtarı gerekmez).
class EventLocationCard extends ConsumerWidget {
  const EventLocationCard({
    super.key,
    required this.event,
    required this.canViewAddress,
  });

  final Event event;
  final bool canViewAddress;

  Future<void> _openMap(BuildContext context, String query) async {
    final uri = Uri.https('www.google.com', '/maps/search/', <String, String>{
      'api': '1',
      'query': query,
    });
    var opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harita uygulaması açılamadı.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    String detail;
    String? mapQuery;

    if (!canViewAddress) {
      detail = 'Tam adres, katılımın onaylandıktan sonra görünür.';
    } else {
      final address = ref.watch(eventAddressProvider(event.id));
      detail = address.when(
        loading: () => 'Adres yükleniyor...',
        error: (_, __) => 'Adres yüklenemedi.',
        data: (value) =>
            (value == null || value.isEmpty) ? 'Adres girilmemiş.' : value,
      );
      final value = address.valueOrNull;
      if (value != null && value.isNotEmpty) {
        mapQuery = '$value, ${event.locationLabel}';
      }
    }

    final query = mapQuery;
    return Card(
      child: ListTile(
        leading: Icon(Icons.location_on, color: theme.colorScheme.primary),
        title: Text(event.locationLabel),
        subtitle: Text(detail),
        trailing: query == null
            ? null
            : IconButton(
                tooltip: 'Haritada aç',
                icon: const Icon(Icons.map_outlined),
                onPressed: () => _openMap(context, query),
              ),
      ),
    );
  }
}
