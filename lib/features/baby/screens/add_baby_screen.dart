import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/baby_provider.dart';

class AddBabyScreen extends ConsumerStatefulWidget {
  const AddBabyScreen({super.key});

  @override
  ConsumerState<AddBabyScreen> createState() => _AddBabyScreenState();
}

class _AddBabyScreenState extends ConsumerState<AddBabyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _lengthCtrl = TextEditingController();
  final _headCtrl = TextEditingController();
  final _problemsCtrl = TextEditingController();
  DateTime? _dob;
  String _gender = 'Male';
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _weightCtrl.dispose();
    _lengthCtrl.dispose();
    _headCtrl.dispose();
    _problemsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 30)),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (d != null) setState(() => _dob = d);
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    if (_dob == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l.selectDOB),
        backgroundColor: AppTheme.error,
      ));
      return;
    }
    setState(() => _loading = true);
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser!.id;
      final baby = await client.from('babies').insert({
        'name': _nameCtrl.text.trim(),
        'date_of_birth': DateFormat('yyyy-MM-dd').format(_dob!),
        'gender': _gender,
        if (_weightCtrl.text.isNotEmpty)
          'weight_at_birth': double.tryParse(_weightCtrl.text),
        if (_lengthCtrl.text.isNotEmpty)
          'length_at_birth': double.tryParse(_lengthCtrl.text),
        if (_headCtrl.text.isNotEmpty)
          'head_circumference': double.tryParse(_headCtrl.text),
        if (_problemsCtrl.text.isNotEmpty)
          'congenital_problems': _problemsCtrl.text.trim(),
        'created_by': userId,
      }).select().single();
      await client
          .from('user_babies')
          .insert({'user_id': userId, 'baby_id': baby['id']});
      ref.invalidate(userBabiesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l.babyAddedSuccess),
          backgroundColor: AppTheme.healthGreen,
        ));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        debugPrint("errororor " + e.toString());
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.addBaby)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                    labelText: l.babyName,
                    prefixIcon: const Icon(Icons.child_care)),
                validator: (v) =>
                    v == null || v.isEmpty ? l.nameRequired : null,
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
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
                      _dob != null
                          ? 'DOB: ${DateFormat('MMM dd, yyyy').format(_dob!)}'
                          : l.dateOfBirth,
                      style: TextStyle(
                          color: _dob != null
                              ? AppTheme.textPrimary
                              : AppTheme.textLight,
                          fontSize: 15),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: InputDecoration(
                    labelText: l.gender,
                    prefixIcon: const Icon(Icons.people_outlined)),
                items: [
                  DropdownMenuItem(value: 'Male', child: Text(l.male)),
                  DropdownMenuItem(value: 'Female', child: Text(l.female)),
                ],
                onChanged: (v) => setState(() => _gender = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _weightCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                decoration: InputDecoration(
                    labelText: l.weightAtBirth,
                    prefixIcon: const Icon(Icons.monitor_weight_outlined)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lengthCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                decoration: InputDecoration(
                    labelText: l.lengthAtBirth,
                    prefixIcon: const Icon(Icons.straighten)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _headCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                decoration: InputDecoration(
                    labelText: l.headCircumference,
                    prefixIcon: const Icon(Icons.face)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _problemsCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                    labelText: l.congenitalProblems,
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
                    : Text(l.addBaby),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
