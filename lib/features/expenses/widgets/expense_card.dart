import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/expense.dart';

class ExpenseCard extends StatelessWidget {
  const ExpenseCard({super.key, required this.expense});

  final Expense expense;

  @override
  Widget build(BuildContext context) {
    final thumbnail = expense.thumbnailPath;

    return Card(
      color: Colors.white,
      child: ListTile(
        leading: thumbnail == null
            ? const CircleAvatar(child: Icon(Icons.receipt_long))
            : ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  File(thumbnail),
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.receipt_long),
                ),
              ),
        title: Text(
          expense.merchant,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          '${expense.category} • ${formatDate(expense.date)}',
        ),
        trailing: Text(
          formatVnd(expense.amount),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}