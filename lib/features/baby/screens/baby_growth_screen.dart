import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../providers/baby_provider.dart';

class BabyGrowthScreen extends ConsumerWidget {
  final String babyId;
  const BabyGrowthScreen({super.key, required this.babyId});

  Future<void> _addRecord(BuildContext context, WidgetRef ref) async {
    final weightCtrl = TextEditingController();
    final lengthCtrl = TextEditingController();
    DateTime? selectedDate;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Add Growth Record',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  final d = await showDatePicker(
                    context: ctx,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (d != null) setS(() => selectedDate = d);
                },
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(selectedDate != null
                    ? DateFormat('MMM dd, yyyy').format(selectedDate!)
                    : 'Select Date *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: weightCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                    labelText: 'Weight (kg)',
                    prefixIcon: Icon(Icons.monitor_weight_outlined)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: lengthCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                    labelText: 'Length (cm)',
                    prefixIcon: Icon(Icons.straighten)),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (selectedDate == null) return;
                  try {
                    final userId =
                        Supabase.instance.client.auth.currentUser!.id;
                    await Supabase.instance.client.from('baby_growth').insert({
                      'baby_id': babyId,
                      'record_date':
                          DateFormat('yyyy-MM-dd').format(selectedDate!),
                      if (weightCtrl.text.isNotEmpty)
                        'weight_kg': double.tryParse(weightCtrl.text),
                      if (lengthCtrl.text.isNotEmpty)
                        'length_cm': double.tryParse(lengthCtrl.text),
                      'created_by': userId,
                    });
                    ref.invalidate(babyGrowthProvider(babyId));
                    if (context.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Record added!'),
                            backgroundColor: AppTheme.healthGreen),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: AppTheme.error));
                    }
                  }
                },
                child: const Text('Save Record'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final growthAsync = ref.watch(babyGrowthProvider(babyId));
    return Scaffold(
      appBar: AppBar(title: const Text('Growth Chart')),
      body: growthAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => AppErrorWidget(
            message: e.toString(),
            onRetry: () => ref.invalidate(babyGrowthProvider(babyId))),
        data: (records) {
          if (records.isEmpty) {
            return const EmptyStateWidget(
                icon: Icons.show_chart,
                title: 'No growth records',
                subtitle: 'Add the first growth measurement');
          }
          final weightSpots = records
              .asMap()
              .entries
              .where((e) => e.value.weightKg != null)
              .map((e) => FlSpot(e.key.toDouble(), e.value.weightKg!))
              .toList();
          final lengthSpots = records
              .asMap()
              .entries
              .where((e) => e.value.lengthCm != null)
              .map((e) => FlSpot(e.key.toDouble(), e.value.lengthCm!))
              .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 260,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: LineChart(LineChartData(
                    gridData: FlGridData(
                      show: true,
                      getDrawingHorizontalLine: (_) =>
                          const FlLine(color: AppTheme.border, strokeWidth: 1),
                      getDrawingVerticalLine: (_) =>
                          const FlLine(color: AppTheme.border, strokeWidth: 1),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 36,
                          getTitlesWidget: (v, _) => Text('${v.toInt()}',
                              style: const TextStyle(
                                  fontSize: 10, color: AppTheme.textSecondary)),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (v, _) {
                            final idx = v.toInt();
                            if (idx < 0 || idx >= records.length) {
                              return const Text('');
                            }
                            return Text(
                              DateFormat('MM/dd')
                                  .format(records[idx].recordDate),
                              style: const TextStyle(
                                  fontSize: 9, color: AppTheme.textSecondary),
                            );
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      if (weightSpots.isNotEmpty)
                        LineChartBarData(
                          spots: weightSpots,
                          isCurved: true,
                          color: AppTheme.healthGreen,
                          barWidth: 2.5,
                          dotData: const FlDotData(show: true),
                        ),
                      if (lengthSpots.isNotEmpty)
                        LineChartBarData(
                          spots: lengthSpots,
                          isCurved: true,
                          color: AppTheme.primary,
                          barWidth: 2.5,
                          dotData: const FlDotData(show: true),
                        ),
                    ],
                  )),
                ),
                const SizedBox(height: 12),
                const Row(children: [
                  _Legend(color: AppTheme.healthGreen, label: 'Weight (kg)'),
                  SizedBox(width: 16),
                  _Legend(color: AppTheme.primary, label: 'Length (cm)'),
                ]),
                const SizedBox(height: 20),
                const Text('Records',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 12),
                ...records.reversed.map((r) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Row(children: [
                        const Icon(Icons.calendar_today,
                            size: 16, color: AppTheme.textSecondary),
                        const SizedBox(width: 10),
                        Text(DateFormat('MMM dd, yyyy').format(r.recordDate),
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        const Spacer(),
                        if (r.weightKg != null)
                          _Badge(
                              label: '${r.weightKg} kg',
                              color: AppTheme.healthGreen),
                        if (r.lengthCm != null) ...[
                          const SizedBox(width: 8),
                          _Badge(
                              label: '${r.lengthCm} cm',
                              color: AppTheme.primary),
                        ],
                      ]),
                    )),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addRecord(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
          width: 16,
          height: 4,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 6),
      Text(label,
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
    ]);
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    );
  }
}
