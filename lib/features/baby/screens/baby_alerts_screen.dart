import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../providers/baby_provider.dart';

class BabyAlertsScreen extends ConsumerWidget {
  final String babyId;
  const BabyAlertsScreen({super.key, required this.babyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final alertsAsync = ref.watch(babyAlertsProvider(babyId));
    return Scaffold(
      appBar: AppBar(title: Text(l.alerts)),
      body: alertsAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => AppErrorWidget(
            message: e.toString(),
            onRetry: () =>
                ref.invalidate(babyAlertsProvider(babyId))),
        data: (alerts) {
          if (alerts.isEmpty) {
            return EmptyStateWidget(
                icon: Icons.notifications_none,
                title: l.noAlerts,
                subtitle: l.babyAlertsSubtitle);
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: alerts.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final a = alerts[i];
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppTheme.error
                          .withValues(alpha: 0.3)),
                ),
                child: Row(children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                        color: AppTheme.error
                            .withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(10)),
                    child: const Icon(
                        Icons.notifications_active,
                        color: AppTheme.error,
                        size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                            a.detectedObject ??
                                l.alertDetected,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14)),
                        Text(
                            DateFormat(
                                    'MMM dd, yyyy • hh:mm a')
                                .format(a.alertTime),
                            style: const TextStyle(
                                fontSize: 12,
                                color:
                                    AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right,
                      color: AppTheme.textLight),
                ]),
              );
            },
          );
        },
      ),
    );
  }
}
