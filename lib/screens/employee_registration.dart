import 'package:flutter/material.dart';

import '../models/employee.dart';
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
        photoPath: null,
        faceData: null,
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

              TextFormField(
                controller: _departmentController,
                decoration: _inputDecoration(
                  'Department',
                  Icons.business,
                ),
              ),

              const SizedBox(height: 14),

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

              // Employee Photo
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.photo_camera,
                      size: 42,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Employee Photo',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Photo capture will be added next',
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Face Registration
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.face_retouching_natural,
                      size: 42,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Face Registration',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Face scan will be added next',
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 26),

              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed:
                      _isSaving ? null : _registerEmployee,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.save),
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
