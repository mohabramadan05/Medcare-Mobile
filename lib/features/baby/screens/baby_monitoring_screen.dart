import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../models/baby_model.dart';

// ── Real-time providers ──────────────────────────────────────────────────────

final _babyAlertsStreamProvider =
    StreamProvider.family<List<BabyAlertModel>, String>((ref, babyId) {
  return Supabase.instance.client
      .from('baby_alerts')
      .stream(primaryKey: ['id'])
      .eq('baby_id', babyId)
      .order('alert_time', ascending: false)
      .limit(10)
      .map((data) => data.map((e) => BabyAlertModel.fromJson(e)).toList());
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
    final alertsAsync = ref.watch(_babyAlertsStreamProvider(babyId));
    final alerts =
        alertsAsync.whenOrNull(data: (d) => d) ?? <BabyAlertModel>[];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.monitoring,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(patientCode,
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
      body: alertsAsync.isLoading
          ? const LoadingWidget()
          : RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(_babyAlertsStreamProvider(babyId));
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
                      trailing: _LiveBadge(),
                    ),
                    child: Column(children: [
                      Container(
                        height: 160,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFAD1457),
                              AppTheme.babyAccent
                            ],
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
                                  color:
                                      Colors.white.withValues(alpha: 0.7),
                                  size: 40),
                              const SizedBox(height: 8),
                              Text(l.babyCameraFeed,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15)),
                              const SizedBox(height: 4),
                              Text("$babyName's Room",
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
                            foregroundColor: AppTheme.babyAccent,
                            side: BorderSide(
                                color: AppTheme.babyAccent
                                    .withValues(alpha: 0.4)),
                          ),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 14),

                  // ── Safety Alerts ─────────────────────────────
                  _SectionCard(
                    color: AppTheme.babyAccent,
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
                        child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
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
                                alerts.isEmpty
                                    ? l.allClear
                                    : '${alerts.length}',
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
                                    time: a.alertTime,
                                    color: AppTheme.babyAccent))
                                .toList(),
                          ),
                  ),
                  const SizedBox(height: 14),

                  // ── Baby Vitals Placeholder ───────────────────
                  _SectionCard(
                    color: AppTheme.babyAccent,
                    header: _SectionHeader(
                      title: l.dailyVitals,
                      icon: Icons.favorite_rounded,
                      color: AppTheme.babyAccent,
                    ),
                    child: Column(children: [
                      Row(children: [
                        Expanded(
                          child: _VitalMini(
                            icon: Icons.favorite,
                            label: l.hrReading,
                            value: '--',
                            color: AppTheme.error,
                            status: '',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _VitalMini(
                            icon: Icons.thermostat,
                            label: l.temperatureLabel,
                            value: '--',
                            color: AppTheme.warning,
                            status: '',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _VitalMini(
                            icon: Icons.air,
                            label: l.spO2,
                            value: '--',
                            color: AppTheme.primary,
                            status: '',
                          ),
                        ),
                      ]),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.babyAccent.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color:
                                  AppTheme.babyAccent.withValues(alpha: 0.2)),
                        ),
                        child: Row(children: [
                          Icon(Icons.info_outline,
                              size: 14,
                              color: AppTheme.babyAccent
                                  .withValues(alpha: 0.7)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l.connectBabyMonitor,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary),
                            ),
                          ),
                        ]),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

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
              fontSize: 14, fontWeight: FontWeight.bold, color: color)),
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
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(_icon(label), size: 16, color: color),
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
  final Color color;
  final String status;

  const _VitalMini({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
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
            style:
                TextStyle(fontSize: 12, color: color.withValues(alpha: 0.7))),
      ]),
    );
  }
}
