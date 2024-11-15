import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tester/services/auth_service.dart';

class LenderScreen extends StatefulWidget {
  final User user;
  const LenderScreen({
    super.key,
    required this.user,
  });

  @override
  State<LenderScreen> createState() => _LenderScreenState();
}

class _LenderScreenState extends State<LenderScreen> {
  final authService = AuthService();
  final supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    print("This is the widget user passed in: ${widget.user}");
    print("The user id: ${widget.user.id}");
    

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Welcome to DrawFi, lender!!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: authService.signOut,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  Future<String?> _getUserRole(String userId) async {
    try {
      final data = await supabase
          .from('user_profiles')
          .select('user_role')
          .eq('id', userId)
          .limit(1)
          .single();
      print("Data: $data");
      print("Data role: ${data['user_role']}");
      /**
       * TODO: 
       * Press the button and see that the data is: 
       * I think that it's the data for Chretien. 
       */

      return data['user_role'];
    } catch (e) {
      print("Error: $e");
      return null;
    }
  }
}
