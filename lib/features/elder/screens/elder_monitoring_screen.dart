import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../models/elder_model.dart';

// ── Real-time providers ──────────────────────────────────────────────────────

final _elderVitalsStreamProvider =
    StreamProvider.family<List<ElderVitalsModel>, String>((ref, elderId) {
  return Supabase.instance.client
      .from('elder_vitals')
      .stream(primaryKey: ['id'])
      .eq('elder_id', elderId)
      .order('measured_at', ascending: false)
      .limit(24)
      .map((data) => data.map((e) => ElderVitalsModel.fromJson(e)).toList());
});

final _elderAlertsStreamProvider =
    StreamProvider.family<List<ElderAlertModel>, String>((ref, elderId) {
  return Supabase.instance.client
      .from('elder_alerts')
      .stream(primaryKey: ['id'])
      .eq('elder_id', elderId)
      .order('alert_time', ascending: false)
      .limit(10)
      .map((data) => data.map((e) => ElderAlertModel.fromJson(e)).toList());
});

// ── Screen ───────────────────────────────────────────────────────────────────

class ElderMonitoringScreen extends ConsumerStatefulWidget {
  final String elderId;
  final String elderName;
  final String patientCode;

  const ElderMonitoringScreen({
    super.key,
    required this.elderId,
    required this.elderName,
    required this.patientCode,
  });

  @override
  ConsumerState<ElderMonitoringScreen> createState() =>
      _ElderMonitoringScreenState();
}

