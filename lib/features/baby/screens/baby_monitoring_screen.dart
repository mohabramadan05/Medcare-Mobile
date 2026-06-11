import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../models/baby_model.dart';
import '../services/baby_monitoring_service.dart';

// ── URL provider ──────────────────────────────────────────────────────────────
// Reads the `monitor_url` column from the `babies` table for this baby.
// Returns null when no Pi has been linked yet.
// This is the ONLY place Supabase is used in this screen — the actual
// monitoring data comes from the Pi (or test server) at that URL.

final _piUrlProvider =
    FutureProvider.family<String?, String>((ref, babyId) async {
  final data = await Supabase.instance.client
      .from('babies')
      .select('monitor_url')
      .eq('id', babyId)
      .maybeSingle(); // returns null instead of throwing when row not found
  return data?['monitor_url'] as String?;
});

// ── Monitoring data providers ─────────────────────────────────────────────────
// Family key is a Dart 3 record (babyId, url) — records have structural
// equality so Riverpod correctly caches one provider per (baby, server) pair.

final _babyAlertsStreamProvider = StreamProvider.family<List<BabyAlertModel>,
    ({String babyId, String url})>((ref, key) {
  return BabyMonitoringService.alertsStream(key.babyId, key.url);
});

final _babyVitalsStreamProvider =
    StreamProvider.family<BabyVitals, ({String babyId, String url})>(
        (ref, key) {
  return BabyMonitoringService.vitalsStream(key.babyId, key.url);
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
    final piUrlAsync = ref.watch(_piUrlProvider(babyId));

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
        // The badge is only meaningful once we know the URL; hide it while loading.
        actions: [
          if (piUrlAsync.hasValue && piUrlAsync.value != null)
            _StatusBadge(
              // Pass the live connected state down from the dashboard child.
              // We use a ValueNotifier so the AppBar updates without rebuilding
              // the whole scaffold.
              connectedNotifier: _connectedNotifier,
              l: l,
            ),
        ],
      ),
      body: piUrlAsync.when(
        // Still fetching the URL from Supabase
        loading: () => const LoadingWidget(),

        // Supabase query failed
        error: (e, _) => _ErrorPanel(
          message: 'Could not load Pi configuration.\n$e',
          onRetry: () => ref.invalidate(_piUrlProvider(babyId)),
        ),

        data: (url) {
          // No Pi has been linked to this baby yet
          if (url == null) {
            return _NotLinkedPanel(patientCode: patientCode);
          }
          // Pi URL is available — show the live dashboard
          return _MonitoringDashboard(
            babyId: babyId,
            babyName: babyName,
            serverUrl: url,
            onConnectedChanged: (v) => _connectedNotifier.value = v,
            onRefresh: () {
              ref.invalidate(_babyAlertsStreamProvider(
                  (babyId: babyId, url: url)));
              ref.invalidate(_babyVitalsStreamProvider(
                  (babyId: babyId, url: url)));
            },
          );
        },
      ),
    );
  }

  // Shared notifier so AppBar badge updates reactively without a StatefulWidget
  static final _connectedNotifier = ValueNotifier<bool>(false);
}

// ── Dashboard (shown when Pi URL is available) ────────────────────────────────

class _MonitoringDashboard extends ConsumerWidget {
  final String babyId;
  final String babyName;
  final String serverUrl;
  final ValueChanged<bool> onConnectedChanged;
  final VoidCallback onRefresh;

