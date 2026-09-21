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
  bool _isSwitchingCamera = false;

  CameraLensDirection _currentDirection =
      CameraLensDirection.front;

  @override
  void initState() {
    super.initState();
    _initializeCamera(_currentDirection);
  }

  Future<void> _initializeCamera(
    CameraLensDirection direction,
  ) async {
    final cameras = CameraService.cameras;

    if (cameras.isEmpty) {
      if (mounted) {
        setState(() {
          _isReady = false;
        });
      }
      return;
    }

    CameraDescription? selectedCamera;

    for (final camera in cameras) {
      if (camera.lensDirection == direction) {
        selectedCamera = camera;
        break;
      }
    }

    selectedCamera ??= cameras.first;

    final oldController = _controller;

    if (mounted) {
      setState(() {
        _isReady = false;
      });
    }

    await oldController?.dispose();

    final controller = CameraController(
      selectedCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      _controller = controller;

      setState(() {
        _isReady = true;
        _currentDirection =
            selectedCamera!.lensDirection;
      });
    } catch (e) {
      await controller.dispose();

      if (!mounted) return;

      setState(() {
        _isReady = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Camera start nahi ho paya.',
          ),
        ),
      );
    }
  }

  Future<void> _switchCamera() async {
    if (_isSwitchingCamera ||
        CameraService.cameras.length < 2) {
      return;
    }

    setState(() {
      _isSwitchingCamera = true;
    });

    final newDirection =
        _currentDirection ==
                CameraLensDirection.front
            ? CameraLensDirection.back
            : CameraLensDirection.front;

    await _initializeCamera(newDirection);

    if (!mounted) return;

    setState(() {
      _isSwitchingCamera = false;
    });
  }

  Future<void> _capturePhoto() async {
    if (!_isReady ||
        _controller == null ||
        _isCapturing ||
        !_controller!.value.isInitialized) {
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    try {
      final photo = await _controller!.takePicture();

      if (!mounted) return;

      /*
       * Camera capture result.
       *
       * punchType:
       * IN  = Punch In
       * OUT = Punch Out
       *
       * capturedAt is the ORIGINAL camera punch time.
       * It will later be saved permanently with the punch record.
       */
      Navigator.pop(
        context,
        {
          'photoPath': photo.path,
          'punchType': widget.isPunchIn
              ? 'IN'
              : 'OUT',
          'capturedAt':
              DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Photo capture failed.',
          ),
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
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (CameraService.cameras.length >= 2)
            IconButton(
              onPressed: _isSwitchingCamera
                  ? null
                  : _switchCamera,
              tooltip: 'Switch Camera',
              icon: const Icon(
                Icons.flip_camera_android,
                size: 28,
              ),
            ),
        ],
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
              borderRadius:
                  BorderRadius.circular(160),
            ),
          ),
        ),

        Positioned(
          top: 20,
          left: 20,
          child: Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(
                alpha: 0.55,
              ),
              borderRadius:
                  BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  _currentDirection ==
                          CameraLensDirection.front
                      ? Icons.camera_front
                      : Icons.camera_rear,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  _currentDirection ==
                          CameraLensDirection.front
                      ? 'Front Camera'
                      : 'Back Camera',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),

        Positioned(
          top: 20,
          right: 20,
          child: Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: widget.isPunchIn
                  ? Colors.green
                  : Colors.red,
              borderRadius:
                  BorderRadius.circular(20),
            ),
            child: Text(
              widget.isPunchIn
                  ? 'PUNCH IN'
                  : 'PUNCH OUT',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
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
                        padding:
                            EdgeInsets.all(22),
                        child:
                            CircularProgressIndicator(
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
