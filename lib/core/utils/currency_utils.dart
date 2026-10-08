String formatVnd(int amount) {
  final sign = amount < 0 ? '-' : '';
  final digits = amount.abs().toString();
  final buffer = StringBuffer();

  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(digits[index]);
  }

  return '$sign$buffer ₫';
}

int parseIntegerAmount(String value) {
  final digits = value.replaceAll(RegExp(r'\D'), '');
  return int.tryParse(digits) ?? 0;
}