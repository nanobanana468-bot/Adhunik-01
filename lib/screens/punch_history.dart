import 'package:flutter/material.dart';

import '../services/database_service.dart';

class PunchHistoryScreen extends StatefulWidget {
  const PunchHistoryScreen({super.key});

  @override
  State<PunchHistoryScreen> createState() =>
      _PunchHistoryScreenState();
}

class _PunchHistoryScreenState
    extends State<PunchHistoryScreen> {
  List<Map<String, dynamic>> _punches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPunchHistory();
  }

  Future<void> _loadPunchHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final punches =
          await DatabaseService.getPunches();

      if (!mounted) return;

      setState(() {
        _punches = punches;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'History load failed: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDateTime(String value) {
    try {
      final dateTime = DateTime.parse(value);

      final day =
          dateTime.day.toString().padLeft(2, '0');

      final month =
          dateTime.month.toString().padLeft(2, '0');

      final year =
          dateTime.year.toString();

      final hour =
          dateTime.hour.toString().padLeft(2, '0');

      final minute =
          dateTime.minute.toString().padLeft(2, '0');

      final second =
          dateTime.second.toString().padLeft(2, '0');

      return '$day/$month/$year  '
          '$hour:$minute:$second';
    } catch (_) {
      return value;
    }
  }

  Color _punchColor(String punchType) {
    if (punchType.toUpperCase() == 'IN') {
      return Colors.green;
    }

    return Colors.red;
  }

  IconData _punchIcon(String punchType) {
    if (punchType.toUpperCase() == 'IN') {
      return Icons.login;
    }

    return Icons.logout;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Punch History',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _loadPunchHistory,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _punches.isEmpty
              ? RefreshIndicator(
                  onRefresh: _loadPunchHistory,
                  child: ListView(
                    children: const [
                      SizedBox(height: 160),
                      Icon(
                        Icons.history,
                        size: 80,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Center(
                        child: Text(
                          'No punch records found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      Center(
                        child: Text(
                          'IN / OUT records will appear here.',
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPunchHistory,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _punches.length,
                    itemBuilder: (context, index) {
                      final punch = _punches[index];

                      final punchType =
                          (punch['punchType'] ?? 'IN')
                              .toString()
                              .toUpperCase();

                      final name =
                          (punch['employeeName'] ?? '')
                              .toString();

                      final employeeId =
                          (punch['employeePunchingId'] ?? '')
                              .toString();

                      final punchTime =
                          (punch['punchTime'] ?? '')
                              .toString();

                      final synced =
                          punch['synced'] == 1;

                      final color =
                          _punchColor(punchType);

                      return Card(
                        margin:
                            const EdgeInsets.only(
                          bottom: 12,
                        ),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding:
                              const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color:
                                      color.withValues(
                                    alpha: 0.12,
                                  ),
                                  shape:
                                      BoxShape.circle,
                                ),
                                child: Icon(
                                  _punchIcon(
                                    punchType,
                                  ),
                                  color: color,
                                  size: 28,
                                ),
                              ),

                              const SizedBox(width: 14),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name.isEmpty
                                          ? 'Unknown Employee'
                                          : name,
                                      style:
                                          const TextStyle(
                                        fontSize: 17,
                                        fontWeight:
                                            FontWeight.bold,
                                      ),
                                    ),

                                    const SizedBox(
                                      height: 4,
                                    ),

                                    Text(
                                      'ID: $employeeId',
                                      style:
                                          const TextStyle(
                                        color:
                                            Colors.grey,
                                      ),
                                    ),

                                    const SizedBox(
                                      height: 5,
                                    ),

                                    Text(
                                      _formatDateTime(
                                        punchTime,
                                      ),
                                      style:
                                          const TextStyle(
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 8),

                              Column(
                                children: [
                                  Container(
                                    padding:
                                        const EdgeInsets
                                            .symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration:
                                        BoxDecoration(
                                      color: color
                                          .withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius:
                                          BorderRadius
                                              .circular(
                                        20,
                                      ),
                                    ),
                                    child: Text(
                                      punchType,
                                      style: TextStyle(
                                        color: color,
                                        fontWeight:
                                            FontWeight.bold,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 6,
                                  ),

                                  Icon(
                                    synced
                                        ? Icons.cloud_done
                                        : Icons
                                            .cloud_upload,
                                    size: 18,
                                    color: synced
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
