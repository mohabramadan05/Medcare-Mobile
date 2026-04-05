import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  String _generateCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random();
    return 'BAB-${List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join()}';
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
    if (!_formKey.currentState!.validate()) return;
    if (_dob == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select date of birth'),
        backgroundColor: AppTheme.error,
      ));
      return;
    }
    setState(() => _loading = true);
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser!.id;
      final baby = await client.from('babies').insert({
        'patient_code': _generateCode(),
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Baby added successfully!'),
          backgroundColor: AppTheme.healthGreen,
        ));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
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
    return Scaffold(
      appBar: AppBar(title: const Text('Add Baby')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                    labelText: 'Baby Name *',
                    prefixIcon: Icon(Icons.child_care)),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Name is required' : null,
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
                          : 'Date of Birth *',
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
                decoration: const InputDecoration(
                    labelText: 'Gender',
                    prefixIcon: Icon(Icons.people_outlined)),
                items: ['Male', 'Female']
                    .map((g) =>
                        DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (v) => setState(() => _gender = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _weightCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                decoration: const InputDecoration(
                    labelText: 'Weight at Birth (kg)',
                    prefixIcon: Icon(Icons.monitor_weight_outlined)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lengthCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                decoration: const InputDecoration(
                    labelText: 'Length at Birth (cm)',
                    prefixIcon: Icon(Icons.straighten)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _headCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                decoration: const InputDecoration(
                    labelText: 'Head Circumference (cm)',
                    prefixIcon: Icon(Icons.face)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _problemsCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                    labelText: 'Congenital Problems (optional)',
                    prefixIcon: Icon(Icons.note_outlined),
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
                    : const Text('Add Baby'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
