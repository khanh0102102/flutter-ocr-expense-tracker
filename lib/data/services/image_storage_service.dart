import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ImageStorageService {
  static Future<Directory> _directory() async {
    final base = await getApplicationDocumentsDirectory();
    final directory = Directory(p.join(base.path, 'receipts'));

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    return directory;
  }

  static Future<(String, String)> persist(File source, String id) async {
    final directory = await _directory();
    final bytes = await source.readAsBytes();
    final imagePath = p.join(directory.path, '$id.jpg');
    final thumbnailPath = p.join(directory.path, '${id}_thumb.jpg');

    await File(imagePath).writeAsBytes(bytes, flush: true);

    final decoded = img.decodeImage(bytes);
    final thumbnail = decoded == null
        ? bytes
        : img.encodeJpg(
            img.copyResize(decoded, width: 320),
            quality: 82,
          );

    await File(thumbnailPath).writeAsBytes(thumbnail, flush: true);
    return (imagePath, thumbnailPath);
  }

  static Future<void> removeForExpense({
    String? imagePath,
    String? thumbnailPath,
  }) async {
    for (final filePath in [imagePath, thumbnailPath]) {
      if (filePath != null) {
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
        }
      }
    }
  }

  static Future<void> clearAll() async {
    final directory = await _directory();
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }
}