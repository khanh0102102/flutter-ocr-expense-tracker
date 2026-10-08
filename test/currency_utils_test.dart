import 'package:flutter_test/flutter_test.dart';
import 'package:ocr_expense_tracker/core/utils/currency_utils.dart';
void main(){test('formats VND',(){expect(formatVnd(150000),'150.000 ₫');});test('parses separators',(){expect(parseIntegerAmount('150.000 đ'),150000);expect(parseIntegerAmount('150,000 VND'),150000);});}
