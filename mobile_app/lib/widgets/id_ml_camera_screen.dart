import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:permission_handler/permission_handler.dart';

class IDMLCameraScreen extends StatefulWidget {
  final Function(File) onImageCaptured;

  const IDMLCameraScreen({Key? key, required this.onImageCaptured})
      : super(key: key);

  @override
  State<IDMLCameraScreen> createState() => _IDMLCameraScreenState();
}

class _IDMLCameraScreenState extends State<IDMLCameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  late ObjectDetector _objectDetector;

  bool _isDetecting = false;
  Timer? _captureTimer;

@override
void initState() {
  super.initState();
  _handleCameraStartup();
}

Future<void> _handleCameraStartup() async {
  final status = await Permission.camera.request();
  if (status.isGranted) {
    _initializeObjectDetector();
    _startCamera();
  } else {
    print("❌ الكاميرا مرفوضة");
  }
}

  void _initializeObjectDetector() {
    final options = ObjectDetectorOptions(
      classifyObjects: false,
      multipleObjects: false,
      mode: DetectionMode.stream,
    );
    _objectDetector = ObjectDetector(options: options);
  }

Future<void> _startCamera() async {
  final cameras = await availableCameras();
  print("📷 الكاميرات المتاحة: ${cameras.length}");

  final camera = cameras.firstWhere(
    (c) => c.lensDirection == CameraLensDirection.back,
  );

  _controller = CameraController(
    camera,
    ResolutionPreset.medium,
    enableAudio: false,
    imageFormatGroup: ImageFormatGroup.unknown,
  );

  _initializeControllerFuture = _controller.initialize();
  await _initializeControllerFuture;

  print("📏 Aspect Ratio: ${_controller.value.aspectRatio}"); // ✅ هنا تحطه

  _controller.startImageStream(_processCameraImage);
  setState(() {});
}

  void _processCameraImage(CameraImage image) async {
    if (_isDetecting) return;
    _isDetecting = true;

    try {
      final bytes = image.planes[0].bytes;

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        inputImageData: InputImageData(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          imageRotation: InputImageRotation.rotation0deg,
          inputImageFormat: InputImageFormat.yuv_420_888,
          planeData: image.planes.map((plane) {
            return InputImagePlaneMetadata(
              bytesPerRow: plane.bytesPerRow,
              height: plane.height,
              width: plane.width,
            );
          }).toList(),
        ),
      );

      final objects = await _objectDetector.processImage(inputImage);

      if (objects.isNotEmpty) {
        final box = objects.first.boundingBox;
        if (box.width > 200 && box.height > 100) {
          _startCaptureCountdown();
        }
      }
    } catch (e) {
      print("Detection error: $e");
    }

    _isDetecting = false;
  }

  void _startCaptureCountdown() {
    if (_captureTimer != null) return;

    _captureTimer = Timer(Duration(seconds: 2), () async {
      final file = await _captureImage();
      if (file != null && file.existsSync()) {
        widget.onImageCaptured(file);

        if (mounted) {
          Future.microtask(() {
            Navigator.pop(context);
          });
        }
      }
      _captureTimer = null;
    });
  }

  Future<File?> _captureImage() async {
    try {
      await _initializeControllerFuture;
      final path = p.join(
        (await getTemporaryDirectory()).path,
        '${DateTime.now()}.jpg',
      );

      final picture = await _controller.takePicture();
      return File(picture.path);
    } catch (e) {
      print("Capture error: $e");
      return null;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _objectDetector.close();
    _captureTimer?.cancel();
    super.dispose();
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.black,
    body: (_controller.value.isInitialized)
        ? Stack(
            children: [
              Center(
                child: AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: CameraPreview(_controller),
                ),
              ),
              Center(
                child: Container(
                  width: 300,
                  height: 180,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.greenAccent, width: 3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              Positioned(
                top: 60,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'رجاء ضع البطاقة داخل الإطار',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ),
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  icon: Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          )
        : const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
  );
}
}
