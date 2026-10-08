import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
class ReceiptOcrService {
  final TextRecognizer _recognizer=TextRecognizer(script:TextRecognitionScript.latin);
  Future<String> recognize(File file) async => (await _recognizer.processImage(InputImage.fromFilePath(file.path))).text.trim();
  Future<void> dispose() => _recognizer.close();
}
