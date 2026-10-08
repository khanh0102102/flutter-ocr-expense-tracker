import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/date_utils.dart';
import '../data/models/expense.dart';
import '../data/repositories/expense_repository.dart';

class ExpenseStore extends ChangeNotifier {
  ExpenseStore(this._repository);
  final ExpenseRepository _repository;
  List<Expense> _expenses=[]; bool _loading=false; String? _error;
  List<Expense> get expenses=>List.unmodifiable(_expenses);
  bool get loading=>_loading; String? get error=>_error;
  Future<void> initialize()=>reload();
  Future<void> reload() async { _loading=true;_error=null;notifyListeners();try{_expenses=await _repository.findAll();}catch(e){_error=e.toString();}finally{_loading=false;notifyListeners();}}
  Future<void> save(Expense e,{Expense? previous}) async {if(previous==null){await _repository.insert(e);}else{await _repository.update(e);}await reload();}
  Future<void> remove(Expense e) async {await _repository.delete(e.id);_expenses=_expenses.where((x)=>x.id!=e.id).toList();notifyListeners();}
  Future<void> clearAll() async {await _repository.deleteAll();_expenses=[];notifyListeners();}
  int get totalSpent=>_expenses.fold(0,(s,e)=>s+e.amount);
  int get thisMonthSpent=>_sumFrom(startOfMonth(DateTime.now()));
  int get thisWeekSpent=>_sumFrom(startOfDay(DateTime.now()).subtract(Duration(days:DateTime.now().weekday-1)));
  int _sumFrom(DateTime start)=>_expenses.where((e)=>!e.date.isBefore(start)).fold(0,(s,e)=>s+e.amount);
  List<CategoryTotal> get categoryTotals{final m=<String,int>{};for(final e in _expenses)m.update(e.category,(v)=>v+e.amount,ifAbsent:()=>e.amount);return m.entries.map((e)=>CategoryTotal(category:e.key,amount:e.value)).toList()..sort((a,b)=>b.amount.compareTo(a.amount));}
  List<DailyTotal> get lastSevenDays{final t=startOfDay(DateTime.now());return List.generate(7,(i){final d=t.subtract(Duration(days:6-i));final a=_expenses.where((e)=>e.date.year==d.year&&e.date.month==d.month&&e.date.day==d.day).fold(0,(s,e)=>s+e.amount);return DailyTotal(date:d,amount:a);});}
  String get defaultCategory=>ExpenseCategory.food.label;
}
