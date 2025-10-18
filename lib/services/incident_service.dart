import 'package:guardian_shield/models/public_incident.dart';
import 'package:guardian_shield/services/supabase_service.dart';
import 'package:uuid/uuid.dart';

class IncidentService {
  static const _uuid = Uuid();

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
      final incident = PublicIncident(
        id: _uuid.v4(),
        userId: userId,
        title: title,
        description: description,
        latitude: latitude,
        longitude: longitude,
        locationAddress: locationAddress,
        mediaUrls: mediaUrls,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await SupabaseService.client
          .from('public_incidents')
          .insert(incident.toJson());

      return incident;
    } catch (e) {
      return null;
    }
  }

  Future<List<PublicIncident>> getAllIncidents() async {
    try {
      final response = await SupabaseService.client
          .from('public_incidents')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => PublicIncident.fromJson(json))
          .toList();
    } catch (e) {
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

      await SupabaseService.client
          .from('public_incidents')
          .update({
            'upvotes': upvotedBy.length,
            'downvotes': downvotedBy.length,
            'upvoted_by': upvotedBy,
            'downvoted_by': downvotedBy,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', incidentId);

      return true;
    } catch (e) {
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

      await SupabaseService.client
          .from('public_incidents')
          .update({
            'upvotes': upvotedBy.length,
            'downvotes': downvotedBy.length,
            'upvoted_by': upvotedBy,
            'downvoted_by': downvotedBy,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', incidentId);

      return true;
    } catch (e) {
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
      return null;
    }
  }
}
