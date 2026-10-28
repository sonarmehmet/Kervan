import 'package:flutter/material.dart';

import '../theme/rota_colors.dart';

/// Etkinlik kartlarının köşesindeki sarı yuvarlak tarih rozeti: gün, ay ve saat.
class DateBadge extends StatelessWidget {
  const DateBadge({super.key, required this.date, this.size = 60});

  final DateTime date;
  final double size;

  static const List<String> _months = <String>[
    'OCA', 'ŞUB', 'MAR', 'NİS', 'MAY', 'HAZ', 'TEM', 'AĞU', 'EYL', 'EKİ', 'KAS', 'ARA',
  ];

  static String monthLabel(DateTime date) => _months[date.toLocal().month - 1];

  @override
  Widget build(BuildContext context) {
    final local = date.toLocal();
    final time =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    const ink = RotaColors.ink;
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(color: RotaColors.sun, shape: BoxShape.circle),
      padding: EdgeInsets.all(size * 0.1),
      child: FittedBox(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${local.day}',
              style: const TextStyle(color: ink, fontSize: 22, fontWeight: FontWeight.w900, height: 1.05),
            ),
            Text(
              monthLabel(local),
              style: const TextStyle(color: ink, fontSize: 11, fontWeight: FontWeight.w800, height: 1.1),
            ),
            Text(
              time,
              style: const TextStyle(color: ink, fontSize: 10, fontWeight: FontWeight.w700, height: 1.1),
            ),
          ],
        ),
      ),
    );
  }
}
