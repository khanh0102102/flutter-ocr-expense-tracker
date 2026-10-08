String formatVnd(int amount) {
  final sign = amount < 0 ? '-' : '';
  final digits = amount.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return sign + buffer.toString() + ' ₫';
}
int parseIntegerAmount(String value) => int.tryParse(value.replaceAll(RegExp(r'\D'), '')) ?? 0;
