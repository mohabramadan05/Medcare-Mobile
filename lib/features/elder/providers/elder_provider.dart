import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/elder_model.dart';

SupabaseClient get _client => Supabase.instance.client;

final userEldersProvider = FutureProvider<List<ElderModel>>((ref) async {
  final userId = _client.auth.currentUser?.id;
  if (userId == null) return [];
  final data = await _client
      .from('user_elders')
      .select('elder_id, elders(*)')
      .eq('user_id', userId);
  return (data as List)
      .map((e) => ElderModel.fromJson(e['elders'] as Map<String, dynamic>))
      .toList();
});

final elderDetailProvider =
    FutureProvider.family<ElderModel?, String>((ref, id) async {
  final data =
      await _client.from('elders').select().eq('id', id).maybeSingle();
  if (data == null) return null;
  return ElderModel.fromJson(data);
});

final elderVitalsProvider =
    FutureProvider.family<List<ElderVitalsModel>, String>((ref, elderId) async {
  final data = await _client
      .from('elder_vitals')
      .select()
      .eq('elder_id', elderId)
      .order('measured_at', ascending: false);
  return (data as List).map((e) => ElderVitalsModel.fromJson(e)).toList();
});

final elderMedicationsProvider =
    FutureProvider.family<List<ElderMedicationModel>, String>(
        (ref, elderId) async {
  final data = await _client
      .from('elder_medications')
      .select()
      .eq('elder_id', elderId);
  return (data as List).map((e) => ElderMedicationModel.fromJson(e)).toList();
});

final elderHealthRecordsProvider =
    FutureProvider.family<List<ElderHealthRecordModel>, String>(
        (ref, elderId) async {
  final data = await _client
      .from('elder_health_records')
      .select()
      .eq('elder_id', elderId)
      .order('record_date', ascending: false);
  return (data as List)
      .map((e) => ElderHealthRecordModel.fromJson(e))
      .toList();
});

final elderAlertsProvider =
    FutureProvider.family<List<ElderAlertModel>, String>((ref, elderId) async {
  final data = await _client
      .from('elder_alerts')
      .select()
      .eq('elder_id', elderId)
      .order('alert_time', ascending: false);
  return (data as List).map((e) => ElderAlertModel.fromJson(e)).toList();
});

final elderSafetyInfoProvider =
    FutureProvider.family<ElderSafetyInfoModel?, String>((ref, elderId) async {
  final data = await _client
      .from('elder_safety_info')
      .select()
      .eq('elder_id', elderId)
      .maybeSingle();
  if (data == null) return null;
  return ElderSafetyInfoModel.fromJson(data);
});
