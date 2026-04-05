import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/models/profile_model.dart';

SupabaseClient get _client => Supabase.instance.client;

final doctorsProvider = FutureProvider<List<ProfileModel>>((ref) async {
  final data = await _client
      .from('profiles')
      .select()
      .eq('role', 'doctor')
      .order('full_name', ascending: true);
  return (data as List).map((e) => ProfileModel.fromJson(e)).toList();
});
