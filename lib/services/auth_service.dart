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
      final AuthResponse response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'role': role.name, // Include role in auth metadata
        },
      );

      if (response.user == null) {
        throw Exception('Sign up failed: No user returned');
      }

      // Create user profile in users table with correct role enum
      await _supabase.from('users').insert({
        'id': response.user!.id,
        'email': email,
        'password': password, // Note: Consider if you really need to store this
        'full_name': fullName,
        'role': role.name, // This will match your database enum
      });

      return response.user;
    } catch (e) {
      throw Exception('Sign up failed: $e');
    }
  }

  Future<Map<String, dynamic>?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final AuthResponse response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null)
        throw Exception('Sign in failed: No user returned');

      // Get user data including role
      final userData = await _supabase
          .from('users')
          .select()
          .eq('id', response.user!.id)
          .single();

      return userData;
    } catch (e) {
      throw Exception('Sign in failed: $e');
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
          await _supabase.from('users').select().eq('id', user.id).single();
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
          .from('users')
          .select('role')
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
