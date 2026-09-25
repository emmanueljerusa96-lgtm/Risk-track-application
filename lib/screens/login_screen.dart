import 'package:flutter/material.dart';

import '../app/routes.dart';
import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../utils/validators.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/risk_logo.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose(); _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await AuthService().login(email: _email.text, password: _password.text);
      await AnalyticsService.instance.logLogin();
      // AuthGate replaces this child when Firebase publishes the signed-in user.
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppHelpers.friendlyError(error))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 34, 24, 30),
          child: Form(key: _form, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(child: RiskLogo()),
              const SizedBox(height: 47),
              Text('Welcome back', style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800, color: AppColors.ink)),
              const SizedBox(height: 5),
              const Text('Sign in to keep your community informed.',
                style: TextStyle(color: AppColors.muted)),
              const SizedBox(height: 26),
              CustomTextField(controller: _email, label: 'Email address',
                icon: Icons.mail_outline, keyboardType: TextInputType.emailAddress,
                validator: Validators.email, textInputAction: TextInputAction.next),
              const SizedBox(height: 14),
              CustomTextField(controller: _password, label: 'Password',
                icon: Icons.lock_outline, obscureText: true,
                validator: (v) => v == null || v.isEmpty ? 'Enter your password.' : null,
                textInputAction: TextInputAction.done),
              Align(alignment: Alignment.centerRight,
                child: TextButton(onPressed: () => AppRoutes.push(context,
                  const ForgotPasswordScreen()), child: const Text('Forgot password?'))),
              const SizedBox(height: 16),
              CustomButton(label: 'Sign in', onPressed: _login, loading: _busy),
              const SizedBox(height: 22),
              Center(child: TextButton(
                onPressed: () => AppRoutes.push(context, const RegisterScreen()),
                child: const Text('New here? Create an account'),
              )),
            ],
          )),
        )),
      );
}
