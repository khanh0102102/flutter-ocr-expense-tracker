import 'package:flutter_test/flutter_test.dart';
import 'package:ocr_expense_tracker/features/scan/receipt_parser.dart';

void main() {
  final parser = ReceiptParser();

  test('parses merchant, labeled VND total and DD/MM/YYYY date', () {
    final receipt = parser.parse(
      'WINMART\nNgay mua: 08/10/2026\nTONG CONG: 150.000 đ',
    );

    expect(receipt.merchant, 'WINMART');
    expect(receipt.amount, 150000);
    expect(receipt.date, DateTime(2026, 10, 8));
  });

  test('parses comma-separated total with VND label', () {
    final receipt = parser.parse('STORE\nTOTAL: 150,000 VND');

    expect(receipt.amount, 150000);
  });

  test('parses currency amount without a total label', () {
    expect(parser.parse('STORE\n150.000 đ').amount, 150000);
    expect(parser.parse('STORE\n200000 ₫').amount, 200000);
  });

  test('parses ISO-style date', () {
    expect(
      parser.parse('STORE\nTOTAL: 200.000\n2026-10-08').date,
      DateTime(2026, 10, 8),
    );
  });

  test('rejects impossible dates', () {
    expect(parser.parse('STORE\n31/02/2026').date, isNull);
  });

  test('continues to a valid date after an invalid date', () {
    expect(
      parser.parse('STORE\n31/02/2026\n08/10/2026').date,
      DateTime(2026, 10, 8),
    );
  });
}
