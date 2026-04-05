import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../chat/providers/chat_provider.dart';
import '../providers/doctor_provider.dart';

class DoctorsListScreen extends ConsumerWidget {
  const DoctorsListScreen({super.key});

  Future<void> _message(
      BuildContext context, WidgetRef ref, String doctorId, String doctorName) async {
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
        }).select().single();
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doctorsAsync = ref.watch(doctorsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Find a Doctor')),
      body: doctorsAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => AppErrorWidget(
            message: e.toString(),
            onRetry: () => ref.invalidate(doctorsProvider)),
        data: (doctors) {
          if (doctors.isEmpty) {
            return const EmptyStateWidget(
                icon: Icons.person_search,
                title: 'No doctors available',
                subtitle: 'Doctors will appear here once registered');
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: doctors.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final d = doctors[i];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                            color: AppTheme.primary
                                .withValues(alpha: 0.1),
                            shape: BoxShape.circle),
                        child: const Icon(Icons.person,
                            color: AppTheme.primary, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(d.fullName,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                            if (d.doctorSpecialization != null)
                              Text(d.doctorSpecialization!,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.primary,
                                      fontWeight:
                                          FontWeight.w500)),
                          ],
                        ),
                      ),
                      if (d.doctorRating != null)
                        Row(children: [
                          const Icon(Icons.star,
                              size: 16, color: AppTheme.warning),
                          const SizedBox(width: 3),
                          Text(d.doctorRating!.toStringAsFixed(1),
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                        ]),
                    ]),
                    if (d.doctorYearsExperience != null ||
                        d.doctorResponseRate != null) ...[
                      const SizedBox(height: 10),
                      Row(children: [
                        if (d.doctorYearsExperience != null) ...[
                          const Icon(Icons.work_outline,
                              size: 14,
                              color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                              '${d.doctorYearsExperience} yrs exp',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary)),
                          const SizedBox(width: 16),
                        ],
                        if (d.doctorResponseRate != null) ...[
                          const Icon(Icons.reply,
                              size: 14,
                              color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                              '${d.doctorResponseRate!.toStringAsFixed(0)}% response',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary)),
                        ],
                      ]),
                    ],
                    if (d.doctorBio != null &&
                        d.doctorBio!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(d.doctorBio!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary)),
                    ],
                    if (d.doctorTags != null &&
                        d.doctorTags!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: d.doctorTags!
                            .map((tag) => Container(
                                  padding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3),
                                  decoration: BoxDecoration(
                                      color: AppTheme.primary
                                          .withValues(alpha: 0.08),
                                      borderRadius:
                                          BorderRadius.circular(
                                              12)),
                                  child: Text(tag,
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.primary)),
                                ))
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _message(context, ref, d.id, d.fullName),
                        icon: const Icon(Icons.message_outlined,
                            size: 16),
                        label: const Text('Message'),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
