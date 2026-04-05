import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../providers/elder_provider.dart';

class ElderMedicationsScreen extends ConsumerWidget {
  final String elderId;
  const ElderMedicationsScreen({super.key, required this.elderId});

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    final dosageCtrl = TextEditingController();
    final freqCtrl = TextEditingController();
    final timeCtrl = TextEditingController();
    final durationCtrl = TextEditingController();
    final instrCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Add Medication',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
                controller: nameCtrl,
                decoration:
                    const InputDecoration(labelText: 'Medicine Name *')),
            const SizedBox(height: 12),
            TextField(
                controller: dosageCtrl,
                decoration: const InputDecoration(labelText: 'Dosage')),
            const SizedBox(height: 12),
            TextField(
                controller: freqCtrl,
                decoration:
                    const InputDecoration(labelText: 'Frequency')),
            const SizedBox(height: 12),
            TextField(
                controller: timeCtrl,
                decoration:
                    const InputDecoration(labelText: 'Time of Day')),
            const SizedBox(height: 12),
            TextField(
                controller: durationCtrl,
                decoration:
                    const InputDecoration(labelText: 'Duration')),
            const SizedBox(height: 12),
            TextField(
                controller: instrCtrl,
                maxLines: 2,
                decoration:
                    const InputDecoration(labelText: 'Instructions')),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty) return;
                try {
                  final userId =
                      Supabase.instance.client.auth.currentUser!.id;
                  await Supabase.instance.client
                      .from('elder_medications')
                      .insert({
                    'elder_id': elderId,
                    'medicine_name': nameCtrl.text.trim(),
                    if (dosageCtrl.text.isNotEmpty)
                      'dosage': dosageCtrl.text.trim(),
                    if (freqCtrl.text.isNotEmpty)
                      'frequency': freqCtrl.text.trim(),
                    if (timeCtrl.text.isNotEmpty)
                      'time_of_day': timeCtrl.text.trim(),
                    if (durationCtrl.text.isNotEmpty)
                      'duration': durationCtrl.text.trim(),
                    if (instrCtrl.text.isNotEmpty)
                      'instructions': instrCtrl.text.trim(),
                    'created_by': userId,
                  });
                  ref.invalidate(elderMedicationsProvider(elderId));
                  if (context.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Medication added!'),
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
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medsAsync = ref.watch(elderMedicationsProvider(elderId));
    return Scaffold(
      appBar: AppBar(title: const Text('Medications')),
      body: medsAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => AppErrorWidget(
            message: e.toString(),
            onRetry: () =>
                ref.invalidate(elderMedicationsProvider(elderId))),
        data: (meds) {
          if (meds.isEmpty) {
            return const EmptyStateWidget(
                icon: Icons.medication,
                title: 'No medications',
                subtitle: 'Add medications for this elder');
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: meds.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final m = meds[i];
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                        color:
                            AppTheme.warning.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.medication,
                        color: AppTheme.warning, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.medicineName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14)),
                        if (m.dosage != null)
                          Text(m.dosage!,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary)),
                        if (m.frequency != null)
                          Text(m.frequency!,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                  if (m.timeOfDay != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color:
                              AppTheme.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6)),
                      child: Text(m.timeOfDay!,
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.warning,
                              fontWeight: FontWeight.w600)),
                    ),
                ]),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: () => _add(context, ref),
          child: const Icon(Icons.add)),
    );
  }
}
