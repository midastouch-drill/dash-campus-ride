
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:campus_dash/core/themes/app_theme.dart';
import 'package:campus_dash/features/auth/providers/auth_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    const OnboardingPage(
      title: 'Move Smarter on Campus',
      description: 'Quick, affordable rides tailored for university students. Skip the long walks and bus waits.',
      animationAsset: 'assets/animations/campus_ride.json',
    ),
    const OnboardingPage(
      title: 'Ride or Earn — You Decide',
      description: 'Need a ride? Request one in seconds. Want to earn? Switch to driver mode.',
      animationAsset: 'assets/animations/ride_sharing.json',
    ),
    const OnboardingPage(
      title: 'Safe, Verified, Student-Only',
      description: 'Every driver and rider is verified with student ID. Your safety is our priority.',
      animationAsset: 'assets/animations/secure_ride.json',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToRoleSelection() {
    // Mark onboarding as complete
    ref.read(authProvider.notifier).completeOnboarding();
    
    // Navigate to role selection
    context.go('/role-selection');
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _pages[index];
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: _pages.length,
                    effect: ExpandingDotsEffect(
                      activeDotColor: primaryColor,
                      dotColor: Colors.grey.shade300,
                      dotHeight: 8,
                      dotWidth: 8,
                      expansionFactor: 3,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: size.width,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage == _pages.length - 1) {
                          _goToRoleSelection();
                        } else {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeIn,
                          );
                        }
                      },
                      child: Text(
                        _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                      ),
                    ),
                  ),
                  if (_currentPage < _pages.length - 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: TextButton(
                        onPressed: _goToRoleSelection,
                        child: const Text('Skip'),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingPage extends StatelessWidget {
  final String title;
  final String description;
  final String animationAsset;

  const OnboardingPage({
    super.key,
    required this.title,
    required this.description,
    required this.animationAsset,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 250,
            child: Lottie.asset(
              animationAsset,
              fit: BoxFit.contain,
              repeat: true,
            ),
          ),
          const SizedBox(height: 48),
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
