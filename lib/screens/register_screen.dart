import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../utils/validators.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose(); _email.dispose(); _password.dispose(); _confirm.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await AuthService().register(
        fullName: _name.text, email: _email.text, password: _password.text);
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (error) {
      if (mounted) {
        final accountExists = AuthService().currentUser != null;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(
          accountExists
              ? 'Account created, but profile setup was interrupted. '
                  'Reconnect and tap Complete profile.'
              : AppHelpers.friendlyError(error),
        )));
        if (accountExists) Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Create account')),
        body: SafeArea(child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Form(key: _form, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Join Risk Track', style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800, color: AppColors.ink)),
              const SizedBox(height: 8),
              const Text('A safer conversation starts with better information.',
                style: TextStyle(color: AppColors.muted)),
              const SizedBox(height: 25),
              CustomTextField(controller: _name, label: 'Full name',
                icon: Icons.person_outline, validator: Validators.fullName,
                textInputAction: TextInputAction.next),
              const SizedBox(height: 14),
              CustomTextField(controller: _email, label: 'Email address',
                icon: Icons.mail_outline, keyboardType: TextInputType.emailAddress,
                validator: Validators.email, textInputAction: TextInputAction.next),
              const SizedBox(height: 14),
              CustomTextField(controller: _password, label: 'Password',
                icon: Icons.lock_outline, obscureText: true,
                validator: Validators.password, textInputAction: TextInputAction.next),
              const SizedBox(height: 14),
              CustomTextField(controller: _confirm, label: 'Confirm password',
                icon: Icons.lock_outline, obscureText: true,
                validator: (value) => value == _password.text
                    ? null : 'Passwords do not match.'),
              const SizedBox(height: 15),
              const Text('Only your name appears alongside your reports. '
                'Your email is not shown publicly.',
                style: TextStyle(fontSize: 12, color: AppColors.muted)),
              const SizedBox(height: 23),
              CustomButton(label: 'Create account', onPressed: _register,
                loading: _busy),
            ],
          )),
        )),
      );
}
