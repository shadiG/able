extension IntFormatExtension on int {
  /// `1234567` → `1,234,567`.
  String get withThousandsSeparators => toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (_) => ',',
      );
}
