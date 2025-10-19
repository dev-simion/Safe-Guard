import 'package:guardian_shield/models/public_incident.dart';
import 'package:guardian_shield/services/supabase_service.dart';
import 'package:guardian_shield/services/location_service.dart';
import 'package:guardian_shield/services/user_service.dart';

class IncidentService {
  // Test database connectivity
  Future<void> testDatabaseConnection() async {
    try {
      print('🧪 Testing database connection...');
      
      // Test 1: Check auth
      final user = SupabaseService.client.auth.currentUser;
      print('🔐 User: ${user?.id ?? 'NOT AUTHENTICATED'}');
      
      if (user == null) {
        print('❌ Cannot test database - user not authenticated');
        return;
      }
      
      // Test 2: Try to access the incidents table
      print('🔍 Testing incidents table access...');
      await SupabaseService.client
          .from('public_incidents')
          .select('id')
          .limit(1);
      print('✅ Database connection test passed - can access incidents table');
      
    } catch (e) {
      print('❌ Database connection test failed: $e');
    }
  }

  Future<PublicIncident?> createIncident({
    required String userId,
    required String title,
    required String description,
    required double latitude,
    required double longitude,
    String? locationAddress,
    List<String> mediaUrls = const [],
  }) async {
    try {
      // Ensure user profile exists in database before creating incident
      print('🔍 Ensuring user profile exists for user: $userId');
      final userProfile = await UserService.getUserProfile();
      if (userProfile == null) {
        print('❌ User profile not found or could not be created');
        print('🔧 Attempting to create user profile...');
        
        // Try to create the user profile manually
        try {
          final user = SupabaseService.client.auth.currentUser;
          if (user != null) {
            final profileData = {
              'id': user.id,
              'email': user.email ?? '',
              'full_name': user.userMetadata?['full_name'] ?? 'User',
              'emergency_contacts': [],
              'medical_info': '',
            };
            
            await SupabaseService.client.from('users').insert(profileData);
            print('✅ User profile created successfully');
          }
        } catch (profileError) {
          print('❌ Failed to create user profile: $profileError');
          return null;
        }
      } else {
        print('✅ User profile confirmed: ${userProfile['full_name']}');
      }

      // Resolve location address if not provided
      String? resolvedAddress = locationAddress;
      if (resolvedAddress == null) {
        resolvedAddress = await LocationService.getAddressFromCoordinates(latitude, longitude);
      }

      // Create incident data without ID (let Supabase generate it)
      final incidentData = {
        'user_id': userId,
        'title': title,
        'description': description,
        'latitude': latitude,
        'longitude': longitude,
        'location_address': resolvedAddress,
        'media_urls': mediaUrls,
        'upvotes': 0,
        'downvotes': 0,
        'upvoted_by': <String>[],
        'downvoted_by': <String>[],
      };

      print('🛰 Inserting incident into Supabase...');
      print('📋 Incident data: $incidentData');
      print('👤 Current user ID: $userId');
      print('📍 Location: ${incidentData['latitude']}, ${incidentData['longitude']}');
      print('📝 Title: \"${incidentData['title']}\"');
      print('📄 Description: \"${incidentData['description']}\"');

      final response = await SupabaseService.client
          .from('public_incidents')
          .insert(incidentData)
          .select()
          .single(); // Add .single() to get the inserted record

      print('✅ Insert response: $response');
      print('🆔 Created incident ID: ${response['id']}');

      // Return the incident from the database response
      return PublicIncident.fromJson(response);
    } catch (e, stack) {
      print('❌ Failed to insert incident: $e');
      print(stack);
      return null;
    }
  }

  Future<List<PublicIncident>> getAllIncidents() async {
    try {
      // Check authentication first
      final user = SupabaseService.client.auth.currentUser;
      print('🔐 Current user: ${user?.id ?? 'NOT AUTHENTICATED'}');
      print('📧 User email: ${user?.email ?? 'NO EMAIL'}');
      
      if (user == null) {
        print('❌ User not authenticated - cannot fetch incidents');
        return [];
      }

      print('🔍 Attempting to fetch incidents...');
      
      // Test 1: Try a simple select first without ordering
      try {
        final simpleResponse = await SupabaseService.client
            .from('public_incidents')
            .select('id, title');
        print('📊 Simple query returned ${simpleResponse.length} records');
      } catch (simpleError) {
        print('❌ Simple query failed: $simpleError');
      }
      
      // Test 2: Full query with ordering
      final response = await SupabaseService.client
          .from('public_incidents')
          .select()
          .order('created_at', ascending: false);

      print('📋 Fetched ${response.length} incidents');
      print('📊 Raw response: $response');

      return (response as List)
          .map((json) => PublicIncident.fromJson(json))
          .toList();
    } catch (e, stack) {
      print('❌ Failed to fetch incidents: $e');
      print('🔍 Error type: ${e.runtimeType}');
      if (e.toString().contains('JWT')) {
        print('🔑 JWT/Authentication error detected');
      }
      if (e.toString().contains('RLS') || e.toString().contains('policy')) {
        print('🛡️ Row Level Security policy error detected');
      }
      print('📍 Stack trace: $stack');
      return [];
    }
  }

  Future<bool> upvoteIncident(String incidentId, String userId) async {
    try {
      final incident = await _getIncident(incidentId);
      if (incident == null) return false;

      final upvotedBy = List<String>.from(incident.upvotedBy);
      final downvotedBy = List<String>.from(incident.downvotedBy);

      if (downvotedBy.contains(userId)) {
        downvotedBy.remove(userId);
      }

      if (upvotedBy.contains(userId)) {
        upvotedBy.remove(userId);
      } else {
        upvotedBy.add(userId);
      }

      await SupabaseService.client.from('public_incidents').update({
        'upvotes': upvotedBy.length,
        'downvotes': downvotedBy.length,
        'upvoted_by': upvotedBy,
        'downvoted_by': downvotedBy,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', incidentId);

      return true;
    } catch (e) {
      print('❌ Failed to upvote: $e');
      return false;
    }
  }

  Future<bool> downvoteIncident(String incidentId, String userId) async {
    try {
      final incident = await _getIncident(incidentId);
      if (incident == null) return false;

      final upvotedBy = List<String>.from(incident.upvotedBy);
      final downvotedBy = List<String>.from(incident.downvotedBy);

      if (upvotedBy.contains(userId)) {
        upvotedBy.remove(userId);
      }

      if (downvotedBy.contains(userId)) {
        downvotedBy.remove(userId);
      } else {
        downvotedBy.add(userId);
      }

      await SupabaseService.client.from('public_incidents').update({
        'upvotes': upvotedBy.length,
        'downvotes': downvotedBy.length,
        'upvoted_by': upvotedBy,
        'downvoted_by': downvotedBy,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', incidentId);

      return true;
    } catch (e) {
      print('❌ Failed to downvote: $e');
      return false;
    }
  }

  Future<PublicIncident?> _getIncident(String incidentId) async {
    try {
      final response = await SupabaseService.client
          .from('public_incidents')
          .select()
          .eq('id', incidentId)
          .single();

      return PublicIncident.fromJson(response);
    } catch (e) {
      print('❌ Failed to get incident: $e');
      return null;
    }
  }
}