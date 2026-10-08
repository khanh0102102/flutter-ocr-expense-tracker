import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
class ImageCropService {
  static const _uuid=Uuid();
  static Future<File> cropToReceiptFrame(File source) async {
    final decoded=img.decodeImage(await source.readAsBytes());
    if(decoded==null) throw StateError('Unable to decode captured image.');
    final w=(decoded.width*.86).round(), h=(decoded.height*.62).round();
    final cropped=img.copyCrop(decoded,x:((decoded.width-w)/2).round(),y:((decoded.height-h)/2).round(),width:w,height:h);
    final file=File(p.join((await getTemporaryDirectory()).path,'ocr_'+_uuid.v4()+'.jpg'));
    await file.writeAsBytes(img.encodeJpg(cropped,quality:92),flush:true);
    return file;
  }
}
