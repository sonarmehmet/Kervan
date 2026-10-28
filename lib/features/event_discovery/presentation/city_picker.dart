import 'package:flutter/material.dart';

import '../../../core/constants/turkey_cities.dart';
import '../../../core/utils/text_search.dart';

/// Şehir seçici alt sayfa (aranabilir). Seçilen şehri döner; "Tüm şehirler" için boş metin `''`.
/// Vazgeçilirse `null` döner.
Future<String?> showCityPicker(BuildContext context, {String? selected}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _CityPicker(selected: selected),
  );
}

class _CityPicker extends StatefulWidget {
  const _CityPicker({this.selected});

  final String? selected;

  @override
  State<_CityPicker> createState() => _CityPickerState();
}

class _CityPickerState extends State<_CityPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final cities = TurkeyCities.all.where((c) => matchesSearch(_query, [c])).toList();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: TextField(
                autofocus: false,
                onChanged: (value) => setState(() => _query = value),
                decoration: const InputDecoration(
                  hintText: 'Şehir ara',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  if (_query.trim().isEmpty)
                    ListTile(
                      leading: const Icon(Icons.public),
                      title: const Text('Tüm şehirler'),
                      trailing: widget.selected == null ? const Icon(Icons.check) : null,
                      onTap: () => Navigator.of(context).pop(''),
                    ),
                  for (final city in cities)
                    ListTile(
                      leading: const Icon(Icons.location_city),
                      title: Text(city),
                      trailing: widget.selected == city ? const Icon(Icons.check) : null,
                      onTap: () => Navigator.of(context).pop(city),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
