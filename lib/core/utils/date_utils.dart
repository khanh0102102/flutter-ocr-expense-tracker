String formatDate(DateTime date) => date.day.toString().padLeft(2,'0') + '/' + date.month.toString().padLeft(2,'0') + '/' + date.year.toString();
DateTime startOfDay(DateTime date) => DateTime(date.year, date.month, date.day);
DateTime startOfMonth(DateTime date) => DateTime(date.year, date.month);
