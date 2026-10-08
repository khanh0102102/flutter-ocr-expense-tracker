import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
class ImageStorageService {
  static Future<Directory> _dir() async { final base=await getApplicationDocumentsDirectory(); final dir=Directory(p.join(base.path,'receipts')); if(!await dir.exists()) await dir.create(recursive:true); return dir; }
  static Future<(String,String)> persist(File source,String id) async {
    final dir=await _dir(), bytes=await source.readAsBytes();
    final imagePath=p.join(dir.path,id+'.jpg'), thumbPath=p.join(dir.path,id+'_thumb.jpg');
    await File(imagePath).writeAsBytes(bytes,flush:true);
    final decoded=img.decodeImage(bytes);
    final thumb=decoded==null?bytes:img.encodeJpg(img.copyResize(decoded,width:320),quality:82);
    await File(thumbPath).writeAsBytes(thumb,flush:true);
    return (imagePath,thumbPath);
  }
  static Future<void> removeForExpense({String? imagePath,String? thumbnailPath}) async { for(final path in [imagePath,thumbnailPath]){if(path!=null){final f=File(path);if(await f.exists())await f.delete();}}}
  static Future<void> clearAll() async { final dir=await _dir(); if(await dir.exists()) await dir.delete(recursive:true); }
}
