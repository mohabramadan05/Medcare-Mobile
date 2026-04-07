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

class ElderVitalsScreen extends ConsumerWidget {
  final String elderId;
  const ElderVitalsScreen({super.key, required this.elderId});

  Future<void> _addVitals(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final bpSysCtrl = TextEditingController();
    final bpDiaCtrl = TextEditingController();
    final hrCtrl = TextEditingController();
    final tempCtrl = TextEditingController();
    final sugarCtrl = TextEditingController();
    final o2Ctrl = TextEditingController();
    final weightCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

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
            Text(l.logVitals,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                  child: TextField(
                      controller: bpSysCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: l.bpSystolic))),
              const SizedBox(width: 12),
              Expanded(
                  child: TextField(
                      controller: bpDiaCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: l.bpDiastolic))),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: TextField(
                      controller: hrCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: l.heartRate))),
              const SizedBox(width: 12),
              Expanded(
                  child: TextField(
                      controller: tempCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(labelText: l.temperature))),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: TextField(
                      controller: sugarCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(labelText: l.bloodSugar))),
              const SizedBox(width: 12),
              Expanded(
                  child: TextField(
                      controller: o2Ctrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(labelText: l.o2Sat))),
            ]),
            const SizedBox(height: 12),
            TextField(
                controller: weightCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: l.weightKgLabel)),
            const SizedBox(height: 12),
            TextField(
                controller: notesCtrl,
                maxLines: 2,
                decoration: InputDecoration(labelText: l.notes)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                try {
                  final userId =
                      Supabase.instance.client.auth.currentUser!.id;
                  await Supabase.instance.client.from('elder_vitals').insert({
                    'elder_id': elderId,
                    'measured_at': DateTime.now().toIso8601String(),
                    if (bpSysCtrl.text.isNotEmpty)
                      'blood_pressure_systolic': int.tryParse(bpSysCtrl.text),
                    if (bpDiaCtrl.text.isNotEmpty)
                      'blood_pressure_diastolic': int.tryParse(bpDiaCtrl.text),
                    if (hrCtrl.text.isNotEmpty)
                      'heart_rate': int.tryParse(hrCtrl.text),
                    if (tempCtrl.text.isNotEmpty)
                      'temperature_c': double.tryParse(tempCtrl.text),
                    if (sugarCtrl.text.isNotEmpty)
                      'blood_sugar_mgdl': int.tryParse(sugarCtrl.text),
                    if (o2Ctrl.text.isNotEmpty)
                      'oxygen_saturation_percent': int.tryParse(o2Ctrl.text),
                    if (weightCtrl.text.isNotEmpty)
                      'weight_kg': double.tryParse(weightCtrl.text),
                    if (notesCtrl.text.isNotEmpty) 'notes': notesCtrl.text.trim(),
                    'created_by': userId,
                  });
                  ref.invalidate(elderVitalsProvider(elderId));
                  if (context.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(l.vitalsRecorded),
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
              child: Text(l.saveVitals),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final vitalsAsync = ref.watch(elderVitalsProvider(elderId));
    return Scaffold(
      appBar: AppBar(title: Text(l.vitals)),
      body: vitalsAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => AppErrorWidget(
            message: e.toString(),
            onRetry: () => ref.invalidate(elderVitalsProvider(elderId))),
        data: (vitals) {
          if (vitals.isEmpty) {
            return EmptyStateWidget(
                icon: Icons.monitor_heart,
                title: l.noVitals,
                subtitle: l.logFirstVitals);
          }
          final latest = vitals.first;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.latestReadings,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 4),
                Text(
                    '${l.measuredAt}${DateFormat('MMM dd, yyyy • hh:mm a').format(latest.measuredAt)}',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary)),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.4,
                  children: [
                    if (latest.bloodPressureSystolic != null)
                      _VitalCard(
                          icon: Icons.favorite,
                          label: l.bloodPressure,
                          value:
                              '${latest.bloodPressureSystolic}/${latest.bloodPressureDiastolic}',
                          unit: 'mmHg',
                          color: AppTheme.error),
                    if (latest.heartRate != null)
                      _VitalCard(
                          icon: Icons.monitor_heart,
                          label: l.heartRateLabel,
                          value: '${latest.heartRate}',
                          unit: 'bpm',
                          color: AppTheme.babyAccent),
                    if (latest.temperatureC != null)
                      _VitalCard(
                          icon: Icons.thermostat,
                          label: l.temperatureLabel,
                          value: '${latest.temperatureC}',
                          unit: '°C',
                          color: AppTheme.warning),
                    if (latest.oxygenSaturationPercent != null)
                      _VitalCard(
                          icon: Icons.air,
                          label: l.o2Saturation,
                          value: '${latest.oxygenSaturationPercent}',
                          unit: '%',
                          color: AppTheme.primary),
                    if (latest.bloodSugarMgdl != null)
                      _VitalCard(
                          icon: Icons.water_drop,
                          label: l.bloodSugarLabel,
                          value: '${latest.bloodSugarMgdl}',
                          unit: 'mg/dL',
                          color: AppTheme.elderAccent),
                    if (latest.weightKg != null)
                      _VitalCard(
                          icon: Icons.monitor_weight,
                          label: l.weightLabel,
                          value: '${latest.weightKg}',
                          unit: 'kg',
                          color: AppTheme.healthGreen),
                  ],
                ),
                if (vitals.length > 1) ...[
                  const SizedBox(height: 20),
                  Text(l.history,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary)),
                  const SizedBox(height: 12),
                  ...vitals.skip(1).map((v) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                DateFormat('MMM dd, yyyy • hh:mm a')
                                    .format(v.measuredAt),
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                if (v.bloodPressureSystolic != null)
                                  _MiniVital(
                                      label: 'BP',
                                      value:
                                          '${v.bloodPressureSystolic}/${v.bloodPressureDiastolic}',
                                      color: AppTheme.error),
                                if (v.heartRate != null)
                                  _MiniVital(
                                      label: 'HR',
                                      value: '${v.heartRate} bpm',
                                      color: AppTheme.babyAccent),
                                if (v.temperatureC != null)
                                  _MiniVital(
                                      label: 'Temp',
                                      value: '${v.temperatureC}°C',
                                      color: AppTheme.warning),
                                if (v.oxygenSaturationPercent != null)
                                  _MiniVital(
                                      label: 'O2',
                                      value: '${v.oxygenSaturationPercent}%',
                                      color: AppTheme.primary),
                              ],
                            ),
                          ],
                        ),
                      )),
                ],
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: () => _addVitals(context, ref),
          child: const Icon(Icons.add)),
    );
  }
}

class _VitalCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _VitalCard(
      {required this.icon,
      required this.label,
      required this.value,
      required this.unit,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color)),
          Text('$label ($unit)',
              style: const TextStyle(
                  fontSize: 10, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

class _MiniVital extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniVital(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6)),
      child: Text('$label: $value',
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}
