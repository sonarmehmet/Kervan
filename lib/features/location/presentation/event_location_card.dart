import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../event_details/data/event.dart';
import '../data/location_providers.dart';

/// Etkinlik konumu kartı. Herkes şehir/ilçeyi görür; tam adresi yalnızca
/// etkinlik sahibi ve onaylı katılımcılar görür ([canViewAddress]).
class EventLocationCard extends ConsumerWidget {
  const EventLocationCard({
    super.key,
    required this.event,
    required this.canViewAddress,
  });

  final Event event;
  final bool canViewAddress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final String detail;
    if (!canViewAddress) {
      detail = 'Tam adres, katılımın onaylandıktan sonra görünür.';
    } else {
      final address = ref.watch(eventAddressProvider(event.id));
      detail = address.when(
        loading: () => 'Adres yükleniyor...',
        error: (_, __) => 'Adres yüklenemedi.',
        data: (value) => (value == null || value.isEmpty)
            ? 'Adres girilmemiş.'
            : value,
      );
    }

    return Card(
      child: ListTile(
        leading: Icon(Icons.location_on, color: theme.colorScheme.primary),
        title: Text(event.locationLabel),
        subtitle: Text(detail),
      ),
    );
  }
}
