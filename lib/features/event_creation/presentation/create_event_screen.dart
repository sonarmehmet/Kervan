import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/router/route_names.dart';
import '../../authentication/data/auth_repository.dart';
import '../../profile/data/profile_repository.dart';
import '../../groups/data/group.dart';
import '../../groups/data/group_repository.dart';
import '../data/event_input.dart';
import '../data/event_repository.dart';
import 'event_form.dart';

class CreateEventScreen extends ConsumerWidget {
  const CreateEventScreen({super.key, this.initialGroupId});

  /// Grup sayfasından açıldıysa o grubun kimliği (formda önceden seçilir).
  final String? initialGroupId;

  Future<void> _create(
    BuildContext context,
    WidgetRef ref,
    EventInput input,
  ) async {
    final user = ref.read(authRepositoryProvider).currentUser;
    final profile = ref.read(currentProfileProvider).valueOrNull;
    if (user == null || profile == null) {
      throw const AppException('Profil bilgin yüklenemedi. Lütfen tekrar dene.');
    }
    final eventId = await ref.read(eventRepositoryProvider).createEvent(
          ownerId: user.uid,
          ownerName: profile.displayName,
          input: input,
        );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Etkinliğin oluşturuldu.')),
    );
    context.pushReplacement(RoutePaths.eventDetails(eventId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ownedGroups = ref.watch(ownedGroupsProvider).valueOrNull ?? const <Group>[];
    return Scaffold(
      appBar: AppBar(title: const Text('Etkinlik oluştur')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: EventForm(
                ownedGroups: ownedGroups,
                initialGroupId: initialGroupId,
                submitLabel: 'Etkinliği oluştur',
                onSubmit: (input) => _create(context, ref, input),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
