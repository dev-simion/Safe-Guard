import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase/supabase_config.dart'; // Changed from 'supabase_service.dart'

class UserService {
  static SupabaseClient get _client =>
      SupabaseConfig.client; // Use SupabaseConfig

  // Get current user profile
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;

      final response =
          await _client.from('users').select().eq('id', user.id).maybeSingle();

      // If no profile exists, create one
      if (response == null) {
        final created = await _ensureUserProfileExists();
        if (!created) return null;

        // Try to fetch again after creating
        final newResponse = await _client
            .from('users')
            .select()
            .eq('id', user.id)
            .maybeSingle();
        return newResponse;
      }

      return response;
    } catch (e) {
      print('Error fetching user profile: $e');
      rethrow; // Rethrow to see actual error
    }
  }

  // Ensure user profile exists in database
  static Future<bool> _ensureUserProfileExists() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        print('No user found in _ensureUserProfileExists');
        return false;
      }

      // Check if profile already exists
      final existing = await _client
          .from('users')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();

      if (existing != null) {
        print('User profile already exists');
        return true;
      }

      final data = {
        'id': user.id,
        'email': user.email ?? '',
        'full_name': user.userMetadata?['full_name'] ?? 'User',
        'emergency_contacts': [], // Empty JSON array
        'medical_info': '',
      };

      print('Creating user profile with data: $data');
      await _client.from('users').insert(data);
      print('User profile created successfully');
      return true;
    } catch (e) {
      print('Error ensuring user profile exists: $e');
      print('Error details: ${e.toString()}');
      return false;
    }
  }

  // Create or update user profile
  static Future<bool> upsertUserProfile({
    required String email,
    required String fullName,
    String? phoneNumber,
    List<Map<String, String>>? emergencyContacts,
    String? medicalInfo,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;

      final data = {
        'id': user.id,
        'email': email,
        'full_name': fullName,
        if (phoneNumber != null) 'phone_number': phoneNumber,
        if (emergencyContacts != null)
          'emergency_contacts': emergencyContacts
              .map((c) => Map<String, dynamic>.from(c))
              .toList(),
        if (medicalInfo != null) 'medical_info': medicalInfo,
      };

      await _client.from('users').upsert(data);
      return true;
    } catch (e) {
      print('Error upserting user profile: $e');
      return false;
    }
  }

  // Update emergency contacts
  static Future<bool> updateEmergencyContacts(
      List<Map<String, String>> contacts) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        print('No authenticated user found');
        return false;
      }

      print('Updating emergency contacts for user: ${user.id}');
      print('Contacts to update: $contacts');

      // Ensure user profile exists first
      final profileExists = await _ensureUserProfileExists();
      if (!profileExists) {
        print('Failed to ensure user profile exists');
        return false;
      }

      // Convert to proper JSON format
      final contactsJson = contacts.map((contact) {
        return {
          'name': contact['name'] ?? '',
          'phone': contact['phone'] ?? '',
          'relationship': contact['relationship'] ?? '',
        };
      }).toList();

      print('Converted contacts JSON: $contactsJson');

      final result = await _client
          .from('users')
          .update({'emergency_contacts': contactsJson})
          .eq('id', user.id)
          .select();

      print('Emergency contacts update result: $result');

      if (result.isEmpty) {
        print(
            'Update returned empty result - this might indicate no rows were updated');
        return false;
      }

      return true;
    } catch (e) {
      print('Error updating emergency contacts: $e');
      print('Error type: ${e.runtimeType}');
      print('Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  // Update medical information
  static Future<bool> updateMedicalInfo(String medicalInfo) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        print('No authenticated user found');
        return false;
      }

      // Ensure user profile exists first
      final profileExists = await _ensureUserProfileExists();
      if (!profileExists) {
        print('Failed to ensure user profile exists');
        return false;
      }

      final result = await _client
          .from('users')
          .update({'medical_info': medicalInfo})
          .eq('id', user.id)
          .select();

      print('Medical info update result: $result');
      return result.isNotEmpty;
    } catch (e) {
      print('Error updating medical info: $e');
      return false;
    }
  }

  // Update phone number
  static Future<bool> updatePhoneNumber(String phoneNumber) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        print('No authenticated user found');
        return false;
      }

      // Ensure user profile exists first
      final profileExists = await _ensureUserProfileExists();
      if (!profileExists) {
        print('Failed to ensure user profile exists');
        return false;
      }

      final result = await _client
          .from('users')
          .update({'phone_number': phoneNumber})
          .eq('id', user.id)
          .select();

      print('Phone number update result: $result');
      return result.isNotEmpty;
    } catch (e) {
      print('Error updating phone number: $e');
      return false;
    }
  }

  // Delete/clear specific user data (but not email or core profile)
  static Future<bool> clearUserData({
    bool clearEmergencyContacts = false,
    bool clearMedicalInfo = false,
    bool clearPhoneNumber = false,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        print('No authenticated user found');
        return false;
      }

      final updateData = <String, dynamic>{};

      if (clearEmergencyContacts) {
        updateData['emergency_contacts'] = [];
      }

      if (clearMedicalInfo) {
        updateData['medical_info'] = '';
      }

      if (clearPhoneNumber) {
        updateData['phone_number'] = null;
      }

      if (updateData.isEmpty) return true;

      final result = await _client
          .from('users')
          .update(updateData)
          .eq('id', user.id)
          .select();

      print('Clear user data result: $result');
      return result.isNotEmpty;
    } catch (e) {
      print('Error clearing user data: $e');
      return false;
    }
  }

  // Update full name (but not email - that's managed by auth)
  static Future<bool> updateFullName(String fullName) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        print('No authenticated user found');
        return false;
      }

      // Ensure user profile exists first
      final profileExists = await _ensureUserProfileExists();
      if (!profileExists) {
        print('Failed to ensure user profile exists');
        return false;
      }

      final result = await _client
          .from('users')
          .update({'full_name': fullName})
          .eq('id', user.id)
          .select();

      print('Full name update result: $result');
      return result.isNotEmpty;
    } catch (e) {
      print('Error updating full name: $e');
      return false;
    }
  }
}