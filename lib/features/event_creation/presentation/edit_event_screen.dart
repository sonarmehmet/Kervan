import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../authentication/data/auth_repository.dart';
import '../../location/data/location_providers.dart';
import '../data/event_input.dart';
import '../data/event_repository.dart';
import 'event_form.dart';

class EditEventScreen extends ConsumerWidget {
  const EditEventScreen({super.key, required this.eventId});

  final String eventId;

  Future<void> _update(
    BuildContext context,
    WidgetRef ref,
    EventInput input,
  ) async {
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) return;
    final previous = ref.read(eventProvider(eventId)).valueOrNull?.imageUrl;
    await ref.read(eventRepositoryProvider).updateEvent(
          eventId,
          input,
          ownerId: uid,
          previousImageUrl: previous,
        );
    ref.invalidate(eventAddressProvider(eventId));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Etkinlik güncellendi.')),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventProvider(eventId));
    final addressAsync = ref.watch(eventAddressProvider(eventId));
    final uid = ref.watch(authStateProvider).valueOrNull?.uid;

    Widget body;
    final error = eventAsync.error ?? addressAsync.error;
    if (error != null) {
      body = ErrorView(
        message: mapErrorToMessage(error),
        onRetry: () {
          ref.invalidate(eventProvider(eventId));
          ref.invalidate(eventAddressProvider(eventId));
        },
      );
    } else if (eventAsync.isLoading || addressAsync.isLoading) {
      body = const LoadingView();
    } else {
      final event = eventAsync.valueOrNull;
      if (event == null) {
        body = const EmptyView(
          icon: Icons.event_busy,
          title: 'Etkinlik bulunamadı',
        );
      } else if (event.ownerId != uid) {
        body = const EmptyView(
          icon: Icons.lock_outline,
          title: 'Bu etkinliği düzenleme yetkin yok',
        );
      } else if (event.isCancelled) {
        body = const EmptyView(
          icon: Icons.event_busy,
          title: 'İptal edilmiş etkinlik düzenlenemez',
        );
      } else {
        body = SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: EventForm(
                  initial: event,
                  initialAddress: addressAsync.valueOrNull,
                  minCapacity: event.acceptedCount,
                  submitLabel: 'Kaydet',
                  onSubmit: (input) => _update(context, ref, input),
                ),
              ),
            ),
          ),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Etkinliği düzenle')),
      body: body,
    );
  }
}
