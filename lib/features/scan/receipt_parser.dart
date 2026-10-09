import '../../core/utils/currency_utils.dart';

class ParsedReceipt {
  const ParsedReceipt({
    this.merchant,
    this.amount,
    this.date,
    this.merchantConfidence = 0,
    this.amountConfidence = 0,
    this.dateConfidence = 0,
  });

  final String? merchant;
  final int? amount;
  final DateTime? date;
  final double merchantConfidence;
  final double amountConfidence;
  final double dateConfidence;

  bool get hasAnyValue => merchant != null || amount != null || date != null;
}

class ReceiptParser {
  static final _date =
      RegExp(r'\b([0-3]?\d)[/.-]([01]?\d)[/.-](20\d{2})\b');
  static final _iso =
      RegExp(r'\b(20\d{2})[/.-]([01]?\d)[/.-]([0-3]?\d)\b');

  static final _total = RegExp(
    r'(?:TỔNG\s*(?:CỘNG|TIỀN)|TONG\s*(?:CONG|TIEN)|GRAND\s*TOTAL|TOTAL|THANH\s*TOÁN|THANH\s*TOAN|AMOUNT\s*DUE)\s*[:\-]?\s*([0-9][0-9., ]{2,})',
    caseSensitive: false,
  );

  // Avoid \b after currency symbols such as "đ" and "₫": they are
  // non-word characters, so a word-boundary assertion can reject valid values.
  static final _money = RegExp(
    r'([0-9]{1,3}(?:[.,][0-9]{3})+|[0-9]{4,9})\s*(?:VND|VNĐ|đ|₫)(?![A-Za-zÀ-ỹ])',
    caseSensitive: false,
  );

  ParsedReceipt parse(String text) {
    final lines = text
        .replaceAll('\r', '')
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    String? merchant;
    var merchantConfidence = 0.0;
    for (final line in lines.take(8)) {
      if (line.length < 3 || line.length > 60) continue;

      final upper = line.toUpperCase();
      const ignoredLabels = [
        'HÓA ĐƠN',
        'HOA DON',
        'INVOICE',
        'RECEIPT',
        'TOTAL',
        'TỔNG',
        'DATE',
        'TIME',
        'VAT',
        'TEL',
      ];
      if (ignoredLabels.any(upper.contains)) continue;
      if (RegExp(r'^\d[\d\s.,:/-]*$').hasMatch(line)) continue;

      if (RegExp(r'[A-Za-zÀ-ỹ]').hasMatch(line)) {
        merchant = line.replaceAll(RegExp(r'\s+'), ' ');
        merchantConfidence = 0.55;
        break;
      }
    }

    int? amount;
    var amountConfidence = 0.0;
    final labeledTotal = _total.firstMatch(text);
    if (labeledTotal != null) {
      final value = parseIntegerAmount(labeledTotal.group(1)!);
      if (value > 0) {
        amount = value;
        amountConfidence = 0.95;
      }
    }

    if (amount == null) {
      for (final match in _money.allMatches(text)) {
        final value = parseIntegerAmount(match.group(1)!);
        if (value > 0) {
          amount = value;
          amountConfidence = 0.78;
          break;
        }
      }
    }

    DateTime? date;
    var dateConfidence = 0.0;

    // Skip invalid date matches and keep looking for a valid one.
    for (final match in _date.allMatches(text)) {
      final candidate = _safe(
        int.parse(match.group(3)!),
        int.parse(match.group(2)!),
        int.parse(match.group(1)!),
      );
      if (candidate != null) {
        date = candidate;
        dateConfidence = 0.92;
        break;
      }
    }

    if (date == null) {
      for (final match in _iso.allMatches(text)) {
        final candidate = _safe(
          int.parse(match.group(1)!),
          int.parse(match.group(2)!),
          int.parse(match.group(3)!),
        );
        if (candidate != null) {
          date = candidate;
          dateConfidence = 0.88;
          break;
        }
      }
    }

    return ParsedReceipt(
      merchant: merchant,
      amount: amount,
      date: date,
      merchantConfidence: merchantConfidence,
      amountConfidence: amountConfidence,
      dateConfidence: dateConfidence,
    );
  }

  DateTime? _safe(int year, int month, int day) {
    final value = DateTime(year, month, day);
    if (value.year != year || value.month != month || value.day != day) {
      return null;
    }
    return value;
  }
}
