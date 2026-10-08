# 2–3 Minute Demo Script

## 0:00–0:20 Dashboard
Show monthly, weekly and all-time totals, category donut and weekly bars.

## 0:20–0:50 Receipt capture
Open Scan Receipt. Demonstrate framing overlay, flash toggle, tap-to-focus and camera/gallery input.

## 0:50–1:30 OCR
Capture a Vietnamese receipt containing a merchant, TONG CONG: 150.000 đ and 08/10/2026. Show extracted fields and confidence chips.

## 1:30–1:50 Human review
Change one extracted field manually, choose a category and save. Explain that OCR is assistive and review is mandatory.

## 1:50–2:20 Transaction lifecycle
Open Expenses. Search a merchant, filter a category and swipe a transaction to delete.

## 2:20–2:50 Technical proof
Show the repository tree and explain:
Camera -> Crop -> ML Kit -> Regex -> Review -> SQLite -> CustomPainter
