import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../baby/models/baby_model.dart';
import '../../baby/services/baby_monitoring_service.dart';
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

// Room sensor readings shared via the `baby_sensor_readings` table, keyed by
// patient code. Their `alert_text` feeds the Safety Alerts list alongside
// `elder_alerts`. Polls once a minute.
final _sensorReadingsStreamProvider =
    StreamProvider.family<List<BabySensorReading>, String>((ref, patientCode) {
  return BabyMonitoringService.recentSensorReadingsStream(patientCode);
});

// Latest wearable-band reading from the `band_readings` table, keyed by patient
// code. Drives the heart rate & SpO2 in the Daily Vitals card. Polls once a
// minute.
final _bandReadingStreamProvider =
    StreamProvider.family<BandReading?, String>((ref, patientCode) {
  return BabyMonitoringService.bandReadingStream(patientCode);
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

    // Heart rate & SpO2 in the Daily Vitals card come from the wearable band
    // (`band_readings`), keyed by patient code.
    final band = ref
        .watch(_bandReadingStreamProvider(widget.patientCode))
        .whenOrNull(data: (b) => b);

    // Safety alerts combine the dedicated `elder_alerts` rows with the
    // `alert_text` of the shared room sensor readings (`baby_sensor_readings`,
    // keyed by patient code), sorted newest first and capped at the last 5.
    final sensorReadings =
        ref.watch(_sensorReadingsStreamProvider(widget.patientCode)).whenOrNull(
                  data: (d) => d,
                ) ??
            const <BabySensorReading>[];
    // Newest sensor reading drives the Room Environment card (temp & humidity).
    final latestSensor = sensorReadings.isNotEmpty ? sensorReadings.first : null;
    final safetyAlerts = <_SafetyAlert>[
      for (final a in alerts)
        _SafetyAlert(label: a.detectedObject ?? l.activityDetected, time: a.alertTime),
      for (final s in sensorReadings)
        if (s.alertText != null && s.alertText!.trim().isNotEmpty)
          _SafetyAlert(label: s.alertText!.trim(), time: s.measuredAt),
    ]..sort((a, b) {
        final at = a.time, bt = b.time;
        if (at == null && bt == null) return 0;
        if (at == null) return 1;
        if (bt == null) return -1;
        return bt.compareTo(at); // newest first
      });
    final recentAlerts = safetyAlerts.take(5).toList();

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
                ref.invalidate(
                    _sensorReadingsStreamProvider(widget.patientCode));
                ref.invalidate(
                    _bandReadingStreamProvider(widget.patientCode));
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
                      color: recentAlerts.isEmpty
                          ? AppTheme.healthGreen
                          : AppTheme.warning,
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (recentAlerts.isEmpty
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
                              color: recentAlerts.isEmpty
                                  ? AppTheme.healthGreen
                                  : AppTheme.warning,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            recentAlerts.isEmpty
                                ? l.allClear
                                : '${recentAlerts.length}',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: recentAlerts.isEmpty
                                    ? AppTheme.healthGreen
                                    : AppTheme.warning),
                          ),
                        ]),
                      ),
                    ),
                    child: recentAlerts.isEmpty
                        ? _EmptySection(
                            icon: Icons.check_circle_outline,
                            text: l.noAlertsDetected,
                            color: AppTheme.healthGreen)
                        : Column(
                            children: recentAlerts
                                .map((a) => _AlertTile(
                                    label: a.label, time: a.time))
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
                    child: (latest == null && band == null)
                        ? _EmptySection(
                            icon: Icons.monitor_heart_outlined,
                            text: l.noVitals,
                            color: AppTheme.textSecondary)
                        : Row(children: [
                            Expanded(
                              child: _VitalMini(
                                icon: Icons.favorite,
                                label: l.hrReading,
                                value: band?.heartRate != null
                                    ? '${band!.heartRate}'
                                    : '--',
                                unit: 'BPM',
                                color: AppTheme.error,
                                status: _hrStatus(band?.heartRate),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _VitalMini(
                                icon: Icons.air,
                                label: l.spO2,
                                value: band?.spo2 != null
                                    ? '${band!.spo2}%'
                                    : '--',
                                unit: '%',
                                color: AppTheme.primary,
                                status: _o2Status(band?.spo2?.toDouble()),
                              ),
                            ),
                          ]),
                  ),
                  const SizedBox(height: 14),

                  // ── Room Environment (shared room sensor) ─────
                  _RoomEnvironmentCard(reading: latestSensor),
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
}

// ── Shared widgets ────────────────────────────────────────────────────────────

/// A safety alert, sourced from either an `elder_alerts` row or the
/// `alert_text` of a shared room sensor reading.
class _SafetyAlert {
  final String label;
  final DateTime? time;
  const _SafetyAlert({required this.label, this.time});
}

/// Room temperature & humidity from the shared `baby_sensor_readings` table.
class _RoomEnvironmentCard extends StatelessWidget {
  final BabySensorReading? reading;
  const _RoomEnvironmentCard({required this.reading});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      header: _SectionHeader(
        title: 'Room Environment',
        icon: Icons.sensors_rounded,
        color: AppTheme.elderAccent,
        trailing: reading?.measuredAt != null
            ? Text(
                timeago.format(reading!.measuredAt!),
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.textSecondary),
              )
            : null,
      ),
      child: Row(children: [
        Expanded(
          child: _VitalMini(
            icon: Icons.thermostat,
            label: 'Room Temp',
            value: reading?.roomTemperature != null
                ? '${reading!.roomTemperature}°C'
                : '--',
            unit: '°C',
            color: AppTheme.warning,
            status: '',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _VitalMini(
            icon: Icons.water_drop,
            label: 'Humidity',
            value:
                reading?.humidity != null ? '${reading!.humidity}%' : '--',
            unit: '%',
            color: AppTheme.primary,
            status: '',
          ),
        ),
      ]),
    );
  }
}

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
  final DateTime? time;

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
              if (time != null)
                Text(timeago.format(time!),
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
