import 'package:supabase_flutter/supabase_flutter.dart';

// Define role enum to match database
enum UserRole { lender, contractor, inspector }

class AuthService {
  final _supabase = Supabase.instance.client;

  Future<User?> signUp({
    required String email,
    required String password,
    required String fullName,
    required UserRole role, // Add role parameter
  }) async {
    try {
      // communicates with Authentication backend.
      final AuthResponse response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName, // this becomes "Display Name" on Supabase.
        },
      );
      if (response.user == null) {
        throw Exception('Authentication sign up failed: No user returned');
      }

      // Communicates with Database backend.
      // Create user profile in user_profiles table with correct role enum
      await _supabase.from('user_profiles').insert({
        'id': response.user!.id,
        'email': email,
        'password': password, // Note: Consider if you really need to store this
        'full_name': fullName,
        'user_role': role.name, // This will match your database enum
      });
      return response.user;
    } catch (e) {
      throw Exception('Signup error: $e');
    }
  }

  Future<Map<String, dynamic>?> signIn({
    required String email,
    required String password,
  }) async {
    // only lets the user in IF there are no exceptions thrown. 
    try {
      final AuthResponse response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Sign in failed: No user returned');
      }
      final userData = await _supabase
          .from('user_profiles')
          .select()
          .eq('id', response.user!.id)
          .single();
      return userData;
    } catch (e) {
      throw Exception('Sign in error: $e');
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final userData =
          await _supabase.from('user_profiles').select().eq('id', user.id).single();
      return userData;
    } catch (e) {
      return null;
    }
  }

  Stream<AuthState> authStateChanges() {
    return _supabase.auth.onAuthStateChange;
  }

  // Helper method to get user role
  Future<UserRole?> getUserRole(String userId) async {
    try {
      final userData = await _supabase
          .from('user_profiles')
          .select('user_role')
          .eq('id', userId)
          .single();

      return UserRole.values.firstWhere(
        (role) => role.name == userData['role'],
      );
    } catch (e) {
      return null;
    }
  }
}
