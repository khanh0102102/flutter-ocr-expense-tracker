import 'dart:io';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/expense.dart';
import '../../data/services/image_storage_service.dart';
import '../../state/expense_store.dart';
import 'receipt_parser.dart';

class ReviewPage extends StatefulWidget {
  const ReviewPage({
    super.key,
    required this.store,
    this.imageFile,
    required this.rawText,
    required this.parsed,
  });

  final ExpenseStore store;
  final File? imageFile;
  final String rawText;
  final ParsedReceipt parsed;

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  final _uuid = const Uuid();

  late final TextEditingController _merchant;
  late final TextEditingController _amount;
  late final TextEditingController _notes;
  late DateTime _date;
  late ExpenseCategory _category;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _merchant = TextEditingController(text: widget.parsed.merchant ?? '');
    _amount = TextEditingController(
      text: widget.parsed.amount?.toString() ?? '',
    );
    _notes = TextEditingController();
    _date = widget.parsed.date ?? DateTime.now();
    _category = ExpenseCategory.food;
  }

  @override
  void dispose() {
    _merchant.dispose();
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final merchant = _merchant.text.trim();
    final amount = int.tryParse(
      _amount.text.replaceAll(RegExp(r'\D'), ''),
    );

    if (merchant.length < 2) {
      _msg('Merchant name is required.');
      return;
    }

    if (amount == null || amount <= 0) {
      _msg('Enter a valid VND amount.');
      return;
    }

    setState(() => _saving = true);

    try {
      final id = _uuid.v4();
      String? imagePath;
      String? thumbnailPath;

      if (widget.imageFile != null) {
        (imagePath, thumbnailPath) = await ImageStorageService.persist(
          widget.imageFile!,
          id,
        );
      }

      final now = DateTime.now();
      await widget.store.save(
        Expense(
          id: id,
          merchant: merchant,
          amount: amount,
          date: _date,
          category: _category.label,
          notes: _notes.text.trim(),
          rawText: widget.rawText,
          imagePath: imagePath,
          thumbnailPath: thumbnailPath,
          createdAt: now,
          updatedAt: now,
        ),
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (error) {
      _msg('Save failed: ${error.toString()});
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _msg(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review receipt')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (widget.imageFile != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.file(
                widget.imageFile!,
                height: 210,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 18),
          const Text(
            'Verify extracted details',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _chip('Merchant', widget.parsed.merchantConfidence),
              _chip('Amount', widget.parsed.amountConfidence),
              _chip('Date', widget.parsed.dateConfidence),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _merchant,
            decoration: const InputDecoration(
              labelText: 'Merchant',
              prefixIcon: Icon(Icons.storefront),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amount,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Amount (VND)',
              prefixIcon: Icon(Icons.payments),
            ),
          ),
          const SizedBox(height: 12),
          InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Date',
              prefixIcon: Icon(Icons.event),
            ),
            child: InkWell(
              onTap: () async {
                final selected = await showDatePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  initialDate: _date,
                );
                if (selected != null) {
                  setState(() => _date = selected);
                }
              },
              child: Text(formatDate(_date)),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<ExpenseCategory>(
            initialValue: _category,
            decoration: const InputDecoration(
              labelText: 'Category',
              prefixIcon: Icon(Icons.category),
            ),
            items: ExpenseCategory.values
                .map(
                  (category) => DropdownMenuItem(
                    value: category,
                    child: Text(category.label),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _category = value);
              }
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notes,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Notes'),
          ),
          const SizedBox(height: 12),
          ExpansionTile(
            title: const Text('Raw OCR text'),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: SelectableText(widget.rawText),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: Text(_saving ? 'Saving...' : 'Save expense'),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, double value) {
    if (value == 0) {
      return const SizedBox.shrink();
    }
    return Chip(label: Text('$label ${(value * 100).round()}%'));
  }
}