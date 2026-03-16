import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/api_service.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String email;
  final String phone; // kept for API lookup fallback
  const OtpScreen({super.key, required this.email, this.phone = ''});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final List<TextEditingController> _ctrls = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _nodes = List.generate(6, (_) => FocusNode());
  bool _loading = false;
  bool _resending = false;

  String get _otp => _ctrls.map((c) => c.text).join();

  // Masked email for display, e.g. de***@gmail.com
  String get _maskedEmail {
    if (widget.email.isEmpty) return 'your email';
    final parts = widget.email.split('@');
    if (parts.length != 2) return widget.email;
    final name = parts[0];
    final masked = name.length > 2 ? '${name.substring(0, 2)}***' : '***';
    return '$masked@${parts[1]}';
  }

  void _onChanged(int index, String val) {
    if (val.isNotEmpty && index < 5) {
      FocusScope.of(context).requestFocus(_nodes[index + 1]);
    } else if (val.isEmpty && index > 0) {
      FocusScope.of(context).requestFocus(_nodes[index - 1]);
    }
  }

  Future<void> _verify() async {
    if (_otp.length < 6) return;
    setState(() => _loading = true);
    try {
      await ref.read(authProvider.notifier).verifyOtp(widget.email, widget.phone, _otp);
      if (mounted) context.go('/home');
    } on DioException catch (e) {
      final body = e.response?.data;
      final msg = (body is Map && body['error'] != null) ? body['error'].toString() : 'Verification failed.';
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.pdpRed));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.pdpRed));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    try {
      final api = ref.read(apiServiceProvider);
      await api.resendOtp(widget.email.isNotEmpty ? widget.email : widget.phone);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP resent to your email!')));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to resend OTP.')));
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Your Email')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.email_outlined, color: AppColors.green, size: 48),
            ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: 24),
            Text('Check Your Email', style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 8),
            Text(
              'We sent a 6-digit verification code to\n$_maskedEmail',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Check your spam folder if you don\'t see it.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                    fontStyle: FontStyle.italic,
                    fontSize: 12,
                  ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                6,
                (i) => SizedBox(
                  width: 48,
                  height: 56,
                  child: TextField(
                    controller: _ctrls[i],
                    focusNode: _nodes[i],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppColors.green),
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: AppColors.surfaceElevated,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.green),
                      ),
                    ),
                    onChanged: (v) => _onChanged(i, v),
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _loading ? null : _verify,
              child: _loading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Verify & Continue'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _resending ? null : _resend,
              child: _resending
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text('Resend Code', style: TextStyle(color: AppColors.green)),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('You can sign in and verify later from your profile.'),
                    duration: Duration(seconds: 3),
                  ),
                );
                context.go('/auth/login');
              },
              child: Text(
                'Verify Later',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
