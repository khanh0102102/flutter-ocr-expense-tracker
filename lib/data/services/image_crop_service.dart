import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class ImageCropService {
  static const _uuid = Uuid();

  static Future<File> cropToReceiptFrame(File source) async {
    final decoded = img.decodeImage(await source.readAsBytes());

    if (decoded == null) {
      throw StateError('Unable to decode captured image.');
    }

    final width = (decoded.width * 0.86).round();
    final height = (decoded.height * 0.62).round();
    final x = ((decoded.width - width) / 2).round();
    final y = ((decoded.height - height) / 2).round();

    final cropped = img.copyCrop(
      decoded,
      x: x,
      y: y,
      width: width,
      height: height,
    );

    final path = p.join(
      (await getTemporaryDirectory()).path,
      'ocr_${_uuid.v4()}.jpg',
    );

    final file = File(path);
    await file.writeAsBytes(
      img.encodeJpg(cropped, quality: 92),
      flush: true,
    );

    return file;
  }
}