
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:campus_dash/features/auth/providers/auth_provider.dart';
import 'package:campus_dash/features/onboarding/screens/splash_screen.dart';
import 'package:campus_dash/features/onboarding/screens/onboarding_screen.dart';
import 'package:campus_dash/features/onboarding/screens/role_selection_screen.dart';
import 'package:campus_dash/features/auth/screens/login_screen.dart';
import 'package:campus_dash/features/auth/screens/register_screen.dart';
import 'package:campus_dash/features/auth/screens/driver_register_screen.dart';
import 'package:campus_dash/features/dashboard/screens/rider_dashboard_screen.dart';
import 'package:campus_dash/features/dashboard/screens/driver_dashboard_screen.dart';
import 'package:campus_dash/features/dashboard/screens/driver_earnings_screen.dart';
import 'package:campus_dash/features/ride/screens/request_ride_screen.dart';
import 'package:campus_dash/features/ride/screens/ride_tracking_screen.dart';
import 'package:campus_dash/features/ride/screens/driver_ride_tracking_screen.dart';
import 'package:campus_dash/features/wallet/screens/wallet_screen.dart';
import 'package:campus_dash/features/history/screens/ride_history_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoggedIn = authState.isLoggedIn;
      final isOnboardingComplete = authState.isOnboardingComplete;
      final isInitializing = authState.isInitializing;
      final isDriver = authState.user?.role == 'driver';
      
      // Don't redirect if still initializing auth state
      if (isInitializing) return null;
      
      // Check if the user is on a public route
      final isGoingToLogin = state.location == '/login';
      final isGoingToRegister = state.location == '/register';
      final isGoingToDriverRegister = state.location == '/register-driver';
      final isGoingToOnboarding = state.location == '/onboarding';
      final isGoingToRoleSelection = state.location == '/role-selection';
      final isGoingToSplash = state.location == '/';
      
      // If the user is already logged in but tries to access login or register, redirect them to home
      if (isLoggedIn && (isGoingToLogin || isGoingToRegister || isGoingToDriverRegister || isGoingToOnboarding || isGoingToRoleSelection || isGoingToSplash)) {
        return isDriver ? '/driver/dashboard' : '/dashboard';
      }
      
      // If the user is not logged in
      if (!isLoggedIn) {
        // Allow the splash screen
        if (isGoingToSplash) return null;
        
        // If onboarding is not complete, redirect to onboarding
        if (!isOnboardingComplete && !isGoingToOnboarding && !isGoingToRoleSelection) {
          return '/onboarding';
        }
        
        // If trying to access private routes, redirect to login
        if (!isGoingToLogin && !isGoingToRegister && !isGoingToDriverRegister && !isGoingToOnboarding && !isGoingToRoleSelection) {
          return '/login';
        }
      }
      
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/role-selection',
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/register-driver',
        builder: (context, state) => const DriverRegisterScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const RiderDashboardScreen(),
      ),
      GoRoute(
        path: '/driver/dashboard',
        builder: (context, state) => const DriverDashboardScreen(),
      ),
      GoRoute(
        path: '/driver/earnings',
        builder: (context, state) => const DriverEarningsScreen(),
      ),
      GoRoute(
        path: '/request-ride',
        builder: (context, state) => const RequestRideScreen(),
      ),
      GoRoute(
        path: '/ride/:id',
        builder: (context, state) {
          final rideId = state.params['id']!;
          final isDriver = ref.read(authProvider).user?.role == 'driver';
          return isDriver 
              ? DriverRideTrackingScreen(rideId: rideId)
              : RideTrackingScreen(rideId: rideId);
        },
      ),
      GoRoute(
        path: '/wallet',
        builder: (context, state) => const WalletScreen(),
      ),
      GoRoute(
        path: '/ride-history',
        builder: (context, state) => const RideHistoryScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Route not found: ${state.location}'),
      ),
    ),
  );
});
