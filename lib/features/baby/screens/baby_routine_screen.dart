import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../providers/baby_provider.dart';

class BabyRoutineScreen extends ConsumerWidget {
  final String babyId;
  const BabyRoutineScreen({super.key, required this.babyId});

  IconData _icon(String type) {
    switch (type) {
      case 'feeding': return Icons.restaurant;
      case 'sleep': return Icons.bedtime;
      case 'diaper': return Icons.baby_changing_station;
      default: return Icons.more_horiz;
    }
  }

  Color _color(String type) {
    switch (type) {
      case 'feeding': return AppTheme.healthGreen;
      case 'sleep': return AppTheme.elderAccent;
      case 'diaper': return AppTheme.babyAccent;
      default: return AppTheme.textSecondary;
    }
  }

  String _activityLabel(String type, AppLocalizations l) {
    switch (type) {
      case 'feeding': return l.activityFeeding;
      case 'sleep': return l.activitySleep;
      case 'diaper': return l.activityDiaper;
      default: return l.activityOther;
    }
  }

  Future<DateTime?> _pickDateTime(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );
    if (date == null || !context.mounted) return null;
    final time = await showTimePicker(
        context: context, initialTime: TimeOfDay.now());
    if (time == null) return null;
    return DateTime(
        date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _addActivity(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    String activityType = 'feeding';
    DateTime activityTime = DateTime.now();
    final detailsCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.logActivity,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: activityType,
                decoration: InputDecoration(
                    labelText: l.activityType),
                items: [
                  DropdownMenuItem(
                      value: 'feeding', child: Text(l.activityFeeding)),
                  DropdownMenuItem(
                      value: 'sleep', child: Text(l.activitySleep)),
                  DropdownMenuItem(
                      value: 'diaper', child: Text(l.activityDiaper)),
                  DropdownMenuItem(
                      value: 'other', child: Text(l.activityOther)),
                ],
                onChanged: (v) =>
                    setS(() => activityType = v!),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final dt = await _pickDateTime(ctx);
                  if (dt != null) setS(() => activityTime = dt);
                },
                icon: const Icon(Icons.access_time, size: 16),
                label: Text(DateFormat('MMM dd, hh:mm a')
                    .format(activityTime)),
              ),
              const SizedBox(height: 12),
              TextField(
                  controller: detailsCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                      labelText: l.details)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  try {
                    final userId = Supabase
                        .instance.client.auth.currentUser!.id;
                    await Supabase.instance.client
                        .from('baby_routine')
                        .insert({
                      'baby_id': babyId,
                      'activity_time':
                          activityTime.toIso8601String(),
                      'activity_type': activityType,
                      if (detailsCtrl.text.isNotEmpty)
                        'details': detailsCtrl.text.trim(),
                      'created_by': userId,
                    });
                    ref.invalidate(babyRoutineProvider(babyId));
                    if (context.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(l.activityLogged),
                              backgroundColor:
                                  AppTheme.healthGreen));
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: AppTheme.error));
                    }
                  }
                },
                child: Text(l.logActivity),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final routineAsync = ref.watch(babyRoutineProvider(babyId));
    return Scaffold(
      appBar: AppBar(title: Text(l.dailyRoutine)),
      body: routineAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => AppErrorWidget(
            message: e.toString(),
            onRetry: () =>
                ref.invalidate(babyRoutineProvider(babyId))),
        data: (activities) {
          if (activities.isEmpty) {
            return EmptyStateWidget(
                icon: Icons.schedule,
                title: l.noActivities,
                subtitle: l.startLogging);
          }
          final grouped = <String, List<dynamic>>{};
          for (final a in activities) {
            final key = DateFormat('MMM dd, yyyy')
                .format(a.activityTime);
            grouped.putIfAbsent(key, () => []).add(a);
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: grouped.length,
            itemBuilder: (context, i) {
              final day = grouped.keys.elementAt(i);
              final dayActs = grouped[day]!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8),
                    child: Text(day,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textSecondary)),
                  ),
                  ...dayActs.map((a) => Container(
                        margin:
                            const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius:
                              BorderRadius.circular(10),
                          border:
                              Border.all(color: AppTheme.border),
                        ),
                        child: Row(children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _color(a.activityType)
                                  .withValues(alpha: 0.12),
                              borderRadius:
                                  BorderRadius.circular(10),
                            ),
                            child: Icon(_icon(a.activityType),
                                size: 20,
                                color: _color(a.activityType)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                    _activityLabel(
                                        a.activityType, l),
                                    style: const TextStyle(
                                        fontWeight:
                                            FontWeight.w600,
                                        fontSize: 14)),
                                if (a.details != null &&
                                    a.details!.isNotEmpty)
                                  Text(a.details!,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme
                                              .textSecondary)),
                              ],
                            ),
                          ),
                          Text(
                              DateFormat('hh:mm a')
                                  .format(a.activityTime),
                              style: const TextStyle(
                                  fontSize: 12,
                                  color:
                                      AppTheme.textSecondary)),
                        ]),
                      )),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addActivity(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }
}
