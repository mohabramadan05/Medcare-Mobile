import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../providers/elder_provider.dart';

class ElderHealthRecordsScreen extends ConsumerWidget {
  final String elderId;
  const ElderHealthRecordsScreen({super.key, required this.elderId});

  Color _severityColor(String? s) {
    switch (s) {
      case 'severe': return AppTheme.error;
      case 'moderate': return AppTheme.warning;
      default: return AppTheme.healthGreen;
    }
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final nameCtrl = TextEditingController();
    final typeCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String severity = 'mild';
    String status = 'active';
    DateTime? recordDate;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.addHealthRecord,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                  controller: nameCtrl,
                  decoration:
                      InputDecoration(labelText: l.conditionName)),
              const SizedBox(height: 12),
              TextField(
                  controller: typeCtrl,
                  decoration: InputDecoration(
                      labelText: l.recordType)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: severity,
                decoration: InputDecoration(labelText: l.severity),
                items: [
                  DropdownMenuItem(value: 'mild', child: Text(l.severityMild)),
                  DropdownMenuItem(value: 'moderate', child: Text(l.severityModerate)),
                  DropdownMenuItem(value: 'severe', child: Text(l.severitySevere)),
                ],
                onChanged: (v) => setS(() => severity = v!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: status,
                decoration: InputDecoration(labelText: l.status),
                items: [
                  DropdownMenuItem(value: 'active', child: Text(l.statusActive)),
                  DropdownMenuItem(value: 'resolved', child: Text(l.statusResolved)),
                  DropdownMenuItem(value: 'monitoring', child: Text(l.statusMonitoring)),
                ],
                onChanged: (v) => setS(() => status = v!),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final d = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1950),
                      lastDate: DateTime.now());
                  if (d != null) setS(() => recordDate = d);
                },
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(recordDate != null
                    ? DateFormat('MMM dd, yyyy').format(recordDate!)
                    : l.setDateBtn),
              ),
              const SizedBox(height: 12),
              TextField(
                  controller: notesCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(labelText: l.notes)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.isEmpty) return;
                  try {
                    final userId =
                        Supabase.instance.client.auth.currentUser!.id;
                    await Supabase.instance.client
                        .from('elder_health_records')
                        .insert({
                      'elder_id': elderId,
                      'name': nameCtrl.text.trim(),
                      if (typeCtrl.text.isNotEmpty)
                        'record_type': typeCtrl.text.trim(),
                      'severity': severity,
                      'status': status,
                      if (recordDate != null)
                        'record_date':
                            DateFormat('yyyy-MM-dd').format(recordDate!),
                      if (notesCtrl.text.isNotEmpty)
                        'notes': notesCtrl.text.trim(),
                      'created_by': userId,
                    });
                    ref.invalidate(elderHealthRecordsProvider(elderId));
                    if (context.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(l.recordAddedSuccess),
                              backgroundColor: AppTheme.healthGreen));
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: AppTheme.error));
                    }
                  }
                },
                child: Text(l.save),
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
    final recordsAsync = ref.watch(elderHealthRecordsProvider(elderId));
    return Scaffold(
      appBar: AppBar(title: Text(l.healthRecords)),
      body: recordsAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => AppErrorWidget(
            message: e.toString(),
            onRetry: () =>
                ref.invalidate(elderHealthRecordsProvider(elderId))),
        data: (records) {
          if (records.isEmpty) {
            return EmptyStateWidget(
                icon: Icons.folder_special,
                title: l.noHealthRecords,
                subtitle: l.addHealthConditions);
          }
          final grouped = <String, List<dynamic>>{};
          for (final r in records) {
            final key = r.recordType ?? l.general;
            grouped.putIfAbsent(key, () => []).add(r);
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: grouped.entries
                .expand((entry) => [
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 8),
                        child: Text(entry.key,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textSecondary,
                                letterSpacing: 0.5)),
                      ),
                      ...entry.value.map((r) => Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: _severityColor(r.severity)
                                      .withValues(alpha: 0.3)),
                            ),
                            child: Row(children: [
                              Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                      color: _severityColor(r.severity),
                                      shape: BoxShape.circle)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(r.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14)),
                                    if (r.recordDate != null)
                                      Text(
                                          DateFormat('MMM dd, yyyy')
                                              .format(r.recordDate!),
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textSecondary)),
                                    if (r.notes != null &&
                                        r.notes!.isNotEmpty)
                                      Text(r.notes!,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textSecondary)),
                                  ],
                                ),
                              ),
                              if (r.severity != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                      color: _severityColor(r.severity)
                                          .withValues(alpha: 0.1),
                                      borderRadius:
                                          BorderRadius.circular(6)),
                                  child: Text(r.severity!.toUpperCase(),
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              _severityColor(r.severity))),
                                ),
                            ]),
                          )),
                    ])
                .toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: () => _add(context, ref),
          child: const Icon(Icons.add)),
    );
  }
}
