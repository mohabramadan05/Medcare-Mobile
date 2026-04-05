import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/patient_card.dart';
import '../providers/elder_provider.dart';

class EldersListScreen extends ConsumerWidget {
  const EldersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eldersAsync = ref.watch(userEldersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My Elders')),
      body: eldersAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => AppErrorWidget(
            message: e.toString(),
            onRetry: () => ref.invalidate(userEldersProvider)),
        data: (elders) {
          if (elders.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.elderly,
              title: 'No elders yet',
              subtitle:
                  'Add an elder to start monitoring their health',
              action: ElevatedButton.icon(
                onPressed: () => context.push('/elders/add'),
                icon: const Icon(Icons.add),
                label: const Text('Add Elder'),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(userEldersProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: elders.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final elder = elders[i];
                return PatientCard(
                  name: elder.fullName,
                  code: elder.patientCode,
                  subtitle:
                      '${elder.age != null ? "${elder.age} yrs" : ""}${elder.bloodType != null ? " • ${elder.bloodType}" : ""}',
                  accentColor: AppTheme.elderAccent,
                  icon: Icons.elderly,
                  onTap: () =>
                      context.push('/elders/${elder.id}'),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/elders/add'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
