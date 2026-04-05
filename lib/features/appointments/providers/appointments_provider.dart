import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/appointment_model.dart';

SupabaseClient get _client => Supabase.instance.client;
final appointmentsProvider =
    FutureProvider<List<AppointmentModel>>((ref) async {
  final userId = _client.auth.currentUser?.id;
  if (userId == null) return [];

  // ✅ Run in parallel (FIX for skipped frames)
  final results = await Future.wait([
    _client
        .from('user_babies')
        .select('baby_id')
        .eq('user_id', userId),
    _client
        .from('user_elders')
        .select('elder_id')
        .eq('user_id', userId),
  ]);

  final babiesRes = results[0] as List;
  final eldersRes = results[1] as List;

  final babyIds = babiesRes
      .map((e) => e['baby_id'])
      .where((id) => id != null)
      .toList();

  final elderIds = eldersRes
      .map((e) => e['elder_id'])
      .where((id) => id != null)
      .toList();

  // ✅ Always ensure at least one condition
  final filtersList = <String>[
    'created_by.eq.$userId',
  ];

  if (babyIds.isNotEmpty) {
    filtersList.add('baby_id.in.(${babyIds.join(',')})');
  }

  if (elderIds.isNotEmpty) {
    filtersList.add('elder_id.in.(${elderIds.join(',')})');
  }

  final filters = filtersList.join(',');

  // ✅ Main query
  final data = await _client
      .from('appointments')
      .select('''
        *,
        baby:babies ( name ),
        elder:elders ( full_name )
      ''')
      .or(filters)
      .order('appointment_at', ascending: true);

  return (data as List)
      .map((e) => AppointmentModel.fromJson(e))
      .toList();
});