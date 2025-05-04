
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:campus_dash/core/themes/app_theme.dart';
import 'package:campus_dash/features/auth/providers/auth_provider.dart';
import 'package:lottie/lottie.dart';

class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  ConsumerState<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  String? _selectedRole;

  void _selectRole(String role) {
    setState(() {
      _selectedRole = role;
    });
  }

  void _continueWithRole() async {
    if (_selectedRole != null) {
      // Save role selection
      await ref.read(authProvider.notifier).setUserRole(_selectedRole!);
      
      // Navigate to registration screen
      if (mounted) {
        context.go('/register');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              const Text(
                'What would you like to do on Dash?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Choose your primary role to get started.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 48),
              
              // Rider Role Card
              _RoleCard(
                title: 'I want to Ride',
                description: 'Request rides from student drivers around campus',
                animation: 'assets/animations/rider.json',
                isSelected: _selectedRole == 'rider',
                onTap: () => _selectRole('rider'),
              ),
              
              const SizedBox(height: 24),
              
              // Driver Role Card
              _RoleCard(
                title: 'I want to Drive',
                description: 'Earn money by offering rides to fellow students',
                animation: 'assets/animations/driver.json',
                isSelected: _selectedRole == 'driver',
                onTap: () => _selectRole('driver'),
              ),
              
              const Spacer(),
              
              // Continue Button
              SizedBox(
                width: size.width,
                height: 56,
                child: ElevatedButton(
                  onPressed: _selectedRole != null ? _continueWithRole : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    disabledBackgroundColor: Colors.grey.shade300,
                    disabledForegroundColor: Colors.grey.shade600,
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Already have account button
              Center(
                child: TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Already have an account? Sign in'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String description;
  final String animation;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.description,
    required this.animation,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected ? primaryColor.withOpacity(0.05) : Colors.white,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? primaryColor : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 80,
              height: 80,
              child: Lottie.asset(
                animation,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