  const _MonitoringDashboard({
    required this.babyId,
    required this.babyName,
    required this.serverUrl,
    required this.onConnectedChanged,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final key = (babyId: babyId, url: serverUrl);

    final alertsAsync = ref.watch(_babyAlertsStreamProvider(key));
    final vitalsAsync = ref.watch(_babyVitalsStreamProvider(key));

    final alerts =
        alertsAsync.whenOrNull(data: (d) => d) ?? <BabyAlertModel>[];
    final vitals = vitalsAsync.whenOrNull(data: (v) => v);
    final connected = alertsAsync.hasValue && !alertsAsync.hasError;

    // Propagate connection state up to the AppBar badge
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => onConnectedChanged(connected));

    return alertsAsync.isLoading && !alertsAsync.hasValue
        ? const LoadingWidget()
        : RefreshIndicator(
            onRefresh: () async => onRefresh(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (alertsAsync.hasError)
                  _OfflineBanner(serverUrl: serverUrl),

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
                                color: Colors.white.withValues(alpha: 0.7),
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
                                    color:
                                        Colors.white.withValues(alpha: 0.7),
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
                              color:
                                  AppTheme.babyAccent.withValues(alpha: 0.4)),
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
                    color:
                        alerts.isEmpty ? AppTheme.healthGreen : AppTheme.warning,
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
                                  label: a.detectedObject ?? l.activityDetected,
                                  time: a.alertTime,
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
                  ),
                  child: Column(children: [
                    Row(children: [
                      Expanded(
                        child: _VitalMini(
                          icon: Icons.favorite,
                          label: l.hrReading,
                          value: vitals != null ? '${vitals.heartRate}' : '--',
                          color: AppTheme.error,
                          status: '',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _VitalMini(
                          icon: Icons.thermostat,
                          label: l.temperatureLabel,
                          value: vitals != null
                              ? '${vitals.temperature}°'
                              : '--',
                          color: AppTheme.warning,
                          status: '',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _VitalMini(
                          icon: Icons.air,
                          label: l.spO2,
                          value:
                              vitals != null ? '${vitals.spo2}%' : '--',
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
                            color: AppTheme.babyAccent.withValues(alpha: 0.2)),
                      ),
                      child: Row(children: [
                        Icon(Icons.info_outline,
                            size: 14,
                            color: AppTheme.babyAccent.withValues(alpha: 0.7)),
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
          );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

/// Listens to a ValueNotifier so only the badge re-renders on connection change.
class _StatusBadge extends StatelessWidget {
  final ValueNotifier<bool> connectedNotifier;
  final AppLocalizations l;

  const _StatusBadge(
      {required this.connectedNotifier, required this.l});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: connectedNotifier,
      builder: (_, connected, __) {
        final color = connected ? AppTheme.healthGreen : AppTheme.error;
        final label = connected ? l.live : 'OFFLINE';
        return Container(
          margin: const EdgeInsets.only(right: 12),
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 7,
                height: 7,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w600)),
          ]),
        );
      },
    );
  }
}

/// Full-screen panel shown when monitor_url is null in Supabase.
class _NotLinkedPanel extends StatelessWidget {
  final String patientCode;
  const _NotLinkedPanel({required this.patientCode});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sensors_off_rounded,
                size: 80,
                color: AppTheme.textSecondary.withValues(alpha: 0.4)),
            const SizedBox(height: 20),
            Text(
              'No Pi linked to $patientCode',
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Set the monitor_url column in Supabase\n'
              '(babies table -> row for this baby)\n'
              'to the Pi\'s ngrok URL.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

/// Thin warning strip when the Pi is unreachable.
class _OfflineBanner extends StatelessWidget {
  final String serverUrl;
  const _OfflineBanner({required this.serverUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        Icon(Icons.cloud_off,
            size: 16, color: AppTheme.error.withValues(alpha: 0.8)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Cannot reach Pi ($serverUrl). '
            'Check that server.py is running and ngrok is active.',
            style: TextStyle(
                fontSize: 11, color: AppTheme.error.withValues(alpha: 0.8)),
          ),
        ),
      ]),
    );
  }
}

/// Full-screen error panel (used for Supabase URL fetch failures).
class _ErrorPanel extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorPanel({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 72, color: AppTheme.error),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, height: 1.5)),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
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
      child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
              color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(_icon(label), size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary)),
            Text(timeago.format(time),
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
            style:
                const TextStyle(fontSize: 9, color: AppTheme.textSecondary),
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
            style: TextStyle(
                fontSize: 12, color: color.withValues(alpha: 0.7))),
      ]),
    );
  }
}
