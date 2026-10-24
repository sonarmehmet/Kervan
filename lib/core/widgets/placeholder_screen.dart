import 'package:flutter/material.dart';

import 'empty_view.dart';

/// Henüz yazılmamış ekranlar için geçici yer tutucu.
/// İlgili özellik (B veya C) hazır olunca router'daki satır gerçek ekranla değiştirilir.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    super.key,
    required this.title,
    this.owner,
    this.showAppBar = true,
  });

  final String title;

  /// Bu ekranı yazacak ekip: 'A', 'B' veya 'C'.
  final String? owner;
  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showAppBar ? AppBar(title: Text(title)) : null,
      body: EmptyView(
        icon: Icons.construction,
        title: '$title yakında',
        message: owner == null ? null : 'Bu ekran $owner bölümünde yazılacak.',
      ),
    );
  }
}
