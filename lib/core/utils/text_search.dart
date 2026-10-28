/// Türkçe harfleri sadeleştirir ve küçültür: "İstanbul" ve "istanbul", "Çay" ve "cay" eşleşir.
String foldTr(String input) {
  final buffer = StringBuffer();
  for (final rune in input.runes) {
    final char = String.fromCharCode(rune);
    switch (char) {
      case 'İ':
      case 'I':
      case 'ı':
        buffer.write('i');
      case 'Ç':
      case 'ç':
        buffer.write('c');
      case 'Ğ':
      case 'ğ':
        buffer.write('g');
      case 'Ö':
      case 'ö':
        buffer.write('o');
      case 'Ş':
      case 'ş':
        buffer.write('s');
      case 'Ü':
      case 'ü':
      case 'Û':
      case 'û':
        buffer.write('u');
      case 'Â':
      case 'â':
        buffer.write('a');
      case 'Î':
      case 'î':
        buffer.write('i');
      default:
        buffer.write(char.toLowerCase());
    }
  }
  return buffer.toString();
}

/// Sorgudaki her sözcük alanlardan en az birinde geçiyorsa `true`.
/// Boş sorgu her şeyle eşleşir.
bool matchesSearch(String query, Iterable<String> fields) {
  final tokens = foldTr(query)
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .toList();
  if (tokens.isEmpty) return true;
  final haystack = fields.map(foldTr).join(' ');
  return tokens.every(haystack.contains);
}
