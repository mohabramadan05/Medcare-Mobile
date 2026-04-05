import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../providers/baby_provider.dart';

class BabyVaccinationsScreen extends ConsumerWidget {
  final String babyId;
  const BabyVaccinationsScreen({super.key, required this.babyId});

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return AppTheme.healthGreen;
      case 'missed':
        return AppTheme.error;
      default:
        return AppTheme.warning;
    }
  }

  Future<void> _addVaccination(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    final doseCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    DateTime? vaccineDate;
    DateTime? dueDate;
    String status = 'upcoming';

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
              const Text('Add Vaccination',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Vaccine Name *')),
              const SizedBox(height: 12),
              TextField(
                  controller: doseCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Dose (e.g. 1st)')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: status,
                decoration:
                    const InputDecoration(labelText: 'Status'),
                items: ['upcoming', 'completed', 'missed']
                    .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(s[0].toUpperCase() +
                            s.substring(1))))
                    .toList(),
                onChanged: (v) => setS(() => status = v!),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final d = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now()
                          .add(const Duration(days: 365)));
                  if (d != null) setS(() => vaccineDate = d);
                },
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(vaccineDate != null
                    ? 'Given: ${DateFormat('MMM dd, yyyy').format(vaccineDate!)}'
                    : 'Set Vaccine Date'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  final d = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now()
                          .add(const Duration(days: 365 * 5)));
                  if (d != null) setS(() => dueDate = d);
                },
                icon: const Icon(Icons.event, size: 16),
                label: Text(dueDate != null
                    ? 'Due: ${DateFormat('MMM dd, yyyy').format(dueDate!)}'
                    : 'Set Due Date'),
              ),
              const SizedBox(height: 12),
              TextField(
                  controller: notesCtrl,
                  maxLines: 2,
                  decoration:
                      const InputDecoration(labelText: 'Notes')),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.isEmpty) return;
                  try {
                    final userId = Supabase.instance.client.auth
                        .currentUser!.id;
                    await Supabase.instance.client
                        .from('baby_vaccinations')
                        .insert({
                      'baby_id': babyId,
                      'vaccine_name': nameCtrl.text.trim(),
                      if (doseCtrl.text.isNotEmpty)
                        'dose': doseCtrl.text.trim(),
                      'status': status,
                      if (vaccineDate != null)
                        'vaccine_date': DateFormat('yyyy-MM-dd')
                            .format(vaccineDate!),
                      if (dueDate != null)
                        'due_date': DateFormat('yyyy-MM-dd')
                            .format(dueDate!),
                      if (notesCtrl.text.isNotEmpty)
                        'notes': notesCtrl.text.trim(),
                      'created_by': userId,
                    });
                    ref.invalidate(
                        babyVaccinationsProvider(babyId));
                    if (context.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Vaccination added!'),
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
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vacsAsync = ref.watch(babyVaccinationsProvider(babyId));
    return Scaffold(
      appBar: AppBar(title: const Text('Vaccinations')),
      body: vacsAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => AppErrorWidget(
            message: e.toString(),
            onRetry: () =>
                ref.invalidate(babyVaccinationsProvider(babyId))),
        data: (vacs) {
          if (vacs.isEmpty) {
            return const EmptyStateWidget(
                icon: Icons.vaccines,
                title: 'No vaccinations recorded',
                subtitle:
                    'Track your baby\'s vaccination schedule');
          }
          final grouped = <String, List<dynamic>>{
            'upcoming':
                vacs.where((v) => v.status == 'upcoming').toList(),
            'completed':
                vacs.where((v) => v.status == 'completed').toList(),
            'missed':
                vacs.where((v) => v.status == 'missed').toList(),
          };
          return ListView(
            padding: const EdgeInsets.all(16),
            children: grouped.entries
                .where((e) => e.value.isNotEmpty)
                .expand((entry) => [
                      Padding(
                        padding: const EdgeInsets.only(
                            bottom: 8, top: 4),
                        child: Row(children: [
                          Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                  color:
                                      _statusColor(entry.key),
                                  shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Text(entry.key.toUpperCase(),
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      _statusColor(entry.key),
                                  letterSpacing: 1)),
                        ]),
                      ),
                      ...entry.value.map((v) => Container(
                            margin:
                                const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius:
                                  BorderRadius.circular(10),
                              border: Border.all(
                                  color: _statusColor(v.status)
                                      .withValues(alpha: 0.3)),
                            ),
                            child: Row(children: [
                              Icon(Icons.vaccines,
                                  color:
                                      _statusColor(v.status),
                                  size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(v.vaccineName,
                                        style: const TextStyle(
                                            fontWeight:
                                                FontWeight.w600,
                                            fontSize: 14)),
                                    if (v.dose != null)
                                      Text('Dose: ${v.dose}',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme
                                                  .textSecondary)),
                                    if (v.dueDate != null)
                                      Text(
                                          'Due: ${DateFormat('MMM dd, yyyy').format(v.dueDate!)}',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme
                                                  .textSecondary)),
                                  ],
                                ),
                              ),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3),
                                decoration: BoxDecoration(
                                  color:
                                      _statusColor(v.status)
                                          .withValues(alpha: 0.1),
                                  borderRadius:
                                      BorderRadius.circular(6),
                                ),
                                child: Text(
                                    v.status.toUpperCase(),
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight:
                                            FontWeight.bold,
                                        color: _statusColor(
                                            v.status))),
                              ),
                            ]),
                          )),
                    ])
                .toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addVaccination(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }
}
