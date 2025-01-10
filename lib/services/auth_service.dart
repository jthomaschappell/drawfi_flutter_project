import 'package:supabase_flutter/supabase_flutter.dart';

// Define role enum to match database
enum UserRole { lender, contractor, inspector, borrower }

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
      
      // Create user in the users table 
      // Create a borrower, lender, etc. based on the role. 

      // : 
      // See if you can sign up and it creates a user in the users table. 

      await _supabase.from('users').insert({
        'user_id': response.user!.id,
        'email': email,
        'name': fullName
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
          .from('users')
          .select()
          .eq('user_id', response.user!.id)
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
      final userData = await _supabase
          .from('users')
          .select()
          .eq('user_id', user.id)
          .single();
      return userData;
    } catch (e) {
      return null;
    }
  }

  Stream<AuthState> authStateChanges() {
    return _supabase.auth.onAuthStateChange;
  }

  Future<UserRole?> getUserRole(String userId) async {
    try {
      // Check each table for the user's ID
      try {
        await _supabase
            .from('borrowers')
            .select('borrower_id')
            .eq('borrower_id', userId)
            .single();
        return UserRole.borrower;
      } catch (_) {
        print("The id was not found in borrowers.");
      }

      try {
        await _supabase
            .from('lenders')
            .select('lender_id')
            .eq('lender_id', userId)
            .single();
        return UserRole.lender;
      } catch (_) {
        print("The id was not found in lenders.");
      }

      try {
        await _supabase
            .from('contractors')
            .select('contractor_id')
            .eq('contractor_id', userId)
            .single();
        return UserRole.contractor;
      } catch (_) {
        print("The id was not found in contractors.");
      }

      try {
        await _supabase
            .from('inspectors')
            .select('inspector_id')
            .eq('inspector_id', userId)
            .single();
        return UserRole.inspector;
      } catch (_) {
        print("The id was not found in inspectors.");
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
