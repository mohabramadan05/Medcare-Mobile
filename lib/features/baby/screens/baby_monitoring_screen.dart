import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/app_localizations.dart';
import '../models/baby_model.dart';
import '../services/baby_monitoring_service.dart';

// ── Monitoring data providers ─────────────────────────────────────────────────
// All monitoring data is sourced from Supabase, keyed by patient code
// (e.g. "B-0001"). Each provider polls once a minute for the newest record.

// Latest room sensor reading from the `baby_sensor_readings` Supabase table.
// Keyed by patient code (e.g. "B-0001"); polls once a minute for a new record.
final _sensorReadingStreamProvider =
    StreamProvider.family<BabySensorReading?, String>((ref, patientCode) {
  return BabyMonitoringService.sensorReadingStream(patientCode);
});

// Latest wearable-band reading from the `band_readings` Supabase table.
// Keyed by patient code; polls once a minute. Drives the Daily Vitals card.
final _bandReadingStreamProvider =
    StreamProvider.family<BandReading?, String>((ref, patientCode) {
  return BabyMonitoringService.bandReadingStream(patientCode);
});

// Most recent room sensor readings (newest first). Keyed by patient code;
// polls once a minute. Feeds the Safety Alerts list.
final _recentSensorReadingsProvider =
    StreamProvider.family<List<BabySensorReading>, String>((ref, patientCode) {
  return BabyMonitoringService.recentSensorReadingsStream(patientCode);
});

// Most recent wearable-band readings (newest first). Keyed by patient code;
// polls once a minute. Feeds the Safety Alerts list.
final _recentBandReadingsProvider =
    StreamProvider.family<List<BandReading>, String>((ref, patientCode) {
  return BabyMonitoringService.recentBandReadingsStream(patientCode);
});

// ── Screen ───────────────────────────────────────────────────────────────────

class BabyMonitoringScreen extends ConsumerWidget {
  final String babyId;
  final String babyName;
  final String patientCode;

  const BabyMonitoringScreen({
    super.key,
    required this.babyId,
    required this.babyName,
    required this.patientCode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.monitoring,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(patientCode,
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.textSecondary)),
          ],
        ),
      ),
      body: _MonitoringDashboard(
        babyName: babyName,
        patientCode: patientCode,
      ),
    );
  }
}

// ── Dashboard ─────────────────────────────────────────────────────────────────
// All data comes from Supabase, keyed by patient code.

class _MonitoringDashboard extends ConsumerWidget {
  final String babyName;
  final String patientCode;

