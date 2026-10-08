import '../../core/utils/currency_utils.dart';

class ParsedReceipt {
  const ParsedReceipt({this.merchant,this.amount,this.date,this.merchantConfidence=0,this.amountConfidence=0,this.dateConfidence=0});
  final String? merchant; final int? amount; final DateTime? date;
  final double merchantConfidence, amountConfidence, dateConfidence;
  bool get hasAnyValue => merchant != null || amount != null || date != null;
}

class ReceiptParser {
  static final _date=RegExp(r'\b([0-3]?\d)[/.-]([01]?\d)[/.-](20\d{2})\b');
  static final _iso=RegExp(r'\b(20\d{2})[/.-]([01]?\d)[/.-]([0-3]?\d)\b');
  static final _total=RegExp(r'(?:TỔNG\s*(?:CỘNG|TIỀN)|TONG\s*(?:CONG|TIEN)|TOTAL|GRAND\s*TOTAL|THANH\s*TOÁN|THANH\s*TOAN|AMOUNT\s*DUE)\s*[:\-]?\s*([0-9][0-9., ]{2,})',caseSensitive:false);
  static final _money=RegExp(r'([0-9]{1,3}(?:[.,][0-9]{3})+|[0-9]{4,9})\s*(?:VND|VNĐ|đ|₫)\b',caseSensitive:false);

  ParsedReceipt parse(String text){
    final lines=text.replaceAll('\r','').split('\n').map((e)=>e.trim()).where((e)=>e.isNotEmpty).toList();
    String? merchant; double mc=0;
    for(final line in lines.take(8)){
      if(line.length<3||line.length>60)continue;
      final u=line.toUpperCase();
      if(['HÓA ĐƠN','HOA DON','INVOICE','RECEIPT','TOTAL','TỔNG','DATE','TIME','VAT','TEL'].any(u.contains))continue;
      if(RegExp(r'^\d[\d\s.,:/-]*$').hasMatch(line))continue;
      if(RegExp(r'[A-Za-zÀ-ỹ]').hasMatch(line)){merchant=line.replaceAll(RegExp(r'\s+'),' ');mc=.55;break;}
    }
    int? amount; double ac=0;
    final labeled=_total.firstMatch(text);
    if(labeled!=null){final v=parseIntegerAmount(labeled.group(1)!);if(v>0){amount=v;ac=.95;}}
    if(amount==null)for(final m in _money.allMatches(text)){final v=parseIntegerAmount(m.group(1)!);if(v>0){amount=v;ac=.78;break;}}
    DateTime? date; double dc=0;
    final d=_date.firstMatch(text);
    if(d!=null){date=_safe(int.parse(d.group(3)!),int.parse(d.group(2)!),int.parse(d.group(1)!));if(date!=null)dc=.92;}
    final i=_iso.firstMatch(text);
    if(date==null&&i!=null){date=_safe(int.parse(i.group(1)!),int.parse(i.group(2)!),int.parse(i.group(3)!));if(date!=null)dc=.88;}
    return ParsedReceipt(merchant:merchant,amount:amount,date:date,merchantConfidence:mc,amountConfidence:ac,dateConfidence:dc);
  }
  DateTime? _safe(int y,int m,int d){final x=DateTime(y,m,d);return x.year==y&&x.month==m&&x.day==d?x:null;}
}
