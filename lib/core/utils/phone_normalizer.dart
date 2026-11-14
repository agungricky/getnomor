class PhoneNormalizer {
  static final RegExp _candidatePattern = RegExp(
    r'(?<!\d)(?:\+62|62|0)[0-9\s().-]{8,18}',
  );

  static String? normalize(String input) {
    var value = input.trim().replaceAll(RegExp(r'[^0-9+]'), '');
    if (value.startsWith('+')) value = value.substring(1);
    if (value.startsWith('0')) {
      value = '62${value.substring(1)}';
    } else if (!value.startsWith('62')) {
      return null;
    }
    if (!RegExp(r'^628\d{7,12}$').hasMatch(value)) return null;
    return value;
  }

  static List<String> extract(String text) {
    final found = <String>{};
    for (final match in _candidatePattern.allMatches(text)) {
      final normalized = normalize(match.group(0)!);
      if (normalized != null) found.add(normalized);
    }
    return found.toList();
  }
}