  const _MonitoringDashboard({
    required this.babyName,
    required this.patientCode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);

    final sensorAsync = ref.watch(_sensorReadingStreamProvider(patientCode));
    final reading = sensorAsync.whenOrNull(data: (r) => r);
    final bandAsync = ref.watch(_bandReadingStreamProvider(patientCode));
    final band = bandAsync.whenOrNull(data: (b) => b);

    // Safety alerts are derived from the `alert_text` of the most recent
    // Supabase readings (band + room sensor), combined and sorted newest
    // first, capped at the last 5.
    final recentBands =
        ref.watch(_recentBandReadingsProvider(patientCode)).whenOrNull(
                  data: (b) => b,
                ) ??
            const <BandReading>[];
    final recentSensors =
        ref.watch(_recentSensorReadingsProvider(patientCode)).whenOrNull(
                  data: (s) => s,
                ) ??
            const <BabySensorReading>[];

    final alerts = <_SafetyAlert>[
      for (final b in recentBands)
        if (b.alertText != null && b.alertText!.trim().isNotEmpty)
          _SafetyAlert(text: b.alertText!.trim(), time: b.measuredAt),
      for (final s in recentSensors)
        if (s.alertText != null && s.alertText!.trim().isNotEmpty)
          _SafetyAlert(text: s.alertText!.trim(), time: s.measuredAt),
    ]..sort((a, b) {
        final at = a.time, bt = b.time;
        if (at == null && bt == null) return 0;
        if (at == null) return 1;
        if (bt == null) return -1;
        return bt.compareTo(at); // newest first
      });
    final recentAlerts = alerts.take(5).toList();

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(_sensorReadingStreamProvider(patientCode));
        ref.invalidate(_bandReadingStreamProvider(patientCode));
        ref.invalidate(_recentSensorReadingsProvider(patientCode));
        ref.invalidate(_recentBandReadingsProvider(patientCode));
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Live Feed ─────────────────────────────────
          _SectionCard(
            color: AppTheme.babyAccent,
            header: _SectionHeader(
              title: l.liveFeed,
              icon: Icons.videocam_rounded,
              color: AppTheme.babyAccent,
              trailing: const _LiveBadge(),
            ),
            child: Column(children: [
              Container(
                height: 160,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFAD1457), AppTheme.babyAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.child_care,
                          color: Colors.white.withValues(alpha: 0.7), size: 40),
                      const SizedBox(height: 8),
                      Text(l.babyCameraFeed,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                      const SizedBox(height: 4),
                      Text("$babyName's Room",
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
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
                    foregroundColor: AppTheme.babyAccent,
                    side: BorderSide(
                        color: AppTheme.babyAccent.withValues(alpha: 0.4)),
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 14),

          // ── Room Environment (Supabase sensor readings) ─
          _SectionCard(
            color: AppTheme.babyAccent,
            header: _SectionHeader(
              title: 'Room Environment',
              icon: Icons.sensors_rounded,
              color: AppTheme.babyAccent,
              trailing: reading?.measuredAt != null
                  ? Text(
                      timeago.format(reading!.measuredAt!),
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary),
                    )
                  : null,
            ),
            child: Column(children: [
              Row(children: [
                Expanded(
                  child: _VitalMini(
                    icon: Icons.thermostat,
                    label: 'Room Temp',
                    value: reading?.roomTemperature != null
                        ? '${reading!.roomTemperature}°C'
                        : '--',
                    color: AppTheme.warning,
                    status: '',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _VitalMini(
                    icon: Icons.water_drop,
                    label: 'Humidity',
                    value: reading?.humidity != null
                        ? '${reading!.humidity}%'
                        : '--',
                    color: AppTheme.primary,
                    status: '',
                  ),
                ),
              ]),
            ]),
          ),
          const SizedBox(height: 14),

          // ── Safety Alerts ─────────────────────────────
          _SectionCard(
            color: AppTheme.babyAccent,
            header: _SectionHeader(
              title: l.safetyAlerts,
              icon: Icons.notifications_active_rounded,
              color:
                  recentAlerts.isEmpty ? AppTheme.healthGreen : AppTheme.warning,
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                    recentAlerts.isEmpty ? l.allClear : '${recentAlerts.length}',
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
                            label: a.text,
                            time: a.time,
                            color: AppTheme.babyAccent))
                        .toList(),
                  ),
          ),
          const SizedBox(height: 14),

          // ── Baby Vitals ───────────────────────────────
          _SectionCard(
            color: AppTheme.babyAccent,
            header: _SectionHeader(
              title: l.dailyVitals,
              icon: Icons.favorite_rounded,
              color: AppTheme.babyAccent,
              trailing: band?.measuredAt != null
                  ? Text(
                      timeago.format(band!.measuredAt!),
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary),
                    )
                  : null,
            ),
            child: Column(children: [
              Row(children: [
                Expanded(
                  child: _VitalMini(
                    icon: Icons.favorite,
                    label: l.hrReading,
                    value:
                        band?.heartRate != null ? '${band!.heartRate}' : '--',
                    color: AppTheme.error,
                    status: '',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _VitalMini(
                    icon: Icons.air,
                    label: l.spO2,
                    value: band?.spo2 != null ? '${band!.spo2}%' : '--',
                    color: AppTheme.primary,
                    status: '',
                  ),
                ),
              ]),
            ]),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

/// A safety alert derived from a Supabase reading's `alert_text`.
class _SafetyAlert {
  final String text;
  final DateTime? time;
  const _SafetyAlert({required this.text, this.time});
}

class _SectionCard extends StatelessWidget {
  final Widget header;
  final Widget child;
  final Color color;
  const _SectionCard(
      {required this.header, required this.child, required this.color});

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
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0), child: header),
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
  const _SectionHeader(
      {required this.title,
      required this.icon,
      required this.color,
      this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(width: 7),
      Text(title,
          style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      const Spacer(),
      if (trailing != null) trailing!,
    ]);
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
              color: AppTheme.healthGreen, shape: BoxShape.circle)),
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
  final Color color;
  const _AlertTile(
      {required this.label, required this.time, required this.color});

  IconData _icon(String label) {
    final l = label.toLowerCase();
    if (l.contains('cry')) return Icons.volume_up;
    if (l.contains('move')) return Icons.directions_run;
    if (l.contains('sleep')) return Icons.bedtime;
    return Icons.child_care;
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
              color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(_icon(label), size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary)),
            if (time != null)
              Text(timeago.format(time!),
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textSecondary)),
          ]),
        ),
      ]),
    );
  }
}

class _VitalMini extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final String status;
  const _VitalMini(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color,
      required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(value,
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold, color: color),
            textAlign: TextAlign.center),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary),
            textAlign: TextAlign.center),
      ]),
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
            style:
                TextStyle(fontSize: 12, color: color.withValues(alpha: 0.7))),
      ]),
    );
  }
}
