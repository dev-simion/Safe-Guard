import 'package:guardian_shield/models/public_incident.dart';
import 'package:guardian_shield/services/supabase_service.dart';
import 'package:guardian_shield/services/location_service.dart';

class IncidentService {
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
      print(incidentData);

      final response = await SupabaseService.client
          .from('public_incidents')
          .insert(incidentData)
          .select()
          .single(); // Add .single() to get the inserted record

      print('✅ Insert response: $response');

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
      final response = await SupabaseService.client
          .from('public_incidents')
          .select()
          .order('created_at', ascending: false);

      print('📋 Fetched ${response.length} incidents');

      return (response as List)
          .map((json) => PublicIncident.fromJson(json))
          .toList();
    } catch (e, stack) {
      print('❌ Failed to fetch incidents: $e');
      print(stack);
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