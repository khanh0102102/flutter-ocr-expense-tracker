class Expense {
  const Expense({required this.id, required this.merchant, required this.amount, required this.date, required this.category, required this.notes, required this.rawText, required this.imagePath, required this.thumbnailPath, required this.createdAt, required this.updatedAt});
  final String id, merchant, category, notes, rawText;
  final int amount;
  final DateTime date, createdAt, updatedAt;
  final String? imagePath, thumbnailPath;
  Expense copyWith({String? merchant, int? amount, DateTime? date, String? category, String? notes, String? rawText, String? imagePath, String? thumbnailPath, DateTime? updatedAt}) => Expense(
    id:id, merchant:merchant??this.merchant, amount:amount??this.amount, date:date??this.date,
    category:category??this.category, notes:notes??this.notes, rawText:rawText??this.rawText,
    imagePath:imagePath??this.imagePath, thumbnailPath:thumbnailPath??this.thumbnailPath, createdAt:createdAt, updatedAt:updatedAt??this.updatedAt);
  Map<String,Object?> toMap()=>{'id':id,'merchant':merchant,'amount':amount,'date':date.toIso8601String(),'category':category,'notes':notes,'raw_text':rawText,'image_path':imagePath,'thumbnail_path':thumbnailPath,'created_at':createdAt.toIso8601String(),'updated_at':updatedAt.toIso8601String()};
  factory Expense.fromMap(Map<String,Object?> m)=>Expense(id:m['id']! as String,merchant:m['merchant']! as String,amount:m['amount']! as int,date:DateTime.parse(m['date']! as String),category:m['category']! as String,notes:(m['notes']??'') as String,rawText:(m['raw_text']??'') as String,imagePath:m['image_path'] as String?,thumbnailPath:m['thumbnail_path'] as String?,createdAt:DateTime.parse(m['created_at']! as String),updatedAt:DateTime.parse(m['updated_at']! as String));
}
class CategoryTotal { const CategoryTotal({required this.category,required this.amount}); final String category; final int amount; }
class DailyTotal { const DailyTotal({required this.date,required this.amount}); final DateTime date; final int amount; }
