import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/providers.dart';
import '../../../core/constants/app_constants.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String? _selectedState;
  String? _selectedGender;
  final _ageCtrl = TextEditingController();
  bool _loading = false;
  bool _obscurePass = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register to Vote'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/onboarding')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress indicator
              Row(children: [
                Expanded(child: LinearProgressIndicator(value: 0.5, color: AppColors.green, backgroundColor: AppColors.surfaceElevated)),
                const SizedBox(width: 8),
                Text('Step 1 of 2', style: Theme.of(context).textTheme.bodyMedium),
              ]),
              const SizedBox(height: 28),
              Text('Personal Information', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 20),
              _field(_nameCtrl, 'Full Name', Icons.person_outline, validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 16),
              _field(_phoneCtrl, 'Phone (+234...)', Icons.phone_outlined,
                  keyboardType: TextInputType.phone, validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 16),
              _field(_emailCtrl, 'Email (optional)', Icons.email_outlined, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),
              _field(_passCtrl, 'Password', Icons.lock_outline,
                  obscure: _obscurePass,
                  suffixIcon: IconButton(
                      icon: Icon(_obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textMuted),
                      onPressed: () => setState(() => _obscurePass = !_obscurePass)),
                  validator: (v) => v!.length < 6 ? 'Minimum 6 characters' : null),
              const SizedBox(height: 16),
              // State dropdown
              DropdownButtonFormField<String>(
                value: _selectedState,
                dropdownColor: AppColors.surfaceElevated,
                decoration: InputDecoration(
                  labelText: 'State of Origin',
                  prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.textMuted),
                ),
                items: kNigeriaStates.map((s) => DropdownMenuItem(value: s['name'], child: Text(s['name']!))).toList(),
                onChanged: (v) => setState(() => _selectedState = v),
                validator: (v) => v == null ? 'Please select your state' : null,
              ),
              const SizedBox(height: 16),
              // Gender toggle
              Text('Gender', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'male', label: Text('Male'), icon: Icon(Icons.male)),
                  ButtonSegment(value: 'female', label: Text('Female'), icon: Icon(Icons.female)),
                  ButtonSegment(value: 'other', label: Text('Other')),
                ],
                selected: {_selectedGender ?? 'male'},
                onSelectionChanged: (s) => setState(() => _selectedGender = s.first),
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: AppColors.green.withOpacity(0.2),
                  selectedForegroundColor: AppColors.green,
                ),
              ),
              const SizedBox(height: 16),
              _field(_ageCtrl, 'Age', Icons.cake_outlined,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v!.isEmpty) return 'Required';
                    final age = int.tryParse(v);
                    if (age == null || age < 18) return 'Must be 18 or older';
                    return null;
                  }),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Continue — Verify via OTP'),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => context.go('/auth/login'),
                  child: Text('Already registered? Sign in', style: TextStyle(color: AppColors.textSecondary)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {TextInputType? keyboardType, bool obscure = false, Widget? suffixIcon, String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.textMuted),
        suffixIcon: suffixIcon,
      ),
      validator: validator,
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authProvider.notifier).register({
        'full_name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        'password': _passCtrl.text,
        'state': _selectedState,
        'lga': 'N/A', // TODO: LGA dynamic dropdown
        'gender': _selectedGender ?? 'male',
        'age': int.parse(_ageCtrl.text),
      });
      if (mounted) context.go('/auth/otp?phone=${Uri.encodeComponent(_phoneCtrl.text.trim())}');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.pdpRed));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
