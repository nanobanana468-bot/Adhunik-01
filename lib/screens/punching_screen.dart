import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../services/camera_service.dart';
import '../services/database_service.dart';
import 'employee_registration.dart';
import 'punch_history.dart';

class PunchingScreen extends StatefulWidget {
  const PunchingScreen({super.key});

  @override
  State<PunchingScreen> createState() => _PunchingScreenState();
}

class _PunchingScreenState extends State<PunchingScreen> {
  bool _isProcessing = false;

  String? _selectedPunchType;
  String? _successName;
  String? _successDesignation;
  String? _successWorkerType;
  String? _successTime;

  bool _showSuccessCard = false;

  Future<void> _openRegistration() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const EmployeeRegistrationScreen(),
      ),
    );
  }

  Future<void> _openHistory() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PunchHistoryScreen(),
      ),
    );
  }

  Future<void> _startPunch(String punchType) async {
    if (_isProcessing) {
      return;
    }

    final camera = CameraService.frontCamera;

    if (camera == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Camera not available on this device.',
          ),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    setState(() {
      _isProcessing = true;
      _selectedPunchType = punchType;
    });

    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PunchCameraScreen(
            camera: camera,
            punchType: punchType,
            onPunchCaptured: _savePunch,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _selectedPunchType = null;
        });
      }
    }
  }

  Future<void> _savePunch({
    required String punchType,
    required String employeeId,
    required String employeeName,
    required String designation,
    required String workerType,
    required String punchTime,
    required String photoPath,
  }) async {
    final punchId =
        '${employeeId}_${punchType}_${DateTime.now().microsecondsSinceEpoch}';

    final punchData = {
      'punchId': punchId,
      'employeePunchingId': employeeId,
      'employeeName': employeeName,
      'punchType': punchType,
      'punchTime': punchTime,
      'latitude': null,
      'longitude': null,
      'photoPath': photoPath,
      'synced': 0,
      'createdAt': DateTime.now().toIso8601String(),
    };

    await DatabaseService.addPunch(punchData);

    if (!mounted) return;

    setState(() {
      _successName = employeeName;
      _successDesignation = designation;
      _successWorkerType = workerType;
      _successTime = _formatTime(
        DateTime.parse(punchTime),
      );
      _selectedPunchType = punchType;
      _showSuccessCard = true;
    });

    Navigator.pop(context);

    Future.delayed(
      const Duration(seconds: 2),
      () {
        if (!mounted) return;

        setState(() {
          _showSuccessCard = false;
        });
      },
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour == 0
        ? 12
        : dateTime.hour > 12
            ? dateTime.hour - 12
            : dateTime.hour;

    final minute =
        dateTime.minute.toString().padLeft(2, '0');

    final second =
        dateTime.second.toString().padLeft(2, '0');

    final period =
        dateTime.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute:$second $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'ADHUNIK.01',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _openRegistration,
            icon: const Icon(
              Icons.person_add_alt_1,
            ),
            tooltip: 'Employee Registration',
          ),
          IconButton(
            onPressed: _openHistory,
            icon: const Icon(
              Icons.history,
            ),
            tooltip: 'Punch History',
          ),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Settings will be added in the next module.',
                  ),
                ),
              );
            },
            icon: const Icon(
              Icons.settings,
            ),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 30),

                const Icon(
                  Icons.fingerprint,
                  size: 85,
                  color: Colors.blue,
                ),

                const SizedBox(height: 10),

                const Text(
                  'EMPLOYEE PUNCHING',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'Select Punch Type',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 15,
                  ),
                ),

                const Spacer(),

                Padding(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 16,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _PunchButton(
                          title: 'PUNCH IN',
                          icon: Icons.login,
                          color: Colors.green,
                          onPressed:
                              _isProcessing
                                  ? null
                                  : () => _startPunch(
                                        'IN',
                                      ),
                        ),
                      ),

                      const SizedBox(width: 14),

                      Expanded(
                        child: _PunchButton(
                          title: 'PUNCH OUT',
                          icon: Icons.logout,
                          color: Colors.red,
                          onPressed:
                              _isProcessing
                                  ? null
                                  : () => _startPunch(
                                        'OUT',
                                      ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 35),

                if (_isProcessing)
                  Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 10),
                      Text(
                        _selectedPunchType == null
                            ? 'Processing...'
                            : 'Opening camera for '
                                '${_selectedPunchType!}...',
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),

                const Spacer(),

                Padding(
                  padding:
                      const EdgeInsets.only(
                    bottom: 20,
                  ),
                  child: Text(
                    'ADHUNIK.01 • Attendance Management',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            if (_showSuccessCard)
              Positioned(
                left: 16,
                right: 16,
                bottom: 75,
                child: _PunchSuccessCard(
                  employee: {
                    'name':
                        _successName ?? '',
                    'designation':
                        _successDesignation ?? '',
                    'workerType':
                        _successWorkerType ?? '',
                  },
                  punchType:
                      _selectedPunchType ?? '',
                  timeText:
                      _successTime ?? '',
                  isIn:
                      _selectedPunchType == 'IN',
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PunchButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  const _PunchButton({
    required this.title,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              color.withValues(alpha: 0.45),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(24),
          ),
          elevation: 5,
        ),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 52,
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PunchCameraScreen extends StatefulWidget {
  final CameraDescription camera;
  final String punchType;

  final Future<void> Function({
    required String punchType,
    required String employeeId,
    required String employeeName,
    required String designation,
    required String workerType,
    required String punchTime,
    required String photoPath,
  }) onPunchCaptured;

  const PunchCameraScreen({
    super.key,
    required this.camera,
    required this.punchType,
    required this.onPunchCaptured,
  });

  @override
  State<PunchCameraScreen> createState() =>
      _PunchCameraScreenState();
}

class _PunchCameraScreenState
    extends State<PunchCameraScreen> {
  CameraController? _controller;
  bool _isReady = false;
  bool _isCapturing = false;

  final TextEditingController _employeeIdController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final controller = CameraController(
        widget.camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

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
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Camera error: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _employeeIdController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _capturePunch() async {
    if (!_isReady ||
        _controller == null ||
        _isCapturing) {
      return;
    }

    final employeeId =
        _employeeIdController.text.trim();

    if (employeeId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enter employee Punching ID first.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    try {
      final employee =
          await DatabaseService.getEmployeeByPunchingId(
        employeeId,
      );

      if (employee == null) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Employee not found. Please register the employee first.',
            ),
            backgroundColor: Colors.red,
          ),
        );

        setState(() {
          _isCapturing = false;
        });

        return;
      }

      if ((employee['isActive'] ?? 1) != 1) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'This employee is inactive.',
            ),
            backgroundColor: Colors.red,
          ),
        );

        setState(() {
          _isCapturing = false;
        });

        return;
      }

      final image =
          await _controller!.takePicture();

      final punchTime =
          DateTime.now().toIso8601String();

      await widget.onPunchCaptured(
        punchType: widget.punchType,
        employeeId: employeeId,
        employeeName:
            employee['name']?.toString() ?? '',
        designation:
            employee['designation']?.toString() ?? '',
        workerType:
            employee['workerType']?.toString() ?? '',
        punchTime: punchTime,
        photoPath: image.path,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Punch failed: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );

      setState(() {
        _isCapturing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          'PUNCH ${widget.punchType}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          if (_isReady &&
              _controller != null)
            Positioned.fill(
              child: CameraPreview(
                _controller!,
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),

          Positioned(
            left: 20,
            right: 20,
            bottom: 25,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color:
                        Colors.black.withValues(
                      alpha: 0.75,
                    ),
                    borderRadius:
                        BorderRadius.circular(16),
                  ),
                  padding:
                      const EdgeInsets.all(12),
                  child: TextField(
                    controller:
                        _employeeIdController,
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                    decoration:
                        const InputDecoration(
                      labelText:
                          'Employee Punching ID',
                      labelStyle: TextStyle(
                        color: Colors.white70,
                      ),
                      prefixIcon: Icon(
                        Icons.badge,
                        color: Colors.white,
                      ),
                      enabledBorder:
                          OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.white54,
                        ),
                      ),
                      focusedBorder:
                          OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed:
                        _isCapturing ||
                                !_isReady
                            ? null
                            : _capturePunch,
                    icon: _isCapturing
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt,
                          ),
                    label: Text(
                      _isCapturing
                          ? 'PROCESSING...'
                          : 'CAPTURE PUNCH ${widget.punchType}',
                      style: const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PunchSuccessCard
    extends StatelessWidget {
  final Map<String, dynamic> employee;
  final String punchType;
  final String timeText;
  final bool isIn;

  const _PunchSuccessCard({
    required this.employee,
    required this.punchType,
    required this.timeText,
    required this.isIn,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            blurRadius: 20,
            spreadRadius: 2,
            offset: Offset(0, 8),
            color: Colors.black26,
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            child: Text(
              employee['name']
                      .toString()
                      .isNotEmpty
                  ? employee['name']
                      .toString()[0]
                      .toUpperCase()
                  : '?',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  employee['name'].toString(),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  '${employee['designation']} • '
                  '${employee['workerType']}',
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  timeText,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              color: isIn
                  ? Colors.green
                  : Colors.red,
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: Text(
              punchType,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
