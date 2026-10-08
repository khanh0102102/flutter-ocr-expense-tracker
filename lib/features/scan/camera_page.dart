import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/services/image_crop_service.dart';
import '../../data/services/receipt_ocr_service.dart';
import '../../state/expense_store.dart';
import 'receipt_parser.dart';
import 'review_page.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key, required this.store});

  final ExpenseStore store;

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  final _picker = ImagePicker();
  final _ocr = ReceiptOcrService();

  CameraController? _camera;
  bool _busy = false;
  bool _flash = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw StateError('No camera available.');
      }

      final camera = cameras.firstWhere(
        (item) => item.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await controller.initialize();
      await controller.setFlashMode(FlashMode.off);

      if (mounted) {
        setState(() => _camera = controller);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _toggleFlash() async {
    final controller = _camera;
    if (controller == null) {
      return;
    }

    final enabled = !_flash;

    try {
      await controller.setFlashMode(
        enabled ? FlashMode.torch : FlashMode.off,
      );

      if (mounted) {
        setState(() => _flash = enabled);
      }
    } on CameraException catch (error) {
      _showMessage(
        'Flash unavailable: ' + (error.description ?? error.code),
      );
    }
  }

  Future<void> _focus(TapUpDetails details) async {
    final controller = _camera;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    final size = MediaQuery.sizeOf(context);
    if (size.isEmpty) {
      return;
    }

    final point = Offset(
      (details.globalPosition.dx / size.width).clamp(0.0, 1.0),
      (details.globalPosition.dy / size.height).clamp(0.0, 1.0),
    );

    try {
      await controller.setFocusPoint(point);
    } on CameraException {
      _showMessage('Manual focus is not supported by this camera.');
    }
  }

  Future<void> _pick(ImageSource source) async {
    if (_busy) {
      return;
    }

    setState(() => _busy = true);

    try {
      final image = await _picker.pickImage(
        source: source,
        imageQuality: 100,
      );

      if (image != null) {
        await _process(File(image.path));
      }
    } catch (error) {
      _showMessage('OCR failed: ' + error.toString());
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _capture() async {
    final controller = _camera;
    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.isTakingPicture ||
        _busy) {
      return;
    }

    setState(() => _busy = true);

    try {
      final image = await controller.takePicture();
      await _process(File(image.path));
    } catch (error) {
      _showMessage('Capture failed: ' + error.toString());
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _process(File source) async {
    final cropped = await ImageCropService.cropToReceiptFrame(source);
    final rawText = await _ocr.recognize(cropped);
    final parsed = ReceiptParser().parse(rawText);

    if (!mounted) {
      return;
    }

    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewPage(
          store: widget.store,
          imageFile: cropped,
          rawText: rawText,
          parsed: parsed,
        ),
      ),
    );

    if (saved == true && mounted) {
      Navigator.pop(context);
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _camera?.dispose();
    _ocr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _error!,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final controller = _camera;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureDetector(
          onTapUp: _focus,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (controller != null) CameraPreview(controller),
              const IgnorePointer(
                child: CustomPaint(painter: _FramePainter()),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: IconButton(
                  onPressed: _toggleFlash,
                  icon: Icon(
                    _flash ? Icons.flash_on : Icons.flash_off,
                    color: Colors.white,
                  ),
                ),
              ),
              Positioned(
                bottom: 24,
                left: 20,
                right: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => _pick(ImageSource.gallery),
                      icon: const Icon(
                        Icons.photo_library,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    FloatingActionButton(
                      onPressed: _busy ? null : _capture,
                      child: _busy
                          ? const CircularProgressIndicator()
                          : const Icon(Icons.camera_alt),
                    ),
                    IconButton(
                      onPressed: () => _pick(ImageSource.camera),
                      icon: const Icon(
                        Icons.document_scanner,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FramePainter extends CustomPainter {
  const _FramePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: size.width * 0.86,
      height: size.height * 0.46,
    );

    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = Colors.black.withValues(alpha: 0.35),
    );

    final clear = Paint()..blendMode = BlendMode.clear;
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = Colors.black54,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(22)),
      clear,
    );
    canvas.restore();

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(22)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _FramePainter oldDelegate) => false;
}