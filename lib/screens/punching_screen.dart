import 'package:flutter/material.dart';

class PunchingScreen extends StatelessWidget {
  const PunchingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ADHUNIK.01',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.person_add_alt_1),
            tooltip: 'Employee Registration',
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.history),
            tooltip: 'History',
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings),
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

              Row(
                children: [
                  Expanded(
                    child: _PunchButton(
                      title: 'PUNCH IN',
                      icon: Icons.login,
                      color: Colors.green,
                      onPressed: () {},
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: _PunchButton(
                      title: 'PUNCH OUT',
                      icon: Icons.logout,
                      color: Colors.red,
                      onPressed: () {},
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
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 52),
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
