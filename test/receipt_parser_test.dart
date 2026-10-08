import 'package:flutter_test/flutter_test.dart';
import 'package:ocr_expense_tracker/features/scan/receipt_parser.dart';
void main(){final p=ReceiptParser();test('parses receipt',(){final r=p.parse('WINMART\nNgay mua: 08/10/2026\nTONG CONG: 150.000 đ');expect(r.merchant,'WINMART');expect(r.amount,150000);expect(r.date,DateTime(2026,10,8));});test('rejects invalid date',(){expect(p.parse('STORE\nTOTAL: 200.000\n31/02/2026').date,isNull);});}
