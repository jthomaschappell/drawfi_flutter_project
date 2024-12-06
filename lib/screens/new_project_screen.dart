import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

const String _logoSvg = '''
<svg width="1531" height="1531" viewBox="0 0 1531 1531" fill="none" xmlns="http://www.w3.org/2000/svg">
<rect width="1531" height="1531" rx="200" fill="url(#paint0_linear_82_170)"/>
<ellipse cx="528" cy="429.5" rx="136.5" ry="136" transform="rotate(-90 528 429.5)" fill="white"/>
<circle cx="528" cy="1103" r="136" transform="rotate(-90 528 1103)" fill="white"/>
<circle cx="1001" cy="773" r="136" fill="white"/>
<ellipse cx="528" cy="774" rx="29" ry="28" fill="white"/>
<ellipse cx="808" cy="494" rx="29" ry="28" fill="white"/>
<ellipse cx="808" cy="1038.5" rx="29" ry="29.5" fill="white"/>
<defs>
<linearGradient id="paint0_linear_82_170" x1="1485.07" y1="0.00010633" x2="30.6199" y2="1485.07" gradientUnits="userSpaceOnUse">
<stop stop-color="#FF1970"/>
<stop offset="0.145" stop-color="#E81766"/>
<stop offset="0.307358" stop-color="#DB12AF"/>
<stop offset="0.43385" stop-color="#BF09D5"/>
<stop offset="0.556871" stop-color="#A200FA"/>
<stop offset="0.698313" stop-color="#6500E9"/>
<stop offset="0.855" stop-color="#3C17DB"/>
<stop offset="1" stop-color="#2800D7"/>
</linearGradient>
</defs>
</svg>
''';

class NewProjectScreen extends StatefulWidget {
  const NewProjectScreen({super.key});

  @override
  State<NewProjectScreen> createState() => _NewProjectScreenState();
}

class _NewProjectScreenState extends State<NewProjectScreen> {
  String _searchQuery = '';
  int _selectedNavIndex = 0;

  final List<Map<String, dynamic>> _projects = List.generate(
    4,
    (index) => {
      'name': 'KDK Construction',
      'address': '1024 S. Parkway Ave',
      'location': 'American Fork, UT',
      'disbursed': '16%',
      'actions': '0',
      'status': 'On Track',
    },
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Navigation Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Row(
              children: [
                // Logo
                SvgPicture.string(
                  _logoSvg,
                  height: 32,
                  width: 32,
                ),
                const SizedBox(width: 24),

                // Navigation Icons
                Row(
                  children: [
                    _buildNavIcon(
                      Icons.home_outlined,
                      isSelected: _selectedNavIndex == 0,
                      onTap: () => setState(() => _selectedNavIndex = 0),
                    ),
                    const SizedBox(width: 16),
                    _buildNavIcon(
                      Icons.notifications_outlined,
                      isSelected: _selectedNavIndex == 1,
                      onTap: () => setState(() => _selectedNavIndex = 1),
                    ),
                    const SizedBox(width: 16),
                    _buildNavIcon(
                      Icons.settings_outlined,
                      isSelected: _selectedNavIndex == 2,
                      onTap: () => setState(() => _selectedNavIndex = 2),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Hi This file is not being used,',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.add, size: 20),
                        label: const Text('New Project'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Search Bar
                  Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white, // Background of the search bar
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: const Color.fromARGB(255, 0, 0, 0)),
                    ),
                    child: TextField(
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                      style: const TextStyle(
                        color: Colors.black, // Black text color
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Search by name, loan #, etc...',
                        hintStyle: TextStyle(
                          color: Color.fromARGB(
                              255, 0, 0, 0), // Gray hint text color
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color:
                              Color.fromARGB(255, 0, 0, 0), // Search icon color
                        ),
                        fillColor: Colors.white, // Background behind text
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Recently Opened
                  const Text(
                    'Recently Opened',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Project List
                  Expanded(
                    child: ListView.builder(
                      itemCount: _projects.length,
                      itemBuilder: (context, index) =>
                          _buildProjectCard(_projects[index]),
                      padding: EdgeInsets.zero,
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

  Widget _buildNavIcon(IconData icon,
      {required bool isSelected, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(
        icon,
        color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF6B7280),
      ),
    );
  }

  Widget _buildProjectCard(Map<String, dynamic> project) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'KD',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project['name'],
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1F2937),
                  ),
                ),
                Text(
                  project['address'],
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 14,
                  ),
                ),
                Text(
                  project['location'],
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 14,
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
