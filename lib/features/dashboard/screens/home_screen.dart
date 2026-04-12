import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../auth/providers/auth_provider.dart';
import 'main_shell.dart';
import '../../baby/providers/baby_provider.dart';
import '../../elder/providers/elder_provider.dart';
import '../../appointments/providers/appointments_provider.dart';
import '../../appointments/models/appointment_model.dart';
import '../../baby/models/baby_model.dart';
import '../../elder/models/elder_model.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final babiesAsync = ref.watch(userBabiesProvider);
    final eldersAsync = ref.watch(userEldersProvider);
    final upcomingAsync = ref.watch(appointmentsProvider);

    return profileAsync.when(
      loading: () => const Scaffold(body: LoadingWidget()),
      error: (e, _) => Scaffold(
          body: Center(child: Text(AppLocalizations.of(context).errorLoadingProfile))),
      data: (profile) {
        final l = AppLocalizations.of(context);
        final isDoctor = profile?.role == 'doctor';
        final name = profile?.fullName ?? 'Welcome';
        final initials = name.trim().isNotEmpty
            ? name.trim().split(' ').where((p) => p.isNotEmpty).map((p) => p[0]).take(2).join().toUpperCase()
            : '?';
        return Scaffold(
          backgroundColor: AppTheme.background,
          body: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(profileProvider);
              ref.invalidate(userBabiesProvider);
              ref.invalidate(userEldersProvider);
              ref.invalidate(appointmentsProvider);
            },
            child: CustomScrollView(
              slivers: [
                // ── Header ──────────────────────────────────────────
                SliverAppBar(
                  expandedHeight: 170,
                  floating: true,
                  pinned: false,
                  backgroundColor: AppTheme.primary,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF1D4ED8), AppTheme.primary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${_greeting(context)} 👋',
                                          style: TextStyle(
                                              color: Colors.white
                                                  .withValues(alpha: 0.8),
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          name,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: -0.3),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Avatar circle
                                  Container(
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white
                                              .withValues(alpha: 0.4),
                                          width: 1.5),
                                    ),
                                    child: Center(
                                      child: Text(initials,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.favorite_rounded,
                                        size: 12, color: Colors.white),
                                    const SizedBox(width: 5),
                                    Text(
                                      isDoctor
                                          ? l.doctorDashboard
                                          : l.yourHealthOurCare,
                                      style: TextStyle(
                                          color: Colors.white
                                              .withValues(alpha: 0.9),
                                          fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    const BiometricToggleButton(),
                    const LangToggleButton(),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.logout_rounded,
                            color: Colors.white, size: 18),
                      ),
                      onPressed: () async {
                        await ref
                            .read(supabaseClientProvider)
                            .auth
                            .signOut();
                        if (context.mounted) context.go('/login');
                      },
                    ),
                    const SizedBox(width: 4),
                  ],
                ),

                if (isDoctor)
                  _DoctorHomeContent()
                else
                  _UserHomeContent(
                    babiesAsync: babiesAsync,
                    eldersAsync: eldersAsync,
                    upcomingAsync: upcomingAsync,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _greeting(BuildContext context) {
    final l = AppLocalizations.of(context);
    final h = DateTime.now().hour;
    if (h < 12) return l.goodMorning;
    if (h < 17) return l.goodAfternoon;
    return l.goodEvening;
  }
}

// ─────────────────────────────────────────────
class _UserHomeContent extends ConsumerWidget {
  final AsyncValue<List<BabyModel>> babiesAsync;
  final AsyncValue<List<ElderModel>> eldersAsync;
  final AsyncValue<List<AppointmentModel>> upcomingAsync;

  const _UserHomeContent({
    required this.babiesAsync,
    required this.eldersAsync,
    required this.upcomingAsync,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final babies =
        babiesAsync.whenOrNull(data: (d) => d) ?? <BabyModel>[];
    final elders =
        eldersAsync.whenOrNull(data: (d) => d) ?? <ElderModel>[];
    final all =
        upcomingAsync.whenOrNull(data: (d) => d) ?? <AppointmentModel>[];
    final upcoming =
        all.where((a) => a.status == 'upcoming').toList();
    final l = AppLocalizations.of(context);

    return SliverList(
      delegate: SliverChildListDelegate([
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Quick Actions ─────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _QuickAction(
                    icon: Icons.child_care_rounded,
                    label: l.myBabies,
                    color: AppTheme.babyAccent,
                    onTap: () => context.push('/babies'),
                  ),
                  _QuickAction(
                    icon: Icons.elderly_rounded,
                    label: l.myElders,
                    color: AppTheme.elderAccent,
                    onTap: () => context.push('/elders'),
                  ),
                  _QuickAction(
                    icon: Icons.calendar_month_rounded,
                    label: l.schedule,
                    color: AppTheme.primary,
                    onTap: () => context.go('/appointments'),
                  ),
                  _QuickAction(
                    icon: Icons.search_rounded,
                    label: l.doctors,
                    color: AppTheme.healthGreen,
                    onTap: () => context.push('/doctors'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Stats ────────────────────────────────────────
              Row(children: [
                Expanded(
                  child: StatCard(
                    icon: Icons.child_care_rounded,
                    label: l.myBabies,
                    value: '${babies.length}',
                    color: AppTheme.babyAccent,
                    onTap: () => context.push('/babies'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    icon: Icons.elderly_rounded,
                    label: l.myElders,
                    value: '${elders.length}',
                    color: AppTheme.elderAccent,
                    onTap: () => context.push('/elders'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    icon: Icons.event_available_rounded,
                    label: l.upcoming,
                    value: '${upcoming.length}',
                    color: AppTheme.primary,
                    onTap: () => context.go('/appointments'),
                  ),
                ),
              ]),
              const SizedBox(height: 28),

              // ── My Babies ─────────────────────────────────────
              _SectionHeader(
                title: l.myBabies,
                onSeeAll: () => context.push('/babies'),
                onAdd: () => context.push('/babies/add'),
              ),
              const SizedBox(height: 12),
              if (babies.isEmpty)
                _EmptyCard(
                  message: l.noBabiesAdded,
                  onAdd: () => context.push('/babies/add'),
                  color: AppTheme.babyAccent,
                )
              else
                SizedBox(
                  height: 120,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: babies.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: 12),
                    itemBuilder: (context, i) {
                      final b = babies[i];
                      return GestureDetector(
                        onTap: () => context.push('/babies/${b.id}'),
                        child: _PatientCard(
                          name: b.name,
                          subtitle: b.ageLabel,
                          color: AppTheme.babyAccent,
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 28),

              // ── My Elders ─────────────────────────────────────
              _SectionHeader(
                title: l.myElders,
                onSeeAll: () => context.push('/elders'),
                onAdd: () => context.push('/elders/add'),
              ),
              const SizedBox(height: 12),
              if (elders.isEmpty)
                _EmptyCard(
                  message: l.noEldersAdded,
                  onAdd: () => context.push('/elders/add'),
                  color: AppTheme.elderAccent,
                )
              else
                SizedBox(
                  height: 120,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: elders.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: 12),
                    itemBuilder: (context, i) {
                      final e = elders[i];
                      return GestureDetector(
                        onTap: () => context.push('/elders/${e.id}'),
                        child: _PatientCard(
                          name: e.fullName,
                          subtitle: e.age != null
                              ? '${e.age} ${l.yearsOld}'
                              : l.myElders,
                          color: AppTheme.elderAccent,
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 28),

              // ── Upcoming Appointments ─────────────────────────
              _SectionHeader(
                title: l.upcomingAppointments,
                onSeeAll: () => context.go('/appointments'),
                onAdd: () => context.push('/appointments/add'),
              ),
              const SizedBox(height: 12),
              if (upcoming.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Row(children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.calendar_today_outlined,
                          color: AppTheme.primary, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.noUpcomingAppointments,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: AppTheme.textPrimary)),
                        const SizedBox(height: 2),
                        Text(l.tapToSchedule,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary)),
                      ],
                    ),
                  ]),
                )
              else
                ...upcoming.take(3).map((a) => _AppointmentRow(a)),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────
class _DoctorHomeContent extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SliverFillRemaining(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle),
                child: const Icon(Icons.medical_services_rounded,
                    color: AppTheme.primary, size: 40),
              ),
              const SizedBox(height: 20),
              Text(AppLocalizations.of(context).doctorDashboard,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 8),
              Text(
                  AppLocalizations.of(context).viewAndRespondDoctors,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                      height: 1.5)),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: () => context.go('/chat'),
                icon: const Icon(Icons.chat_bubble_rounded, size: 18),
                label: Text(AppLocalizations.of(context).viewConversations),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 7),
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
class _PatientCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final Color color;

  const _PatientCard({
    required this.name,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final initial =
        name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Text(
              initial,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const Spacer(),
          Text(name,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppTheme.textPrimary),
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(subtitle,
              style: const TextStyle(
                  fontSize: 11, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
class _AppointmentRow extends StatelessWidget {
  final AppointmentModel appointment;
  const _AppointmentRow(this.appointment);

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    final typeColor = a.patientType == 'baby'
        ? AppTheme.babyAccent
        : AppTheme.elderAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(children: [
        // Left accent strip
        Container(
          width: 5,
          height: 68,
          decoration: BoxDecoration(
            color: typeColor,
            borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(14)),
          ),
        ),
        const SizedBox(width: 14),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.event_rounded,
              color: AppTheme.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(a.appointmentType ?? 'Appointment',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 2),
              Row(children: [
                const Icon(Icons.access_time_rounded,
                    size: 12, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(
                  DateFormat('MMM dd • hh:mm a')
                      .format(a.appointmentAt),
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary),
                ),
              ]),
            ],
          ),
        ),
        // Patient type badge
        Container(
          margin: const EdgeInsets.only(right: 12),
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: typeColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            a.patientType?.toUpperCase() ?? '',
            style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: typeColor),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  final VoidCallback? onAdd;

  const _SectionHeader(
      {required this.title, this.onSeeAll, this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(title,
          style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
              letterSpacing: -0.2)),
      const Spacer(),
      if (onAdd != null)
        GestureDetector(
          onTap: onAdd,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.add_rounded,
                size: 18, color: AppTheme.primary),
          ),
        ),
      if (onSeeAll != null) ...[
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onSeeAll,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('See all',
                style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    ]);
  }
}

// ─────────────────────────────────────────────
class _EmptyCard extends StatelessWidget {
  final String message;
  final VoidCallback onAdd;
  final Color color;

  const _EmptyCard(
      {required this.message, required this.onAdd, required this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onAdd,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: color.withValues(alpha: 0.2),
              style: BorderStyle.solid),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add_rounded,
                  color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Text(message,
                style: TextStyle(
                    color: color.withValues(alpha: 0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
