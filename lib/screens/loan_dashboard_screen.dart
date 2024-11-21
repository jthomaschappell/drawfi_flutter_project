import 'package:flutter/material.dart';

class LoanDashboardScreen extends StatefulWidget {
  const LoanDashboardScreen({super.key});

  @override
  State<LoanDashboardScreen> createState() => _LoanDashboardScreenState();
}

class _LoanDashboardScreenState extends State<LoanDashboardScreen> {
  Widget _buildTopNav() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[400],
        borderRadius: BorderRadiusDirectional.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.only(
          left: 60.0,
          right: 60.0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var item in [
              'Home',
              'Notifications',
              'User Config',
              'Settings'
            ])
              TextButton(
                onPressed: () {},
                child: Text(item, style: const TextStyle(color: Colors.white)),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(
              top: 16.0,
              bottom: 16.0,
              left: 8.0,
              right: 8.0,
            ),
            child: _buildTopNav(),
          ),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 250,
                  color: Colors.grey[200],
                ), // Placeholder sidebar
                const Expanded(child: Center(child: Text('Main Content'))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
