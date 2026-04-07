import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../baby/providers/baby_provider.dart';
import '../../elder/providers/elder_provider.dart';
import '../providers/appointments_provider.dart';

class AddAppointmentScreen extends ConsumerStatefulWidget {
  const AddAppointmentScreen({super.key});

  @override
  ConsumerState<AddAppointmentScreen> createState() =>
      _AddAppointmentScreenState();
}

class _AddAppointmentScreenState extends ConsumerState<AddAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _typeCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _patientType = 'baby';
  String? _selectedPatientId;
  DateTime? _dateTime;
  bool _loading = false;

  @override
  void dispose() {
    _typeCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time =
        await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null) return;
    setState(() => _dateTime =
        DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dateTime == null || _selectedPatientId == null) return;

    setState(() => _loading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      await Supabase.instance.client.from('appointments').insert({
        'patient_type': _patientType,
        'baby_id': _patientType == 'baby' ? _selectedPatientId : null,
        'elder_id': _patientType == 'elder' ? _selectedPatientId : null,
        'appointment_at': _dateTime!.toIso8601String(),
        'appointment_type': _typeCtrl.text,
        'notes': _notesCtrl.text,
        'created_by': userId,
        'status': 'upcoming',
      });

      ref.invalidate(appointmentsProvider);
      if (mounted) context.pop();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final babiesAsync = ref.watch(userBabiesProvider);
    final eldersAsync = ref.watch(userEldersProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.addAppointment)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.patientType,
                  style:
                      const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: _TypeChip(
                    label: l.baby,
                    icon: Icons.child_care,
                    color: AppTheme.babyAccent,
                    selected: _patientType == 'baby',
                    onTap: () => setState(() {
                      _patientType = 'baby';
                      _selectedPatientId = null;
                    }),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TypeChip(
                    label: l.elder,
                    icon: Icons.elderly,
                    color: AppTheme.elderAccent,
                    selected: _patientType == 'elder',
                    onTap: () => setState(() {
                      _patientType = 'elder';
                      _selectedPatientId = null;
                    }),
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedPatientId,
                decoration: InputDecoration(
                    labelText: l.selectPatient,
                    prefixIcon: const Icon(Icons.person)),
                items: _patientType == 'baby'
                    ? (babiesAsync.whenOrNull(data: (b) => b) ?? [])
                        .map((b) =>
                            DropdownMenuItem(value: b.id, child: Text(b.name)))
                        .toList()
                    : (eldersAsync.whenOrNull(data: (e) => e) ?? [])
                        .map((e) => DropdownMenuItem(
                            value: e.id, child: Text(e.fullName)))
                        .toList(),
                onChanged: (v) => setState(() => _selectedPatientId = v),
                validator: (v) => v == null ? l.selectPatientError : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _typeCtrl,
                decoration: InputDecoration(
                    labelText: l.appointmentType,
                    prefixIcon: const Icon(Icons.medical_services_outlined),
                    hintText: l.appointmentTypeHint),
                validator: (v) => v == null || v.isEmpty
                    ? l.appointmentTypeRequired
                    : null,
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _pickDateTime,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    border: Border.all(color: AppTheme.border),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(children: [
                    const Icon(Icons.calendar_today,
                        color: AppTheme.textSecondary, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      _dateTime != null
                          ? DateFormat('MMM dd, yyyy • hh:mm a')
                              .format(_dateTime!)
                          : l.selectDateTime,
                      style: TextStyle(
                          color: _dateTime != null
                              ? AppTheme.textPrimary
                              : AppTheme.textLight,
                          fontSize: 15),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                    labelText: '${l.notes} (${l.optional})',
                    prefixIcon: const Icon(Icons.note_outlined),
                    alignLabelWithHint: true),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(l.scheduleAppointment),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip(
      {required this.label,
      required this.icon,
      required this.color,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.1) : AppTheme.surface,
          border: Border.all(
              color: selected ? color : AppTheme.border,
              width: selected ? 2 : 1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 18, color: selected ? color : AppTheme.textSecondary),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    color: selected ? color : AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}
