import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../doctor/providers/doctor_provider.dart';
import '../providers/chat_provider.dart';

class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  Future<void> _startConversation(BuildContext context, WidgetRef ref,
      String doctorId, String doctorName) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final existing = await Supabase.instance.client
          .from('doctor_user_conversations')
          .select()
          .eq('doctor_id', doctorId)
          .eq('user_id', userId)
          .maybeSingle();

      String convId;
      if (existing != null) {
        convId = existing['id'] as String;
      } else {
        final created = await Supabase.instance.client
            .from('doctor_user_conversations')
            .insert({
              'doctor_id': doctorId,
              'user_id': userId,
              'last_message_at': DateTime.now().toIso8601String(),
            })
            .select()
            .single();
        convId = created['id'] as String;
      }
      ref.invalidate(conversationsProvider);
      if (context.mounted) {
        context.push(
            '/chat/$convId?doctorId=$doctorId&doctorName=${Uri.encodeComponent(doctorName)}');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'), backgroundColor: AppTheme.error));
      }
    }
  }

  void _showDoctorsList(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (ctx, scroll) => Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
              child: Row(children: [
                const Text('Find a Doctor',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx)),
              ]),
            ),
            Expanded(
              child: Consumer(builder: (ctx, ref, _) {
                final doctorsAsync = ref.watch(doctorsProvider);
                return doctorsAsync.when(
                  loading: () => const LoadingWidget(),
                  error: (e, _) => AppErrorWidget(message: e.toString()),
                  data: (doctors) => ListView.separated(
                    controller: scroll,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: doctors.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) {
                      final d = doctors[i];
                      final initial = d.fullName.trim().isNotEmpty
                          ? d.fullName.trim()[0].toUpperCase()
                          : 'D';
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: AppTheme.cardShadow,
                        ),
                        child: Row(children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor:
                                AppTheme.primary.withValues(alpha: 0.12),
                            child: Text(initial,
                                style: const TextStyle(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(d.fullName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14)),
                                if (d.doctorSpecialization != null)
                                  Text(d.doctorSpecialization!,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textSecondary)),
                              ],
                            ),
                          ),
                          FilledButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _startConversation(
                                  context, ref, d.id, d.fullName);
                            },
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Message',
                                style: TextStyle(fontSize: 13)),
                          ),
                        ]),
                      );
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final convsAsync = ref.watch(conversationsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: convsAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => AppErrorWidget(
            message: e.toString(),
            onRetry: () => ref.invalidate(conversationsProvider)),
        data: (convs) {
          if (convs.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'No conversations yet',
              subtitle: 'Start a conversation with a doctor',
              action: ElevatedButton.icon(
                onPressed: () => _showDoctorsList(context, ref),
                icon: const Icon(Icons.search_rounded, size: 18),
                label: const Text('Find a Doctor'),
                style:
                    ElevatedButton.styleFrom(minimumSize: const Size(200, 48)),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: convs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final c = convs[i];
              final initial = c.doctorName.trim().isNotEmpty
                  ? c.doctorName.trim()[0].toUpperCase()
                  : 'D';
              return GestureDetector(
                onTap: () => context.push(
                    '/chat/${c.id}?doctorId=${c.doctorId}&doctorName=${Uri.encodeComponent(c.doctorName)}'),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Row(children: [
                    // Avatar with initials
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                      child: Text(initial,
                          style: const TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 20)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.doctorName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: AppTheme.textPrimary)),
                          if (c.doctorSpecialization.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(c.doctorSpecialization,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary)),
                          ],
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (c.lastMessageAt != null)
                          Text(
                              timeago.format(c.lastMessageAt!,
                                  locale: 'en_short'),
                              style: const TextStyle(
                                  fontSize: 11, color: AppTheme.textLight)),
                        const SizedBox(height: 4),
                        const Icon(Icons.chevron_right_rounded,
                            color: AppTheme.textLight, size: 20),
                      ],
                    ),
                  ]),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showDoctorsList(context, ref),
        child: const Icon(Icons.edit_rounded),
      ),
    );
  }
}
