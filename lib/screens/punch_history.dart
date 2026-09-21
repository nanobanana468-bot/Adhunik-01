import 'package:flutter/material.dart';

import '../../services/database_service.dart';

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
    _loadPunches();
  }

  Future<void> _loadPunches() async {
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
            'History load nahi ho payi: $e',
          ),
        ),
      );
    }
  }

  String _formatDateTime(String value) {
    final dateTime = DateTime.tryParse(value);

    if (dateTime == null) {
      return value;
    }

    final day =
        dateTime.day.toString().padLeft(2, '0');
    final month =
        dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year.toString();

    final hour =
        dateTime.hour.toString().padLeft(2, '0');
    final minute =
        dateTime.minute.toString().padLeft(2, '0');
    final second =
        dateTime.second.toString().padLeft(2, '0');

    return '$day/$month/$year  '
        '$hour:$minute:$second';
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
            onPressed: _loadPunches,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_punches.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadPunches,
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 180),
            Icon(
              Icons.history,
              size: 70,
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
                'Your IN/OUT punches will appear here.',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPunches,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _punches.length,
        separatorBuilder: (_, __) =>
            const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final punch = _punches[index];

          final punchType =
              punch['punchType']?.toString() ?? '';

          final isIn = punchType == 'IN';

          final name =
              punch['employeeName']?.toString() ??
                  'Unknown Employee';

          final punchingId =
              punch['employeePunchingId']
                      ?.toString() ??
                  '';

          final punchTime =
              punch['punchTime']?.toString() ?? '';

          final synced =
              punch['synced'] == 1;

          return Card(
            elevation: 3,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isIn
                          ? Colors.green
                              .withValues(alpha: 0.12)
                          : Colors.red
                              .withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isIn
                          ? Icons.login
                          : Icons.logout,
                      color: isIn
                          ? Colors.green
                          : Colors.red,
                      size: 27,
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          'ID: $punchingId',
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          _formatDateTime(punchTime),
                          style: const TextStyle(
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Row(
                          children: [
                            Icon(
                              synced
                                  ? Icons.cloud_done
                                  : Icons.cloud_off,
                              size: 15,
                              color: synced
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              synced
                                  ? 'Synced'
                                  : 'Pending Sync',
                              style: TextStyle(
                                fontSize: 12,
                                color: synced
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isIn
                          ? Colors.green
                          : Colors.red,
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                    child: Text(
                      punchType,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
