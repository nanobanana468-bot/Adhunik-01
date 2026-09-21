       import 'dart:io';  
       import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../models/employee.dart';
import '../services/face_service.dart';
import '../services/camera_service.dart';
import '../services/database_service.dart';

class EmployeeRegistrationScreen extends StatefulWidget {
  const EmployeeRegistrationScreen({super.key});

  @override
  State<EmployeeRegistrationScreen> createState() =>
      _EmployeeRegistrationScreenState();
}

class _EmployeeRegistrationScreenState
    extends State<EmployeeRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _punchingIdController = TextEditingController();
  final _nameController = TextEditingController();
  final _designationController = TextEditingController();
  final _departmentController = TextEditingController();
  final _mobileController = TextEditingController();

  String _workerType = 'WORKER';
  String _shift = 'GENERAL';
  DateTime? _joiningDate;

  bool _isSaving = false;

  // Employee photo path.
  String? _employeePhotoPath;

  // Face registration placeholder for next module.
  String? _faceData;

  @override
  void dispose() {
    _punchingIdController.dispose();
    _nameController.dispose();
    _designationController.dispose();
    _departmentController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _selectJoiningDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (selectedDate != null) {
      setState(() {
        _joiningDate = selectedDate;
      });
    }
  }

  Future<void> _captureEmployeePhoto() async {
    final camera = CameraService.frontCamera;

    if (camera == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Front camera is not available on this device.',
          ),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    final photoPath = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => EmployeePhotoCameraScreen(
          camera: camera,
        ),
      ),
    );

    if (photoPath != null && photoPath.isNotEmpty) {
      setState(() {
        _employeePhotoPath = photoPath;
      });
    }
  }

  void _removeEmployeePhoto() {
    setState(() {
      _employeePhotoPath = null;
    });
  }

  Future<void> _registerEmployee() async {
    if (_isSaving) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_joiningDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select joining date'),
        ),
      );
      return;
    }

    if (_employeePhotoPath == null ||
        _employeePhotoPath!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please capture employee photo first.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final punchingId =
          _punchingIdController.text.trim();

      // Check duplicate Punching ID.
      final existingEmployee =
          await DatabaseService.getEmployeeByPunchingId(
        punchingId,
      );

      if (existingEmployee != null) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'This Punching ID is already registered.',
            ),
            backgroundColor: Colors.red,
          ),
        );

        setState(() {
          _isSaving = false;
        });

        return;
      }

      final employee = Employee(
        punchingId: punchingId,
        name: _nameController.text.trim(),
        workerType: _workerType,
        designation: _designationController.text.trim(),
        department: _departmentController.text.trim(),
        mobile: _mobileController.text.trim(),
        joiningDate: _joiningDate!,
        shift: _shift,

        // Save captured employee photo.
        photoPath: _employeePhotoPath,

        // Face recognition data will be added
        // in the next face-registration module.
        faceData: _faceData,

        isActive: true,
      );

      final employeeData = employee.toMap();

      // Database needs createdAt for every employee.
      employeeData['createdAt'] =
          DateTime.now().toIso8601String();

      await DatabaseService.addEmployee(
        employeeData,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${employee.name} registered successfully.',
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Clear form after successful registration.
      _punchingIdController.clear();
      _nameController.clear();
      _designationController.clear();
      _departmentController.clear();
      _mobileController.clear();

      setState(() {
        _workerType = 'WORKER';
        _shift = 'GENERAL';
        _joiningDate = null;
        _employeePhotoPath = null;
        _faceData = null;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Registration failed: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  InputDecoration _inputDecoration(
    String label,
    IconData icon,
  ) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Employee Registration',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Icon(
                Icons.person_add_alt_1,
                size: 70,
              ),

              const SizedBox(height: 12),

              const Text(
                'Register New Employee',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 24),

              // --------------------------------------------------
              // PUNCHING ID
              // --------------------------------------------------

              TextFormField(
                controller: _punchingIdController,
                decoration: _inputDecoration(
                  'Punching ID / Employee ID',
                  Icons.badge,
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Enter punching ID';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 14),

              // --------------------------------------------------
              // EMPLOYEE NAME
              // --------------------------------------------------

              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration(
                  'Employee Name',
                  Icons.person,
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Enter employee name';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 14),

              // --------------------------------------------------
              // EMPLOYEE TYPE
              // --------------------------------------------------

              DropdownButtonFormField<String>(
                value: _workerType,
                decoration: _inputDecoration(
                  'Employee Type',
                  Icons.groups,
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'WORKER',
                    child: Text('WORKER'),
                  ),
                  DropdownMenuItem(
                    value: 'STAFF',
                    child: Text('STAFF'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _workerType = value;
                    });
                  }
                },
              ),

              const SizedBox(height: 14),

              // --------------------------------------------------
              // DESIGNATION
              // --------------------------------------------------

              TextFormField(
                controller: _designationController,
                decoration: _inputDecoration(
                  'Designation',
                  Icons.work,
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Enter designation';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 14),

              // --------------------------------------------------
              // DEPARTMENT
              // --------------------------------------------------

              TextFormField(
                controller: _departmentController,
                decoration: _inputDecoration(
                  'Department',
                  Icons.business,
                ),
              ),

              const SizedBox(height: 14),

              // --------------------------------------------------
              // MOBILE
              // --------------------------------------------------

              TextFormField(
                controller: _mobileController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: _inputDecoration(
                  'Mobile Number',
                  Icons.phone,
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Enter mobile number';
                  }

                  if (value.length != 10) {
                    return 'Enter valid 10-digit number';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 8),

              // --------------------------------------------------
              // JOINING DATE
              // --------------------------------------------------

              InkWell(
                onTap: _selectJoiningDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: _inputDecoration(
                    'Joining Date',
                    Icons.calendar_month,
                  ),
                  child: Text(
                    _joiningDate == null
                        ? 'Select joining date'
                        : _formatDate(_joiningDate!),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // --------------------------------------------------
              // SHIFT
              // --------------------------------------------------

              DropdownButtonFormField<String>(
                value: _shift,
                decoration: _inputDecoration(
                  'Shift',
                  Icons.schedule,
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'GENERAL',
                    child: Text('GENERAL'),
                  ),
                  DropdownMenuItem(
                    value: 'DAY',
                    child: Text('DAY'),
                  ),
                  DropdownMenuItem(
                    value: 'NIGHT',
                    child: Text('NIGHT'),
                  ),
                  DropdownMenuItem(
                    value: 'A',
                    child: Text('SHIFT A'),
                  ),
                  DropdownMenuItem(
                    value: 'B',
                    child: Text('SHIFT B'),
                  ),
                  DropdownMenuItem(
                    value: 'C',
                    child: Text('SHIFT C'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _shift = value;
                    });
                  }
                },
              ),

              const SizedBox(height: 22),

              // ==================================================
              // EMPLOYEE PHOTO
              // ==================================================

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _employeePhotoPath != null
                        ? Colors.green
                        : Colors.grey,
                    width: 1.5,
                  ),
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Employee Photo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 14),

                    if (_employeePhotoPath != null)
                      ClipRRect(
                        borderRadius:
                            BorderRadius.circular(14),
                        child: Image.file(
                          FileImage(
                            _employeePhotoPath!,
                          ).file,
                          width: 180,
                          height: 180,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius:
                              BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.grey.shade300,
                          ),
                        ),
                        child: const Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person,
                              size: 70,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'No Photo',
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isSaving
                                ? null
                                : _captureEmployeePhoto,
                            icon: const Icon(
                              Icons.camera_alt,
                            ),
                            label: Text(
                              _employeePhotoPath == null
                                  ? 'CAPTURE PHOTO'
                                  : 'RETAKE PHOTO',
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (_employeePhotoPath != null) ...[
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _isSaving
                            ? null
                            : _removeEmployeePhoto,
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        label: const Text(
                          'REMOVE PHOTO',
                          style: TextStyle(
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ==================================================
              // FACE REGISTRATION
              // ==================================================

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey,
                  ),
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.face_retouching_natural,
                      size: 42,
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Face Registration',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      _faceData == null
                          ? 'Face scan will be added next'
                          : 'Face registration completed',
                      style: TextStyle(
                        color: _faceData == null
                            ? Colors.grey
                            : Colors.green,
                      ),
                    ),

                    const SizedBox(height: 12),

                    OutlinedButton.icon(
                      onPressed: _isSaving
                          ? null
                          : () {
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Face registration module will be added next.',
                                  ),
                                ),
                              );
                            },
                      icon: const Icon(
                        Icons.face,
                      ),
                      label: const Text(
                        'REGISTER FACE',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 26),

              // ==================================================
              // REGISTER BUTTON
              // ==================================================

              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed:
                      _isSaving ? null : _registerEmployee,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.save,
                        ),
                  label: Text(
                    _isSaving
                        ? 'SAVING...'
                        : 'REGISTER EMPLOYEE',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
// EMPLOYEE PHOTO CAMERA SCREEN
// ================================================================

class EmployeePhotoCameraScreen
    extends StatefulWidget {
  final CameraDescription camera;

  const EmployeePhotoCameraScreen({
    super.key,
    required this.camera,
  });

  @override
  State<EmployeePhotoCameraScreen> createState() =>
      _EmployeePhotoCameraScreenState();
}

class _EmployeePhotoCameraScreenState
    extends State<EmployeePhotoCameraScreen> {
  CameraController? _controller;

  bool _isReady = false;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final controller = CameraController(
        widget.camera,
        ResolutionPreset.high,
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
    _controller?.dispose();
    super.dispose();
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
      final image =
          await _controller!.takePicture();

      if (!mounted) return;

      Navigator.pop(
        context,
        image.path,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isCapturing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Photo capture failed: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          'Capture Employee Photo',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          if (_isReady && _controller != null)
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

          // Face positioning guide.
          Center(
            child: Container(
              width: 240,
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
                borderRadius:
                    BorderRadius.circular(120),
              ),
            ),
          ),

          Positioned(
            left: 20,
            right: 20,
            bottom: 25,
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(
                      alpha: 0.70,
                    ),
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'Keep the employee face inside the frame',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                SizedBox(
                  width: 74,
                  height: 74,
                  child: FloatingActionButton(
                    heroTag: 'employee_photo_capture',
                    onPressed:
                        _isCapturing ||
                                !_isReady
                            ? null
                            : _capturePhoto,
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    child: _isCapturing
                        ? const CircularProgressIndicator()
                        : const Icon(
                            Icons.camera_alt,
                            size: 34,
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
