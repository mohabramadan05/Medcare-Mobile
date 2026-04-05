import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_model.dart';

SupabaseClient get _client => Supabase.instance.client;

final conversationsProvider =
    FutureProvider<List<ConversationModel>>((ref) async {
  final userId = _client.auth.currentUser?.id;
  if (userId == null) return [];

  final profile = await _client
      .from('profiles')
      .select('role')
      .eq('id', userId)
      .maybeSingle();
  final isDoctor = profile?['role'] == 'doctor';

  final List conversations = await _client
      .from('doctor_user_conversations')
      .select()
      .eq(isDoctor ? 'doctor_id' : 'user_id', userId)
      .order('last_message_at', ascending: false);

  if (conversations.isEmpty) return [];

  // Collect the IDs we need to look up
  final otherIds = conversations
      .map((c) => (isDoctor ? c['user_id'] : c['doctor_id']) as String)
      .toSet()
      .toList();

  final List profiles = await _client
      .from('profiles')
      .select('id, full_name, doctor_specialization')
      .inFilter('id', otherIds);

  final profileMap = {for (final p in profiles) p['id'] as String: p};

  return conversations.map((c) {
    final otherId =
        (isDoctor ? c['user_id'] : c['doctor_id']) as String? ?? '';
    final otherProfile = profileMap[otherId] ?? {};
    return ConversationModel.fromJson({
      ...c,
      if (isDoctor) 'user': otherProfile else 'doctor': otherProfile,
    });
  }).toList();
});

final messagesProvider = StreamProvider.family<List<MessageModel>, String>(
    (ref, conversationId) {
  return _client
      .from('doctor_user_messages')
      .stream(primaryKey: ['id'])
      .eq('conversation_id', conversationId)
      .order('created_at', ascending: true)
      .map((data) => data.map((e) => MessageModel.fromJson(e)).toList());
});
