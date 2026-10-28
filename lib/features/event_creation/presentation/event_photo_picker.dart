import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/event_validators.dart';

/// Etkinlik fotoğrafı seçici: 16:9 önizleme, ekle, değiştir ve kaldır.
class EventPhotoPicker extends StatelessWidget {
  const EventPhotoPicker({
    super.key,
    required this.existingUrl,
    required this.newImage,
    required this.onPicked,
    required this.onRemoved,
  });

  /// Düzenlemede mevcut fotoğraf bağlantısı.
  final String? existingUrl;

  /// Yeni seçilen fotoğraf baytları.
  final Uint8List? newImage;
  final ValueChanged<Uint8List> onPicked;
  final VoidCallback onRemoved;

  bool get _hasImage => newImage != null || (existingUrl != null && existingUrl!.isNotEmpty);

  Future<void> _pick(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 82,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.length > EventLimits.imageMaxBytes) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Fotoğraf çok büyük. 3 MB altında bir görsel seç.')),
        );
        return;
      }
      onPicked(bytes);
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Fotoğraf seçilemedi. Tekrar dene.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(22);
    Widget content;
    if (newImage != null) {
      content = Image.memory(newImage!, fit: BoxFit.cover);
    } else if (existingUrl != null && existingUrl!.isNotEmpty) {
      content = Image.network(
        existingUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image_outlined)),
      );
    } else {
      content = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate_outlined, size: 40, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 8),
          Text('Kapak fotoğrafı ekle', style: theme.textTheme.titleSmall),
          Text(
            'İsteğe bağlı, ama fotoğraflı etkinlikler daha çok ilgi görür.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      );
    }
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: ClipRRect(
            borderRadius: radius,
            child: Material(
              color: theme.colorScheme.surfaceContainer,
              child: InkWell(
                onTap: () => _pick(context),
                child: SizedBox.expand(child: content),
              ),
            ),
          ),
        ),
        if (_hasImage)
          Positioned(
            top: 8,
            right: 8,
            child: Row(
              children: [
                IconButton.filledTonal(
                  tooltip: 'Fotoğrafı değiştir',
                  onPressed: () => _pick(context),
                  icon: const Icon(Icons.edit_outlined),
                ),
                const SizedBox(width: 4),
                IconButton.filledTonal(
                  tooltip: 'Fotoğrafı kaldır',
                  onPressed: onRemoved,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
