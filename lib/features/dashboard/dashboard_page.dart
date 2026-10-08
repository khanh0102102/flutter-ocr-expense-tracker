import 'package:flutter/material.dart';
import '../../core/utils/currency_utils.dart';
import '../../state/expense_store.dart';
import '../../widgets/charts/category_donut_chart.dart';
import '../../widgets/charts/weekly_bar_chart.dart';
import '../scan/camera_page.dart';
import '../expenses/widgets/expense_card.dart';

class DashboardPage extends StatelessWidget{
 const DashboardPage({super.key,required this.store,this.onOpenExpenses});final ExpenseStore store;final VoidCallback? onOpenExpenses;
 @override Widget build(BuildContext context){final recent=store.expenses.take(5).toList();return SafeArea(child:RefreshIndicator(onRefresh:store.reload,child:ListView(padding:const EdgeInsets.fromLTRB(20,18,20,120),children:[
 Row(children:[Expanded(child:Text('Your finances',style:Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight:FontWeight.w900))),IconButton(onPressed:()=>_scan(context),icon:const Icon(Icons.document_scanner_outlined))]),
 Text('Offline-first • OCR on device'),const SizedBox(height:20),_summary(context,'This month',store.thisMonthSpent,Icons.calendar_month),const SizedBox(height:12),
 Row(children:[Expanded(child:_mini(context,'This week',store.thisWeekSpent,Icons.date_range)),const SizedBox(width:12),Expanded(child:_mini(context,'All time',store.totalSpent,Icons.wallet))]),
 const SizedBox(height:26),const Text('Category distribution',style:TextStyle(fontSize:20,fontWeight:FontWeight.w800)),const SizedBox(height:10),
 Card(color:Colors.white,child:Padding(padding:const EdgeInsets.all(18),child:CategoryDonutChart(data:store.categoryTotals))),const SizedBox(height:26),
 const Text('Last 7 days',style:TextStyle(fontSize:20,fontWeight:FontWeight.w800)),const SizedBox(height:10),Card(color:Colors.white,child:Padding(padding:const EdgeInsets.all(18),child:WeeklyBarChart(data:store.lastSevenDays))),
 const SizedBox(height:26),Row(children:[const Expanded(child:Text('Recent expenses',style:TextStyle(fontSize:20,fontWeight:FontWeight.w800))),TextButton(onPressed:onOpenExpenses,child:const Text('See all'))]),
 if(recent.isEmpty)Card(color:Theme.of(context).colorScheme.secondaryContainer,child:ListTile(onTap:()=>_scan(context),leading:const Icon(Icons.center_focus_strong),title:const Text('Scan your first receipt'),subtitle:const Text('Extract merchant, total and date locally.'))) else ...recent.map((e)=>Padding(padding:const EdgeInsets.only(bottom:8),child:ExpenseCard(expense:e)))
]));}
 void _scan(BuildContext c)=>Navigator.push(c,MaterialPageRoute(builder:(_)=>CameraPage(store:store)));
 Widget _summary(BuildContext c,String t,int a,IconData i)=>Card(color:Theme.of(c).colorScheme.primary,child:ListTile(contentPadding:const EdgeInsets.all(16),leading:CircleAvatar(child:Icon(i)),title:Text(t,style:const TextStyle(color:Colors.white70)),subtitle:Text(formatVnd(a),style:const TextStyle(color:Colors.white,fontSize:24,fontWeight:FontWeight.w900))));
 Widget _mini(BuildContext c,String t,int a,IconData i)=>Card(color:Colors.white,child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(i),const SizedBox(height:12),Text(t),const SizedBox(height:4),Text(formatVnd(a),style:const TextStyle(fontWeight:FontWeight.w900))])));
}