class _ElderMonitoringScreenState
    extends ConsumerState<ElderMonitoringScreen> {
  bool _show24h = true;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final vitalsAsync =
        ref.watch(_elderVitalsStreamProvider(widget.elderId));
    final alertsAsync =
        ref.watch(_elderAlertsStreamProvider(widget.elderId));

    final vitals =
        vitalsAsync.whenOrNull(data: (d) => d) ?? <ElderVitalsModel>[];
    final alerts =
        alertsAsync.whenOrNull(data: (d) => d) ?? <ElderAlertModel>[];
    final latest = vitals.isNotEmpty ? vitals.first : null;
    final isLoading = vitalsAsync.isLoading && alertsAsync.isLoading;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.monitoring,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(widget.patientCode,
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.textSecondary)),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.healthGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                    color: AppTheme.healthGreen, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Text(l.live,
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.healthGreen,
                      fontWeight: FontWeight.w600)),
            ]),
          ),
        ],
      ),
      body: isLoading
          ? const LoadingWidget()
          : RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(
                    _elderVitalsStreamProvider(widget.elderId));
                ref.invalidate(
                    _elderAlertsStreamProvider(widget.elderId));
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Live Feed ─────────────────────────────────
                  _SectionCard(
                    header: _SectionHeader(
                      title: l.liveFeed,
                      icon: Icons.videocam_rounded,
                      color: AppTheme.elderAccent,
                      trailing: _LiveBadge(),
                    ),
                    child: Column(children: [
                      Container(
                        height: 160,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3730A3), AppTheme.elderAccent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.person,
                                  color: Colors.white.withValues(alpha: 0.7),
                                  size: 40),
                              const SizedBox(height: 8),
                              Text(l.elderCameraFeed,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15)),
                              const SizedBox(height: 4),
                              Text(l.livingRoom,
                                  style: TextStyle(
                                      color: Colors.white
                                          .withValues(alpha: 0.7),
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.fullscreen, size: 16),
                          label: Text(l.fullScreen),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.elderAccent,
                            side: BorderSide(
                                color: AppTheme.elderAccent
                                    .withValues(alpha: 0.4)),
                          ),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 14),

                  // ── Safety Alerts ─────────────────────────────
                  _SectionCard(
                    header: _SectionHeader(
                      title: l.safetyAlerts,
                      icon: Icons.notifications_active_rounded,
                      color: alerts.isEmpty
                          ? AppTheme.healthGreen
                          : AppTheme.warning,
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (alerts.isEmpty
                                  ? AppTheme.healthGreen
                                  : AppTheme.warning)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: alerts.isEmpty
                                  ? AppTheme.healthGreen
                                  : AppTheme.warning,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            alerts.isEmpty ? l.allClear : '${alerts.length}',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: alerts.isEmpty
                                    ? AppTheme.healthGreen
                                    : AppTheme.warning),
                          ),
                        ]),
                      ),
                    ),
                    child: alerts.isEmpty
                        ? _EmptySection(
                            icon: Icons.check_circle_outline,
                            text: l.noAlertsDetected,
                            color: AppTheme.healthGreen)
                        : Column(
                            children: alerts
                                .take(5)
                                .map((a) => _AlertTile(
                                    label: a.detectedObject ??
                                        l.activityDetected,
                                    time: a.alertTime))
                                .toList(),
                          ),
                  ),
                  const SizedBox(height: 14),

                  // ── Daily Vitals ──────────────────────────────
                  _SectionCard(
                    header: _SectionHeader(
                      title: l.dailyVitals,
                      icon: Icons.favorite_rounded,
                      color: AppTheme.error,
                    ),
                    child: latest == null
                        ? _EmptySection(
                            icon: Icons.monitor_heart_outlined,
                            text: l.noVitals,
                            color: AppTheme.textSecondary)
                        : Row(children: [
                            Expanded(
                              child: _VitalMini(
                                icon: Icons.favorite,
                                label: l.hrReading,
                                value: latest.heartRate != null
                                    ? '${latest.heartRate}'
                                    : '--',
                                unit: 'BPM',
                                color: AppTheme.error,
                                status: _hrStatus(latest.heartRate),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _VitalMini(
                                icon: Icons.air,
                                label: l.spO2,
                                value: latest.oxygenSaturationPercent != null
                                    ? '${latest.oxygenSaturationPercent!.toStringAsFixed(0)}%'
                                    : '--',
                                unit: '%',
                                color: AppTheme.primary,
                                status: _o2Status(
                                    latest.oxygenSaturationPercent),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _VitalMini(
                                icon: Icons.thermostat,
                                label: l.temperatureLabel,
                                value: latest.temperatureC != null
                                    ? '${latest.temperatureC!.toStringAsFixed(1)} °C'
                                    : '--',
                                unit: '°C',
                                color: AppTheme.warning,
                                status: _tempStatus(latest.temperatureC),
                              ),
                            ),
                          ]),
                  ),
                  const SizedBox(height: 14),

                  // ── Heart Rate Chart ──────────────────────────
                  _SectionCard(
                    header: _SectionHeader(
                      title: l.heartRateTracking,
                      icon: Icons.show_chart_rounded,
                      color: AppTheme.elderAccent,
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        _ToggleBtn(
                            label: l.h24,
                            selected: _show24h,
                            onTap: () => setState(() => _show24h = true)),
                        const SizedBox(width: 6),
                        _ToggleBtn(
                            label: l.week,
                            selected: !_show24h,
                            onTap: () => setState(() => _show24h = false)),
                      ]),
                    ),
                    child: vitals.isEmpty
                        ? _EmptySection(
                            icon: Icons.show_chart,
                            text: l.noVitalsForChart,
                            color: AppTheme.textSecondary)
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${widget.elderName}'s ${l.hrReading} - ${_show24h ? l.h24 : l.week}",
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 180,
                                child: _HrChart(
                                    vitals: vitals, show24h: _show24h),
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  '${l.liveTrendFor} ${widget.patientCode}',
                                  style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.elderAccent
                                          .withValues(alpha: 0.7),
                                      letterSpacing: 1),
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Legend
                              Wrap(
                                spacing: 10,
                                runSpacing: 6,
                                children: [
                                  _LegendItem(
                                      color: AppTheme.healthGreen,
                                      label: l.restingRange),
                                  _LegendItem(
                                      color: AppTheme.warning,
                                      label: l.normalRange),
                                  _LegendItem(
                                      color: const Color(0xFFFF7043),
                                      label: l.elevatedRange),
                                  _LegendItem(
                                      color: AppTheme.error,
                                      label: l.highRange),
                                  _LegendItem(
                                      color: const Color(0xFF4A0000),
                                      label: l.peakRange),
                                ],
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  String _hrStatus(int? hr) {
    if (hr == null) return '';
    if (hr <= 70) return 'Resting';
    if (hr <= 100) return 'Normal';
    if (hr <= 130) return 'Elevated';
    if (hr <= 160) return 'High';
    return 'Peak';
  }

  String _o2Status(double? o2) {
    if (o2 == null) return '';
    if (o2 >= 95) return 'Good';
    if (o2 >= 90) return 'Low';
    return 'Critical';
  }

  String _tempStatus(double? temp) {
    if (temp == null) return '';
    if (temp < 36.1) return 'Low';
    if (temp <= 37.2) return 'Normal';
    if (temp <= 38.0) return 'Elevated';
    return 'High';
  }
}

// ── Chart ────────────────────────────────────────────────────────────────────

class _HrChart extends StatelessWidget {
  final List<ElderVitalsModel> vitals;
  final bool show24h;

  const _HrChart({required this.vitals, required this.show24h});

