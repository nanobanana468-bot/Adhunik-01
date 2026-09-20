import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../services/camera_service.dart';

class CameraScreen extends StatefulWidget {
  final bool isPunchIn;

  const CameraScreen({
    super.key,
    required this.isPunchIn,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _isReady = false;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final camera = CameraService.frontCamera ??
        CameraService.backCamera;

    if (camera == null) {
      return;
    }

    final controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _isReady = true;
      });
    } catch (e) {
      await controller.dispose();
    }
  }

  Future<void> _capturePhoto() async {
    if (!_isReady ||
        _controller == null ||
        _isCapturing) {
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    try {
      final photo = await _controller!.takePicture();

      if (!mounted) return;

      Navigator.pop(context, photo.path);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Camera photo capture failed'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          widget.isPunchIn
              ? 'PUNCH IN'
              : 'PUNCH OUT',
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (!_isReady || _controller == null) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(_controller!),

        Center(
          child: Container(
            width: 260,
            height: 320,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.white,
                width: 3,
              ),
              borderRadius: BorderRadius.circular(160),
            ),
          ),
        ),

        Positioned(
          bottom: 35,
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              onTap: _capturePhoto,
              child: Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  color: widget.isPunchIn
                      ? Colors.green
                      : Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 5,
                  ),
                ),
                child: _isCapturing
                    ? const Padding(
                        padding: EdgeInsets.all(22),
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 34,
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
