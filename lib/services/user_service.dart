import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class UserService {
  static final SupabaseClient _client = SupabaseService.client;

  // Get current user profile
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;

      final response = await _client
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      // If no profile exists, create one
      if (response == null) {
        await _ensureUserProfileExists();
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
      return null;
    }
  }

  // Ensure user profile exists in database
  static Future<bool> _ensureUserProfileExists() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;

      final data = {
        'id': user.id,
        'email': user.email ?? '',
        'full_name': user.userMetadata?['full_name'] ?? 'User',
        'emergency_contacts': <Map<String, String>>[],
        'medical_info': '',
      };

      await _client.from('users').upsert(data);
      return true;
    } catch (e) {
      print('Error ensuring user profile exists: $e');
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
        if (emergencyContacts != null) 'emergency_contacts': emergencyContacts,
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
  static Future<bool> updateEmergencyContacts(List<Map<String, String>> contacts) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        print('No authenticated user found');
        return false;
      }

      // Ensure user profile exists first
      await _ensureUserProfileExists();

      final result = await _client
          .from('users')
          .update({'emergency_contacts': contacts})
          .eq('id', user.id)
          .select();

      print('Emergency contacts update result: $result');
      return true;
    } catch (e) {
      print('Error updating emergency contacts: $e');
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
      await _ensureUserProfileExists();

      final result = await _client
          .from('users')
          .update({'medical_info': medicalInfo})
          .eq('id', user.id)
          .select();

      print('Medical info update result: $result');
      return true;
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
      await _ensureUserProfileExists();

      final result = await _client
          .from('users')
          .update({'phone_number': phoneNumber})
          .eq('id', user.id)
          .select();

      print('Phone number update result: $result');
      return true;
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
        updateData['emergency_contacts'] = <Map<String, String>>[];
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
      return true;
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
      await _ensureUserProfileExists();

      final result = await _client
          .from('users')
          .update({'full_name': fullName})
          .eq('id', user.id)
          .select();

      print('Full name update result: $result');
      return true;
    } catch (e) {
      print('Error updating full name: $e');
      return false;
    }
  }
}