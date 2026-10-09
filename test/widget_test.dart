import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ocr_expense_tracker/data/models/expense.dart';
import 'package:ocr_expense_tracker/widgets/charts/category_donut_chart.dart';

void main() {
  testWidgets('category donut chart displays category totals', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CategoryDonutChart(
            data: [
              CategoryTotal(category: 'Food', amount: 150000),
              CategoryTotal(category: 'Study', amount: 50000),
            ],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Study'), findsOneWidget);
    expect(find.text('200.000 ₫'), findsOneWidget);
  });
}
