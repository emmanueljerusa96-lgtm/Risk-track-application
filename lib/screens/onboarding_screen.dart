import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/routes.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';
import 'auth_gate.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;
  static const _items = [
    (Icons.map_outlined, 'Discover Reported Risks',
      'Explore community-submitted reports around places you care about.'),
    (Icons.add_location_alt_outlined, 'Report Risky Locations',
      'Pin a location, describe what you saw, and add a photo if helpful.'),
    (Icons.groups_2_outlined, 'Help Your Community Stay Aware',
      'Follow updates while keeping reported information separate from verified reports.'),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    try {
      await SharedPreferencesAsync().setBool('onboarding_complete', true);
    } catch (_) {
      // Do not block sign-in if preference storage fails.
    }
    if (mounted) AppRoutes.replace(context, const AuthGate());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 26),
          child: Column(children: [
            Align(alignment: Alignment.centerRight,
              child: TextButton(onPressed: _finish, child: const Text('Skip'))),
            Expanded(child: PageView(
              controller: _controller,
              onPageChanged: (index) => setState(() => _page = index),
              children: _items.map((item) => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 190, height: 190,
                    decoration: const BoxDecoration(
                      color: AppColors.mint, shape: BoxShape.circle),
                    child: Icon(item.$1, size: 96, color: AppColors.teal),
                  ),
                  const SizedBox(height: 48),
                  Text(item.$2, textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800, color: AppColors.ink)),
                  const SizedBox(height: 16),
                  Text(item.$3, textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16,
                      height: 1.5, color: AppColors.muted)),
                ],
              )).toList(),
            )),
            Row(mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: _page == index ? 26 : 8, height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: _page == index ? AppColors.teal : AppColors.border,
                  borderRadius: BorderRadius.circular(8),
                ),
              ))),
            const SizedBox(height: 28),
            CustomButton(label: _page == 2 ? 'Get Started' : 'Continue',
              onPressed: _page == 2 ? _finish : () => _controller.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              )),
          ]),
        )),
      );
}
