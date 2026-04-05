import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/baby_model.dart';

SupabaseClient get _client => Supabase.instance.client;

final userBabiesProvider = FutureProvider<List<BabyModel>>((ref) async {
  final userId = _client.auth.currentUser?.id;
  if (userId == null) return [];

  // Babies linked via junction table
  final linked = await _client
      .from('user_babies')
      .select('baby_id, babies(*)')
      .eq('user_id', userId);
  final linkedBabies = (linked as List)
      .map((e) => BabyModel.fromJson(e['babies'] as Map<String, dynamic>))
      .toList();

  // Babies directly created by the user
  final created = await _client
      .from('babies')
      .select()
      .eq('created_by', userId);
  final createdBabies = (created as List)
      .map((e) => BabyModel.fromJson(e as Map<String, dynamic>))
      .toList();

  // Merge and deduplicate by id
  final seen = <String>{};
  final all = <BabyModel>[];
  for (final b in [...linkedBabies, ...createdBabies]) {
    if (seen.add(b.id)) all.add(b);
  }
  return all;
});

final babyDetailProvider =
    FutureProvider.family<BabyModel?, String>((ref, id) async {
  final data =
      await _client.from('babies').select().eq('id', id).maybeSingle();
  if (data == null) return null;
  return BabyModel.fromJson(data);
});

final babyGrowthProvider =
    FutureProvider.family<List<BabyGrowthModel>, String>((ref, babyId) async {
  final data = await _client
      .from('baby_growth')
      .select()
      .eq('baby_id', babyId)
      .order('record_date', ascending: true);
  return (data as List).map((e) => BabyGrowthModel.fromJson(e)).toList();
});

final babyVaccinationsProvider =
    FutureProvider.family<List<BabyVaccinationModel>, String>(
        (ref, babyId) async {
  final data = await _client
      .from('baby_vaccinations')
      .select()
      .eq('baby_id', babyId)
      .order('due_date', ascending: true);
  return (data as List)
      .map((e) => BabyVaccinationModel.fromJson(e))
      .toList();
});

final babyMedicinesProvider =
    FutureProvider.family<List<BabyMedicineModel>, String>((ref, babyId) async {
  final data =
      await _client.from('baby_medicines').select().eq('baby_id', babyId);
  return (data as List).map((e) => BabyMedicineModel.fromJson(e)).toList();
});

final babyRoutineProvider =
    FutureProvider.family<List<BabyRoutineModel>, String>((ref, babyId) async {
  final data = await _client
      .from('baby_routine')
      .select()
      .eq('baby_id', babyId)
      .order('activity_time', ascending: false);
  return (data as List).map((e) => BabyRoutineModel.fromJson(e)).toList();
});

final babyAlertsProvider =
    FutureProvider.family<List<BabyAlertModel>, String>((ref, babyId) async {
  final data = await _client
      .from('baby_alerts')
      .select()
      .eq('baby_id', babyId)
      .order('alert_time', ascending: false);
  return (data as List).map((e) => BabyAlertModel.fromJson(e)).toList();
});
