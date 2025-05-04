
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:campus_dash/core/themes/app_theme.dart';
import 'package:campus_dash/features/auth/providers/auth_provider.dart';
import 'package:campus_dash/features/dashboard/providers/dashboard_provider.dart';
import 'package:campus_dash/features/history/providers/ride_history_provider.dart';
import 'package:campus_dash/features/dashboard/widgets/wallet_card.dart';
import 'package:campus_dash/features/dashboard/widgets/recent_rides_section.dart';
import 'package:campus_dash/shared/widgets/shimmer_loading.dart';

class RiderDashboardScreen extends ConsumerStatefulWidget {
  const RiderDashboardScreen({super.key});

  @override
  ConsumerState<RiderDashboardScreen> createState() => _RiderDashboardScreenState();
}

class _RiderDashboardScreenState extends ConsumerState<RiderDashboardScreen> {
  bool _isRefreshing = false;

  Future<void> _refreshDashboard() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      await ref.read(dashboardProvider.notifier).refreshDashboard();
      await ref.read(rideHistoryProvider.notifier).fetchRecentRides(limit: 3);
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // Fetch dashboard data on screen load
    Future.microtask(() {
      ref.read(dashboardProvider.notifier).fetchDashboard();
      ref.read(rideHistoryProvider.notifier).fetchRecentRides(limit: 3);
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final dashboardState = ref.watch(dashboardProvider);
    final rideHistoryState = ref.watch(rideHistoryProvider);

    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // Navigate to notifications screen
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              // Navigate to profile screen
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshDashboard,
        color: primaryColor,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Greeting Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: primaryLightColor,
                      backgroundImage: user?.profilePicture != null
                          ? NetworkImage(user!.profilePicture!)
                          : null,
                      child: user?.profilePicture == null
                          ? Text(
                              user?.firstName.substring(0, 1) ?? '',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hi, ${user?.firstName ?? 'there'}!',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Where would you like to go today?',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Wallet Card
            if (dashboardState.isLoading)
              const ShimmerLoading(height: 120)
            else
              WalletCard(
                balance: user?.wallet?.balance ?? 0.0,
                onTap: () => context.push('/wallet'),
              ),

            const SizedBox(height: 24),

            // Request Ride Button
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => context.push('/request-ride'),
                icon: const Icon(Icons.directions_car),
                label: const Text('Request a Ride'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Tip Card - Rotating Carousel
            Card(
              color: Colors.amber.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: Colors.amber.shade700,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Pro Tip',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Schedule your rides in advance for popular campus events to ensure you get a ride!',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Recent Rides Section
            const Text(
              'Recent Rides',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            if (rideHistoryState.isLoading)
              Column(
                children: List.generate(
                  3,
                  (index) => const Padding(
                    padding: EdgeInsets.only(bottom: 8.0),
                    child: ShimmerLoading(height: 100),
                  ),
                ),
              )
            else if (rideHistoryState.rides.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.directions_car,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No rides yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              RecentRidesSection(
                rides: rideHistoryState.rides,
                onViewAll: () => context.push('/ride-history'),
              ),
            
            const SizedBox(height: 16),
            
            // View All Rides Button
            if (!rideHistoryState.isLoading && rideHistoryState.rides.isNotEmpty)
              TextButton(
                onPressed: () => context.push('/ride-history'),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('View All Rides'),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 16),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
