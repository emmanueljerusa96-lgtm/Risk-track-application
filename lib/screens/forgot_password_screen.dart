import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../utils/validators.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _busy = false;
  bool _sent = false;

  @override
  void dispose() { _email.dispose(); super.dispose(); }

  Future<void> _send() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await AuthService().resetPassword(_email.text);
      if (mounted) setState(() => _sent = true);
    } catch (error) {
      if (error is FirebaseAuthException && error.code == 'user-not-found') {
        // Do not reveal whether an email address is registered.
        if (mounted) setState(() => _sent = true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppHelpers.friendlyError(error))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Reset password')),
        body: SafeArea(child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _sent
              ? Column(children: [
                  const SizedBox(height: 40),
                  const Icon(Icons.mark_email_read_outlined, size: 70,
                    color: AppColors.teal),
                  const SizedBox(height: 18),
                  const Text('Check your inbox', style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 9),
                  const Text('If this email is registered, a password reset '
                    'link is on its way. Check your spam folder too.',
                    textAlign: TextAlign.center),
                  const SizedBox(height: 25),
                  CustomButton(label: 'Back to sign in',
                    onPressed: () => Navigator.of(context).pop()),
                ])
              : Form(key: _form, child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 28),
                    const Icon(Icons.lock_reset, size: 54, color: AppColors.teal),
                    const SizedBox(height: 16),
                    const Text('Forgot your password?', style: TextStyle(
                      fontSize: 23, fontWeight: FontWeight.w800,
                      color: AppColors.ink)),
                    const SizedBox(height: 8),
                    const Text('Enter your email and we’ll send you a reset link.',
                      style: TextStyle(color: AppColors.muted)),
                    const SizedBox(height: 25),
                    CustomTextField(controller: _email, label: 'Email address',
                      keyboardType: TextInputType.emailAddress,
                      icon: Icons.mail_outline, validator: Validators.email),
                    const SizedBox(height: 22),
                    CustomButton(label: 'Send reset link', onPressed: _send,
                      loading: _busy),
                  ],
                )),
        )),
      );
}
