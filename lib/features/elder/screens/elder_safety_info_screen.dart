import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';
import '../providers/elder_provider.dart';

class ElderSafetyInfoScreen extends ConsumerStatefulWidget {
  final String elderId;
  const ElderSafetyInfoScreen({super.key, required this.elderId});

  @override
  ConsumerState<ElderSafetyInfoScreen> createState() =>
      _ElderSafetyInfoScreenState();
}

class _ElderSafetyInfoScreenState
    extends ConsumerState<ElderSafetyInfoScreen> {
  final _p1Name = TextEditingController();
  final _p1Phone = TextEditingController();
  final _p1Rel = TextEditingController();
  final _p2Name = TextEditingController();
  final _p2Phone = TextEditingController();
  final _p2Rel = TextEditingController();
  final _addInfo = TextEditingController();
  bool _loading = false;
  bool _initialized = false;

  @override
  void dispose() {
    _p1Name.dispose(); _p1Phone.dispose(); _p1Rel.dispose();
    _p2Name.dispose(); _p2Phone.dispose(); _p2Rel.dispose();
    _addInfo.dispose();
    super.dispose();
  }

  void _init(dynamic info) {
    if (_initialized || info == null) return;
    _initialized = true;
    _p1Name.text = info.primaryContactName ?? '';
    _p1Phone.text = info.primaryContactPhone ?? '';
    _p1Rel.text = info.primaryContactRelationship ?? '';
    _p2Name.text = info.secondaryContactName ?? '';
    _p2Phone.text = info.secondaryContactPhone ?? '';
    _p2Rel.text = info.secondaryContactRelationship ?? '';
    _addInfo.text = info.additionalSafetyInformation ?? '';
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      await Supabase.instance.client.from('elder_safety_info').upsert({
        'elder_id': widget.elderId,
        'primary_contact_name': _p1Name.text.trim(),
        'primary_contact_phone': _p1Phone.text.trim(),
        'primary_contact_relationship': _p1Rel.text.trim(),
        'secondary_contact_name': _p2Name.text.trim(),
        'secondary_contact_phone': _p2Phone.text.trim(),
        'secondary_contact_relationship': _p2Rel.text.trim(),
        'additional_safety_information': _addInfo.text.trim(),
        'updated_by': userId,
      });
      ref.invalidate(elderSafetyInfoProvider(widget.elderId));
      if (mounted) {
        final l = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(l.safetyInfoSaved),
            backgroundColor: AppTheme.healthGreen));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.error));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final safetyAsync =
        ref.watch(elderSafetyInfoProvider(widget.elderId));
    return Scaffold(
      appBar: AppBar(title: Text(l.safetyInfo)),
      body: safetyAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => AppErrorWidget(
            message: e.toString(),
            onRetry: () =>
                ref.invalidate(elderSafetyInfoProvider(widget.elderId))),
        data: (info) {
          _init(info);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionHeader(
                    label: l.primaryContact,
                    icon: Icons.person_pin,
                    color: AppTheme.error),
                const SizedBox(height: 12),
                TextField(
                    controller: _p1Name,
                    decoration: InputDecoration(
                        labelText: l.fullName,
                        prefixIcon: const Icon(Icons.person))),
                const SizedBox(height: 12),
                TextField(
                    controller: _p1Phone,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                        labelText: l.phoneNumber,
                        prefixIcon: const Icon(Icons.phone))),
                const SizedBox(height: 12),
                TextField(
                    controller: _p1Rel,
                    decoration: InputDecoration(
                        labelText: l.relationship,
                        prefixIcon: const Icon(Icons.family_restroom))),
                const SizedBox(height: 20),
                _SectionHeader(
                    label: l.secondaryContact,
                    icon: Icons.person_pin_circle,
                    color: AppTheme.elderAccent),
                const SizedBox(height: 12),
                TextField(
                    controller: _p2Name,
                    decoration: InputDecoration(
                        labelText: l.fullName,
                        prefixIcon: const Icon(Icons.person))),
                const SizedBox(height: 12),
                TextField(
                    controller: _p2Phone,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                        labelText: l.phoneNumber,
                        prefixIcon: const Icon(Icons.phone))),
                const SizedBox(height: 12),
                TextField(
                    controller: _p2Rel,
                    decoration: InputDecoration(
                        labelText: l.relationship,
                        prefixIcon: const Icon(Icons.family_restroom))),
                const SizedBox(height: 20),
                _SectionHeader(
                    label: l.additionalInfo,
                    icon: Icons.info_outline,
                    color: AppTheme.primary),
                const SizedBox(height: 12),
                TextField(
                    controller: _addInfo,
                    maxLines: 4,
                    decoration: InputDecoration(
                        labelText: l.safetyNotes,
                        alignLabelWithHint: true)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loading ? null : _save,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(l.saveSafetyInfo),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _SectionHeader(
      {required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 20, color: color),
      const SizedBox(width: 8),
      Text(label,
          style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.bold, color: color)),
    ]);
  }
}
