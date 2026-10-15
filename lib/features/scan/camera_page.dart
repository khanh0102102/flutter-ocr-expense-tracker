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
      } else {
        await controller.dispose();
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

  Future<void> _retryCamera() async {
    if (_loading) {
      return;
    }

    await _camera?.dispose();
    if (!mounted) {
      return;
    }

    setState(() {
      _camera = null;
      _error = null;
      _loading = true;
      _flash = false;
    });
    await _initializeCamera();
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
        'Flash unavailable: ${error.description ?? error.code}',
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
        // Imported images are processed in full. Only photos taken using the
        // in-app viewfinder are cropped to its receipt frame.
        await _process(File(image.path));
      }
    } catch (error) {
      _showMessage('OCR failed: ${error.toString()}');
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
      await _process(File(image.path), cropToReceiptFrame: true);
    } catch (error) {
      _showMessage('Capture failed: ${error.toString()}');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _process(
    File source, {
    bool cropToReceiptFrame = false,
  }) async {
    final imageForOcr = cropToReceiptFrame
        ? await ImageCropService.cropToReceiptFrame(source)
        : source;
    final rawText = await _ocr.recognize(imageForOcr);
    final parsed = ReceiptParser().parse(rawText);

    if (!mounted) {
      return;
    }

    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewPage(
          store: widget.store,
          imageFile: imageForOcr,
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

    // Do not block the gallery/file-import workflow when an emulator or
    // device has no usable camera.
    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF101114),
        appBar: AppBar(
          backgroundColor: const Color(0xFF101114),
          foregroundColor: Colors.white,
          title: const Text('Import receipt'),
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            tooltip: 'Close',
          ),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.image_search_outlined,
                      size: 76,
                      color: Colors.white70,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'No camera available',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'You can still scan a receipt by choosing an image '
                      'from your device. The app will read the image on-device '
                      'and let you review the detected details before saving.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _busy
                            ? null
                            : () => _pick(ImageSource.gallery),
                        icon: _busy
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.upload_file),
                        label: Text(
                          _busy ? 'Processing image...' : 'Choose receipt image',
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _retryCamera,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try camera again'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
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
                      tooltip: 'Choose receipt image',
                      onPressed: _busy ? null : () => _pick(ImageSource.gallery),
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
                      tooltip: 'Take photo with device camera',
                      onPressed: _busy ? null : () => _pick(ImageSource.camera),
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