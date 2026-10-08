# Architecture

## Runtime flow

Camera / Gallery
-> receipt framing crop
-> Google ML Kit Text Recognition
-> Regex heuristic parser
-> Review & manual correction
-> SQLite transaction
-> dashboard analytics

## Modules

- Presentation: Flutter pages/widgets.
- State: ExpenseStore owns UI-facing transaction state and derived totals.
- Repository: ExpenseRepository isolates SQL from widgets.
- Database: AppDatabase owns schema and indexes.
- OCR: ReceiptOcrService wraps ML Kit.
- Image pipeline: ImageCropService and ImageStorageService.
- Analytics: CategoryDonutChart and WeeklyBarChart render directly with CustomPainter.

## Reliability

OCR never writes directly to the database. Review is the human verification boundary.

Amounts are stored as integer VND. Receipt media is stored in application storage and referenced by file path.

The parser returns confidence values instead of pretending heuristic extraction is perfect.
