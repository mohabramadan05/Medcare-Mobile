import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';
import '../providers/elder_provider.dart';

class ElderDetailScreen extends ConsumerWidget {
  final String elderId;
  const ElderDetailScreen({super.key, required this.elderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elderAsync = ref.watch(elderDetailProvider(elderId));
    return elderAsync.when(
      loading: () => const Scaffold(body: LoadingWidget()),
      error: (e, _) =>
          Scaffold(body: AppErrorWidget(message: e.toString())),
      data: (elder) {
        if (elder == null) {
          return const Scaffold(
              body: Center(child: Text('Elder not found')));
        }
        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 190,
                pinned: true,
                backgroundColor: AppTheme.elderAccent,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.elderAccent,
                          Color(0xFF4F46E5)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                            20, 60, 20, 20),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          mainAxisAlignment:
                              MainAxisAlignment.end,
                          children: [
                            Row(children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                    color: Colors.white
                                        .withValues(alpha: 0.3),
                                    shape: BoxShape.circle),
                                child: const Icon(Icons.elderly,
                                    size: 30,
                                    color: Colors.white),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(elder.fullName,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight:
                                                FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2),
                                      decoration: BoxDecoration(
                                          color: Colors.white
                                              .withValues(
                                                  alpha: 0.25),
                                          borderRadius:
                                              BorderRadius.circular(
                                                  6)),
                                      child: Text(
                                          elder.patientCode,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight:
                                                  FontWeight.w600)),
                                    ),
                                  ],
                                ),
                              ),
                            ]),
                            const SizedBox(height: 10),
                            Wrap(spacing: 8, children: [
                              if (elder.age != null)
                                _InfoChip(
                                    label:
                                        '${elder.age} years old'),
                              if (elder.bloodType != null)
                                _InfoChip(
                                    label: elder.bloodType!),
                            ]),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.2,
                  ),
                  delegate: SliverChildListDelegate([
                    _FeatureCard(
                        icon: Icons.monitor_heart,
                        label: 'Vitals',
                        color: AppTheme.error,
                        onTap: () => context
                            .push('/elders/$elderId/vitals')),
                    _FeatureCard(
                        icon: Icons.medication,
                        label: 'Medications',
                        color: AppTheme.warning,
                        onTap: () => context
                            .push('/elders/$elderId/medications')),
                    _FeatureCard(
                        icon: Icons.folder_special,
                        label: 'Health Records',
                        color: AppTheme.primary,
                        onTap: () => context.push(
                            '/elders/$elderId/health-records')),
                    _FeatureCard(
                        icon: Icons.notifications_active,
                        label: 'Alerts',
                        color: AppTheme.error,
                        onTap: () => context
                            .push('/elders/$elderId/alerts')),
                    _FeatureCard(
                        icon: Icons.security,
                        label: 'Safety Info',
                        color: AppTheme.healthGreen,
                        onTap: () => context
                            .push('/elders/$elderId/safety')),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(12)),
      child: Text(label,
          style: const TextStyle(color: Colors.white, fontSize: 12)),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _FeatureCard(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 10),
            Text(label,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
