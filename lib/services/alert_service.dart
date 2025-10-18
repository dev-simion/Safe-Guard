import 'package:guardian_shield/models/emergency_alert.dart';
import 'package:guardian_shield/services/supabase_service.dart';
import 'package:uuid/uuid.dart';

class AlertService {
  static const _uuid = Uuid();

  Future<EmergencyAlert?> createAlert({
    required String userId,
    required AlertType type,
    required double latitude,
    required double longitude,
    String? locationAddress,
    bool isSilent = false,
    String? notes,
  }) async {
    try {
      final alert = EmergencyAlert(
        id: _uuid.v4(),
        userId: userId,
        type: type,
        latitude: latitude,
        longitude: longitude,
        locationAddress: locationAddress,
        isSilent: isSilent,
        notes: notes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await SupabaseService.client
          .from('emergency_alerts')
          .insert(alert.toJson());

      return alert;
    } catch (e) {
      return null;
    }
  }

  Future<List<EmergencyAlert>> getUserAlerts(String userId) async {
    try {
      final response = await SupabaseService.client
          .from('emergency_alerts')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => EmergencyAlert.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<EmergencyAlert?> getActiveAlert(String userId) async {
    try {
      final response = await SupabaseService.client
          .from('emergency_alerts')
          .select()
          .eq('user_id', userId)
          .eq('status', AlertStatus.active.name)
          .order('created_at', ascending: false)
          .limit(1)
          .single();

      return EmergencyAlert.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateAlertStatus(String alertId, AlertStatus status) async {
    try {
      await SupabaseService.client
          .from('emergency_alerts')
          .update({
            'status': status.name,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', alertId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> addMediaToAlert(String alertId, List<String> mediaUrls) async {
    try {
      await SupabaseService.client
          .from('emergency_alerts')
          .update({
            'media_urls': mediaUrls,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', alertId);
      return true;
    } catch (e) {
      return false;
    }
  }
}
