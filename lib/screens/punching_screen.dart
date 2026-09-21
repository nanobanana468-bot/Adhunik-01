import 'package:flutter/material.dart';

import 'camera_screen.dart';
import 'employee_registration.dart';
import 'history/punch_history.dart';
import '../services/database_service.dart';

class PunchingScreen extends StatefulWidget {
  const PunchingScreen({super.key});

  @override
  State<PunchingScreen> createState() =>
      _PunchingScreenState();
}

class _PunchingScreenState extends State<PunchingScreen> {
  bool _isProcessing = false;

  Future<void> _openPunchCamera(
    BuildContext context,
    bool isPunchIn,
  ) async {
    if (_isProcessing) {
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CameraScreen(
          isPunchIn: isPunchIn,
        ),
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    if (result is! Map) {
      return;
    }

    final photoPath = result['photoPath']?.toString();
    final punchType = result['punchType']?.toString();
    final capturedAt = result['capturedAt']?.toString();

    if (photoPath == null ||
        punchType == null ||
        capturedAt == null) {
      return;
    }

    await _selectEmployeeAndSavePunch(
      photoPath: photoPath,
      punchType: punchType,
      capturedAt: capturedAt,
    );
  }

  Future<void> _selectEmployeeAndSavePunch({
    required String photoPath,
    required String punchType,
    required String capturedAt,
  }) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final employees =
          await DatabaseService.getEmployees(
        activeOnly: true,
      );

      if (!mounted) return;

      if (employees.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Pehle kam se kam ek employee register karein.',
            ),
          ),
        );

        setState(() {
          _isProcessing = false;
        });

        return;
      }

      final selectedEmployee =
          await showModalBottomSheet<
              Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) {
          return SafeArea(
            child: SizedBox(
              height:
                  MediaQuery.of(context).size.height * 0.75,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      8,
                      20,
                      12,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          punchType == 'IN'
                              ? Icons.login
                              : Icons.logout,
                          color: punchType == 'IN'
                              ? Colors.green
                              : Colors.red,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            punchType == 'IN'
                                ? 'Select Employee - PUNCH IN'
                                : 'Select Employee - PUNCH OUT',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView.separated(
                      itemCount: employees.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final employee =
                            employees[index];

                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              employee['name']
                                      .toString()
                                      .isNotEmpty
                                  ? employee['name']
                                      .toString()[0]
                                      .toUpperCase()
                                  : '?',
                            ),
                          ),
                          title: Text(
                            employee['name'].toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            '${employee['punchingId']} • '
                            '${employee['workerType']} • '
                            '${employee['designation']}',
                          ),
                          trailing: Icon(
                            punchType == 'IN'
                                ? Icons.login
                                : Icons.logout,
                            color: punchType == 'IN'
                                ? Colors.green
                                : Colors.red,
                          ),
                          onTap: () {
                            Navigator.pop(
                              context,
                              employee,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

      if (!mounted) return;

      if (selectedEmployee == null) {
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      final employeePunchingId =
          selectedEmployee['punchingId'].toString();

      final employeeName =
          selectedEmployee['name'].toString();

      final uniquePunchId =
          '${employeePunchingId}_${punchType}_'
          '${DateTime.now().microsecondsSinceEpoch}';

      final punchData = {
        'punchId': uniquePunchId,
        'employeePunchingId': employeePunchingId,
        'employeeName': employeeName,
        'punchType': punchType,
        'punchTime': capturedAt,
        'latitude': null,
        'longitude': null,
        'photoPath': photoPath,
        'synced': 0,
        'createdAt':
            DateTime.now().toIso8601String(),
      };

      await DatabaseService.addPunch(
        punchData,
      );

      if (!mounted) return;

      await _showPunchSuccessCard(
        employee: selectedEmployee,
        punchType: punchType,
        punchTime: DateTime.tryParse(
              capturedAt,
            ) ??
            DateTime.now(),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Punch save nahi ho paya: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _showPunchSuccessCard({
    required Map<String, dynamic> employee,
    required String punchType,
    required DateTime punchTime,
  }) async {
    final isIn = punchType == 'IN';

    final timeText =
        '${punchTime.hour.toString().padLeft(2, '0')}:'
        '${punchTime.minute.toString().padLeft(2, '0')}:'
        '${punchTime.second.toString().padLeft(2, '0')}';

    final overlay = Overlay.of(context);

    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: 90,
          left: 16,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: _PunchSuccessCard(
              employee: employee,
              punchType: punchType,
              timeText: timeText,
              isIn: isIn,
            ),
          ),
        );
      },
    );

    overlay.insert(entry);

    await Future.delayed(
      const Duration(seconds: 2),
    );

    if (entry.mounted) {
      entry.remove();
    }
  }

  void _openEmployeeRegistration(
    BuildContext context,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const EmployeeRegistrationScreen(),
      ),
    );
  }

  void _openHistory(
    BuildContext context,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const PunchHistoryScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ADHUNIK.01',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              _openEmployeeRegistration(context);
            },
            icon: const Icon(
              Icons.person_add_alt_1,
            ),
            tooltip: 'Employee Registration',
          ),

          IconButton(
            onPressed: () {
              _openHistory(context);
            },
            icon: const Icon(
              Icons.history,
            ),
            tooltip: 'Punch History',
          ),

          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.settings,
            ),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 20),

              const Text(
                'Employee Punching',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Select an option to continue',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey,
                ),
              ),

              const Spacer(),

              if (_isProcessing)
                const Padding(
                  padding: EdgeInsets.only(
                    bottom: 20,
                  ),
                  child: CircularProgressIndicator(),
                ),

              Row(
                children: [
                  Expanded(
                    child: _PunchButton(
                      title: 'PUNCH IN',
                      icon: Icons.login,
                      color: Colors.green,
                      onPressed: () {
                        _openPunchCamera(
                          context,
                          true,
                        );
                      },
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: _PunchButton(
                      title: 'PUNCH OUT',
                      icon: Icons.logout,
                      color: Colors.red,
                      onPressed: () {
                        _openPunchCamera(
                          context,
                          false,
                        );
                      },
                    ),
                  ),
                ],
              ),

              const Spacer(),

              const Text(
                'ADHUNIK.01 • Smart Attendance System',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

class _PunchButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _PunchButton({
    required this.title,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(22),
          ),
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
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PunchSuccessCard extends StatelessWidget {
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
