import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/patient_card.dart';
import '../providers/baby_provider.dart';

class BabiesListScreen extends ConsumerWidget {
  const BabiesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final babiesAsync = ref.watch(userBabiesProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.myBabiesTitle)),
      body: babiesAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(userBabiesProvider),
        ),
        data: (babies) {
          if (babies.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.child_care,
              title: l.noBabiesYet,
              subtitle: l.noBabiesSubtitle,
              action: ElevatedButton.icon(
                onPressed: () => context.push('/babies/add'),
                icon: const Icon(Icons.add),
                label: Text(l.addBaby),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(userBabiesProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: babies.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final baby = babies[i];
                return PatientCard(
                  name: baby.name,
                  code: baby.patientCode,
                  subtitle: '${baby.ageLabel} • ${baby.gender ?? "Unknown"}',
                  accentColor: AppTheme.babyAccent,
                  icon: Icons.child_care,
                  onTap: () => context.push('/babies/${baby.id}'),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/babies/add'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
