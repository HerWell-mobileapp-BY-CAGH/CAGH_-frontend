class NameFormatter {
  static String format(String? rawName) {
    if (rawName == null || rawName.trim().isEmpty) return 'Care Participant';
    var s = rawName.trim();
    if (s.contains('@')) s = s.split('@')[0];
    s = s.replaceAll(RegExp(r'[_ ]?[0-9a-f]{5,}$', caseSensitive: false), '');
    s = s.replaceAll('_', ' ').replaceAll('.', ' ');
    final words = s.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return 'Care Participant';
    return words.map((w) => '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}').join(' ');
  }
}
