import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:guardian_shield/auth/auth_manager.dart';
import 'package:guardian_shield/supabase/supabase_config.dart';
import 'package:guardian_shield/models/user_profile.dart';

class SupabaseAuthManager extends AuthManager with EmailSignInManager {
  final _auth = SupabaseConfig.auth;
  final _client = SupabaseConfig.client;

  @override
  supabase.User? get currentUser => _auth.currentUser;

  @override
  Stream<supabase.AuthState> get authStateChanges => _auth.onAuthStateChange;

  @override
  Future<supabase.User?> signInWithEmail(
    BuildContext context,
    String email,
    String password,
  ) async {
    try {
      final response = await _auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response.user;
    } on supabase.AuthException catch (e) {
      if (context.mounted) {
        _showError(context, e.message);
      }
      return null;
    } catch (e) {
      if (context.mounted) {
        _showError(context, 'Failed to sign in: ${e.toString()}');
      }
      return null;
    }
  }

  @override
  Future<supabase.User?> createAccountWithEmail(
    BuildContext context,
    String email,
    String password, {
    String? fullName,
  }) async {
    try {
      final response = await _auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await _createUserProfile(response.user!, fullName: fullName);
      }

      return response.user;
    } on supabase.AuthException catch (e) {
      if (context.mounted) {
        _showError(context, e.message);
      }
      return null;
    } catch (e) {
      if (context.mounted) {
        _showError(context, 'Failed to create account: ${e.toString()}');
      }
      return null;
    }
  }

  Future<void> _createUserProfile(supabase.User user, {String? fullName}) async {
    try {
      final userProfile = UserProfile(
        id: user.id,
        email: user.email ?? '',
        fullName: fullName ?? user.userMetadata?['full_name'] ?? '',
        phoneNumber: user.phone,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _client.from('users').insert(userProfile.toJson());
    } catch (e) {
      debugPrint('Failed to create user profile: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Failed to sign out: $e');
    }
  }

  @override
  Future<void> deleteUser(BuildContext context) async {
    try {
      final user = currentUser;
      if (user != null) {
        await _client.from('users').delete().eq('id', user.id);
        await _client.rpc('delete_user');
      }
    } catch (e) {
      if (context.mounted) {
        _showError(context, 'Failed to delete account: ${e.toString()}');
      }
    }
  }

  @override
  Future<void> updateEmail({
    required String email,
    required BuildContext context,
  }) async {
    try {
      await _auth.updateUser(supabase.UserAttributes(email: email));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email updated successfully')),
        );
      }
    } on supabase.AuthException catch (e) {
      if (context.mounted) {
        _showError(context, e.message);
      }
    }
  }

  @override
  Future<void> resetPassword({
    required String email,
    required BuildContext context,
  }) async {
    try {
      await _auth.resetPasswordForEmail(email);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset email sent')),
        );
      }
    } on supabase.AuthException catch (e) {
      if (context.mounted) {
        _showError(context, e.message);
      }
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
