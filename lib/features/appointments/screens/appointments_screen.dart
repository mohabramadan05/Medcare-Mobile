import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../providers/appointments_provider.dart';
import '../models/appointment_model.dart';

class AppointmentsScreen extends ConsumerWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.appointmentsTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: l.tabUpcoming),
              Tab(text: l.tabCompleted),
              Tab(text: l.tabCancelled),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton.icon(
                onPressed: () => context.push('/appointments/add'),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(l.newAppointment),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
        body: const _AppointmentTabs(),
      ),
    );
  }
}

class _AppointmentTabs extends ConsumerWidget {
  const _AppointmentTabs();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final appsAsync = ref.watch(appointmentsProvider);
    return appsAsync.when(
      loading: () => const LoadingWidget(),
      error: (e, _) => AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(appointmentsProvider)),
      data: (all) {
        final upcoming = all.where((a) => a.status == 'upcoming').toList();
        final completed = all.where((a) => a.status == 'completed').toList();
        final cancelled = all.where((a) => a.status == 'cancelled').toList();
        return TabBarView(
          children: [
            _AppointmentList(
              appointments: upcoming,
              emptyTitle: l.noUpcoming,
              emptySubtitle: l.noUpcomingSubtitle,
              onRefresh: () async => ref.invalidate(appointmentsProvider),
            ),
            _AppointmentList(
              appointments: completed,
              emptyTitle: l.noCompleted,
              emptySubtitle: l.noCompletedSubtitle,
              onRefresh: () async => ref.invalidate(appointmentsProvider),
            ),
            _AppointmentList(
              appointments: cancelled,
              emptyTitle: l.noCancelled,
              emptySubtitle: l.noCancelledSubtitle,
              onRefresh: () async => ref.invalidate(appointmentsProvider),
            ),
          ],
        );
      },
    );
  }
}

class _AppointmentList extends StatelessWidget {
  final List<AppointmentModel> appointments;
  final String emptyTitle;
  final String emptySubtitle;
  final Future<void> Function() onRefresh;

  const _AppointmentList({
    required this.appointments,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.onRefresh,
  });

  Color _statusColor(String s) {
    switch (s) {
      case 'completed':
        return AppTheme.healthGreen;
      case 'cancelled':
        return AppTheme.error;
      default:
        return AppTheme.primary;
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case 'completed':
        return Icons.check_circle_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.schedule_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (appointments.isEmpty) {
      return EmptyStateWidget(
          icon: Icons.calendar_month_outlined,
          title: emptyTitle,
          subtitle: emptySubtitle);
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: appointments.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final a = appointments[i];
          final statusColor = _statusColor(a.status);
          final patientColor = a.patientType == 'baby'
              ? AppTheme.babyAccent
              : AppTheme.elderAccent;

          return Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.cardShadow,
            ),
            child: IntrinsicHeight(
              child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left status strip
                Container(
                  width: 5,
                  constraints: const BoxConstraints(minHeight: 80),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(16)),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row: status badge + patient type badge
                        Row(children: [
                          Icon(_statusIcon(a.status),
                              size: 14, color: statusColor),
                          const SizedBox(width: 5),
                          Text(
                            a.status[0].toUpperCase() +
                                a.status.substring(1),
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: statusColor),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                                color: patientColor
                                    .withValues(alpha: 0.1),
                                borderRadius:
                                    BorderRadius.circular(6)),
                            child: Text(
                              a.patientType?.toUpperCase() ??
                                  'PATIENT',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: patientColor),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 8),
                        // Appointment type
                        Text(
                          a.appointmentType ?? l.generalConsultation,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary),
                        ),
                        // Patient name
                        if (a.patientName != 'Patient') ...[
                          const SizedBox(height: 2),
                          Row(children: [
                            Icon(
                              a.patientType == 'baby'
                                  ? Icons.child_care_rounded
                                  : Icons.elderly_rounded,
                              size: 13,
                              color: patientColor,
                            ),
                            const SizedBox(width: 4),
                            Text(a.patientName,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: patientColor,
                                    fontWeight: FontWeight.w500)),
                          ]),
                        ],
                        const SizedBox(height: 8),
                        // Date + time
                        Row(children: [
                          const Icon(Icons.calendar_today_outlined,
                              size: 13,
                              color: AppTheme.textSecondary),
                          const SizedBox(width: 5),
                          Text(
                            DateFormat('EEE, MMM dd yyyy')
                                .format(a.appointmentAt),
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary),
                          ),
                          const SizedBox(width: 14),
                          const Icon(Icons.access_time_rounded,
                              size: 13,
                              color: AppTheme.textSecondary),
                          const SizedBox(width: 5),
                          Text(
                            DateFormat('hh:mm a').format(a.appointmentAt),
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary),
                          ),
                        ]),
                        // Notes
                        if (a.notes != null &&
                            a.notes!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.background,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(a.notes!,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                    height: 1.4)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
            ),
          );
        },
      ),
    );
  }
}
