import 'package:flutter/material.dart';

class LoanDashboardScreen extends StatefulWidget {
  const LoanDashboardScreen({super.key});

  @override
  State<LoanDashboardScreen> createState() => _LoanDashboardScreenState();
}

class _LoanDashboardScreenState extends State<LoanDashboardScreen> {
  Widget _buildSearchBar() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search by name, loan #, etc...',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildTopNav() {
    return Container(
      height: 55.0,
      decoration: BoxDecoration(
        color: Colors.grey[400],
        borderRadius: BorderRadiusDirectional.circular(
          12.0,
        ),
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
      backgroundColor: Colors.white,
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
            child: Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 16.0),
              child: Row(
                children: [
                  // side bar.
                  Container(
                    width: 250,
                    decoration: BoxDecoration(
                      // color: Colors.grey[200],
                      // color: const Color(0xFFD32F2F),
                      // color: Colors("D4D4D4"),
                      // color: const Color(0x00d4d4d4),
                      borderRadius: BorderRadiusDirectional.circular(
                        12.0,
                      ),
                      border: Border.all(
                        color: Colors.black,
                        width: 0.5,
                      ),
                    ),
                  ),

                  // main content
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Main Content',
                        style: TextStyle(
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
