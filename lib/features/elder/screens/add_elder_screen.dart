import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/elder_provider.dart';

class AddElderScreen extends ConsumerStatefulWidget {
  const AddElderScreen({super.key});

  @override
  ConsumerState<AddElderScreen> createState() =>
      _AddElderScreenState();
}

class _AddElderScreenState extends ConsumerState<AddElderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  DateTime? _dob;
  String? _bloodType;
  bool _loading = false;

  final _bloodTypes = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  String _generateCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random();
    return 'ELD-${List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join()}';
  }

  int? _calcAge() {
    if (_dob == null) return null;
    final now = DateTime.now();
    int age = now.year - _dob!.year;
    if (now.month < _dob!.month ||
        (now.month == _dob!.month && now.day < _dob!.day)) { age--; }
    return age;
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate:
          DateTime.now().subtract(const Duration(days: 365 * 60)),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (d != null) setState(() => _dob = d);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser!.id;
      final elder = await client.from('elders').insert({
        'patient_code': _generateCode(),
        'full_name': _nameCtrl.text.trim(),
        if (_dob != null)
          'date_of_birth': DateFormat('yyyy-MM-dd').format(_dob!),
        if (_dob != null) 'age': _calcAge(),
        if (_bloodType != null) 'blood_type': _bloodType,
        if (_phoneCtrl.text.isNotEmpty)
          'phone_number': _phoneCtrl.text.trim(),
        if (_addressCtrl.text.isNotEmpty)
          'home_address': _addressCtrl.text.trim(),
        'created_by': userId,
      }).select().single();
      await client.from('user_elders')
          .insert({'user_id': userId, 'elder_id': elder['id']});
      ref.invalidate(userEldersProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Elder added successfully!'),
            backgroundColor: AppTheme.healthGreen));
        context.pop();
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
    return Scaffold(
      appBar: AppBar(title: const Text('Add Elder')),
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
                    labelText: 'Full Name *',
                    prefixIcon: Icon(Icons.person)),
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
                          : 'Date of Birth',
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
                initialValue: _bloodType,
                decoration: const InputDecoration(
                    labelText: 'Blood Type',
                    prefixIcon:
                        Icon(Icons.water_drop_outlined)),
                items: _bloodTypes
                    .map((bt) => DropdownMenuItem(
                        value: bt, child: Text(bt)))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _bloodType = v),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone_outlined)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                    labelText: 'Home Address',
                    prefixIcon: Icon(Icons.home_outlined),
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
                    : const Text('Add Elder'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
