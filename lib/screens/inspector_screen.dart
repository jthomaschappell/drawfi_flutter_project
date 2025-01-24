import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tester/loan_dashboard/lender_loan_screen.dart';
import 'package:tester/screens/inspector_loan_screen.dart';
import 'package:tester/screens/path_to_auth_screen/auth_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


final supabase = Supabase.instance.client;

class InspectorScreen extends StatefulWidget {
  final Map<String, dynamic> userProfile;

  const InspectorScreen({
    super.key,
    required this.userProfile,
  });

  @override
  State<InspectorScreen> createState() => _InspectorScreenState();
}

class _InspectorScreenState extends State<InspectorScreen> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth > 600 ? 24.0 : 16.0;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(horizontalPadding),
                  child: _buildHeader(),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hi Hannah,',
                        style: TextStyle(
                          fontSize: screenWidth > 600 ? 28 : 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '9 Active Projects',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            _buildSearchBar(),
            _buildTabBar(),
            Expanded(
              child: _buildProjectsList(),
            ),
            _buildBottomNavBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          SvgPicture.string(
            '''<svg width="40" height="40" viewBox="0 0 1531 1531" fill="none" xmlns="http://www.w3.org/2000/svg">
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
            </svg>''',
            width: 40,
            height: 40,
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
          ),
        ],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        style: TextStyle(
          color: Colors.black87,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: 'Search projects...',
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          fillColor: Colors.white,
          filled: true,
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            'Recently Opened',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 24),
          Text(
            'All Projects',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

 Widget _buildProjectsList() {
 return ListView.builder(
   padding: EdgeInsets.all(16),
   itemCount: 3,
   itemBuilder: (context, index) {
     return InkWell(
       onTap: () {
         Navigator.push(
           context,
           MaterialPageRoute(
             builder: (context) => InspectorLoanScreen(
               projectData: {
                 'name': 'KDK Construction',
                 'location': 'American Fork, UT', 
                 'lastInspection': '1/9/25',
                 'completion': '50',
                 'nextInspection': '1/16/25',
               },
             ),
           ),
         );
       },
       child: Container(
         margin: EdgeInsets.only(bottom: 16),
         decoration: BoxDecoration(
           border: Border.all(color: Colors.grey[200]!),
           borderRadius: BorderRadius.circular(12),
         ),
         child: Padding(
           padding: EdgeInsets.all(16),
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Row(
                 children: [
                   Container(
                     width: 48,
                     height: 48,
                     decoration: BoxDecoration(
                       color: Colors.purple,
                       borderRadius: BorderRadius.circular(8),
                     ),
                     child: Center(
                       child: Text(
                         'KD',
                         style: TextStyle(
                           color: Colors.white,
                           fontWeight: FontWeight.bold,
                         ),
                       ),
                     ),
                   ),
                   const SizedBox(width: 12),
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text(
                           'KDK Construction',
                           style: TextStyle(
                             fontSize: 16,
                             fontWeight: FontWeight.w600,
                             color: Colors.black87,
                           ),
                         ),
                         Row(
                           children: [
                             Icon(Icons.location_on, size: 16, color: Colors.grey),
                             Text(
                               'American Fork, UT',
                               style: TextStyle(
                                 color: Colors.grey,
                               ),
                             ),
                           ],
                         ),
                       ],
                     ),
                   ),
                   Container(
                     padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                     decoration: BoxDecoration(
                       color: Colors.green[50],
                       borderRadius: BorderRadius.circular(12),
                     ),
                     child: Row(
                       children: [
                         Icon(Icons.check_circle, size: 16, color: Colors.green),
                         const SizedBox(width: 4),
                         Text(
                           'On track',
                           style: TextStyle(
                             color: Colors.green,
                             fontSize: 12,
                           ),
                         ),
                       ],
                     ),
                   ),
                 ],
               ),
               const SizedBox(height: 16),
               Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   _buildInfoColumn('Last Inspection', '1/9/25'),
                   _buildInfoColumn('Completed', '50%'),
                   _buildInfoColumn('Next Inspection', '1/16/25'),
                 ],
               ),
             ],
           ),
         ),
       ),
     );
   },
 );
}


  Widget _buildInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home, true),
          _buildNavItem(Icons.notifications_none, false),
          _buildNavItem(Icons.calendar_today, false),
          _buildNavItem(Icons.settings, false),
        ],
      ),
    );
  }

Widget _buildNavItem(IconData icon, bool isSelected) {
    return IconButton(
      icon: Icon(
        icon,
        color: isSelected ? Colors.purple : Colors.grey,
      ),
      onPressed: () {
        if (icon == Icons.settings) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Settings'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: Icon(Icons.logout, color: Colors.red),
                      title: Text('Log out'),
                      onTap: () async {
                        await supabase.auth.signOut();
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) => const AuthScreen(),
                          ),
                          (route) => false,
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        }
      },
    );
  }
}