  Color _hrColor(double hr) {
    if (hr <= 70) return AppTheme.healthGreen;
    if (hr <= 100) return AppTheme.warning;
    if (hr <= 130) return const Color(0xFFFF7043);
    if (hr <= 160) return AppTheme.error;
    return const Color(0xFF4A0000);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final filtered = vitals
        .where((v) => v.heartRate != null)
        .toList()
        .reversed
        .toList();

    if (filtered.isEmpty) {
      return Center(
          child: Text(l.noHeartRateData,
              style: const TextStyle(color: AppTheme.textSecondary)));
    }

    final spots = filtered.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.heartRate!.toDouble());
    }).toList();

    final minY = (spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) - 10)
        .clamp(0, 300)
        .toDouble();
    final maxY = (spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 10)
        .clamp(0, 300)
        .toDouble();

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: AppTheme.border,
            strokeWidth: 0.8,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (v, _) => Text('${v.toInt()}',
                  style: const TextStyle(
                      fontSize: 9, color: AppTheme.textSecondary)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: (spots.length / 4).ceilToDouble(),
              getTitlesWidget: (v, _) {
                final idx = v.toInt();
                if (idx < 0 || idx >= filtered.length) {
                  return const SizedBox.shrink();
                }
                final t = filtered[idx].measuredAt;
                return Text(
                    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                        fontSize: 9, color: AppTheme.textSecondary));
              },
            ),
          ),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppTheme.elderAccent,
            barWidth: 2,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                radius: 3,
                color: _hrColor(spot.y),
                strokeWidth: 1,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppTheme.elderAccent.withValues(alpha: 0.2),
                  AppTheme.elderAccent.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final Widget header;
  final Widget child;

  const _SectionCard({required this.header, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: header,
        ),
        const SizedBox(height: 2),
        Container(height: 1, color: AppTheme.border),
        Padding(padding: const EdgeInsets.all(14), child: child),
      ]),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Widget? trailing;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.color,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(width: 7),
      Text(title,
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color)),
      const Spacer(),
      if (trailing != null) trailing!,
    ]);
  }
}

class _LiveBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(
            color: AppTheme.healthGreen, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Text(l.live,
          style: const TextStyle(
              fontSize: 11,
              color: AppTheme.healthGreen,
              fontWeight: FontWeight.w600)),
    ]);
  }
}

class _AlertTile extends StatelessWidget {
  final String label;
  final DateTime time;

  const _AlertTile({required this.label, required this.time});

  IconData _icon(String label) {
    final l = label.toLowerCase();
    if (l.contains('medic')) return Icons.medication;
    if (l.contains('rest') || l.contains('sleep')) return Icons.bedtime;
    return Icons.directions_walk;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppTheme.elderAccent.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(_icon(label),
              size: 16, color: AppTheme.elderAccent),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary)),
              Text(timeago.format(time),
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textSecondary)),
            ],
          ),
        ),
      ]),
    );
  }
}

class _VitalMini extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;
  final String status;

  const _VitalMini({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.status,
  });

  Color _statusColor(String s) {
    switch (s) {
      case 'Normal':
      case 'Good':
      case 'Resting':
        return AppTheme.healthGreen;
      case 'Elevated':
      case 'Low':
        return AppTheme.warning;
      default:
        return AppTheme.error;
    }
  }

  String _localizeStatus(String s, AppLocalizations l) {
    switch (s) {
      case 'Resting': return l.resting;
      case 'Normal': return l.normal;
      case 'Elevated': return l.elevated;
      case 'High': return l.high;
      case 'Peak': return l.peak;
      case 'Good': return l.good;
      case 'Low': return l.low;
      case 'Critical': return l.critical;
      default: return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final localizedStatus = status.isNotEmpty ? _localizeStatus(status, l) : '';
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: color),
              textAlign: TextAlign.center),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 9, color: AppTheme.textSecondary),
              textAlign: TextAlign.center),
          if (localizedStatus.isNotEmpty) ...[
            const SizedBox(height: 5),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _statusColor(status).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(localizedStatus,
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: _statusColor(status))),
            ),
          ],
        ],
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleBtn(
      {required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.elderAccent
              : AppTheme.elderAccent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color:
                    selected ? Colors.white : AppTheme.elderAccent)),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label,
          style:
              const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
    ]);
  }
}

class _EmptySection extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _EmptySection(
      {required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: color.withValues(alpha: 0.5), size: 18),
        const SizedBox(width: 8),
        Text(text,
            style: TextStyle(
                fontSize: 12,
                color: color.withValues(alpha: 0.7))),
      ]),
    );
  }
}
