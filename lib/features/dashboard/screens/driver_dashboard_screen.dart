
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:campus_dash/features/auth/providers/auth_provider.dart';
import 'package:campus_dash/features/auth/providers/driver_provider.dart';
import 'package:campus_dash/features/dashboard/widgets/wallet_card.dart';
import 'package:campus_dash/features/dashboard/providers/dashboard_provider.dart';
import 'package:campus_dash/features/wallet/providers/wallet_provider.dart';
import 'package:campus_dash/features/ride/providers/driver_ride_provider.dart';
import 'package:campus_dash/shared/widgets/shimmer_loading.dart';
import 'package:campus_dash/features/ride/widgets/driver_ride_request_card.dart';
import 'package:campus_dash/features/ride/widgets/driver_active_ride_card.dart';
import 'package:campus_dash/features/dashboard/widgets/driver_ride_history_section.dart';

class DriverDashboardScreen extends ConsumerStatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  ConsumerState<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends ConsumerState<DriverDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Initial data loading
    Future.microtask(() {
      ref.read(driverProvider.notifier).refreshDriverProfile();
      ref.read(walletProvider.notifier).fetchWalletBalance();
      ref.read(driverRideProvider.notifier).fetchDriverRides();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final driverState = ref.watch(driverProvider);
    final walletState = ref.watch(walletProvider);
    final rideState = ref.watch(driverRideProvider);

    final user = authState.user;
    final driver = driverState.driver;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              // Navigate to profile screen
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(driverProvider.notifier).refreshDriverProfile();
          await ref.read(walletProvider.notifier).fetchWalletBalance();
          await ref.read(driverRideProvider.notifier).fetchDriverRides();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting and Status Toggle
              _buildGreetingAndStatus(context, user?.firstName ?? '', driverState),
              
              const SizedBox(height: 20),
              
              // Wallet Card
              WalletCard(
                balance: user?.wallet?.balance ?? 0,
                isLoading: walletState.isLoadingBalance,
                onTap: () => context.go('/wallet'),
              ),
              
              const SizedBox(height: 20),
              
              // Today's Earnings
              _buildTodayEarnings(rideState),
              
              const SizedBox(height: 20),
              
              // Active Ride (if any)
              if (rideState.activeRide != null) ...[
                DriverActiveRideCard(
                  ride: rideState.activeRide!,
                  onViewDetails: () => context.go('/ride/${rideState.activeRide!.id}'),
                ),
                const SizedBox(height: 20),
              ],
              
              // Ride Requests (if available and driver is online)
              if (driverState.isAvailable && rideState.rideRequests.isNotEmpty) ...[
                _buildRideRequestsSection(rideState),
                const SizedBox(height: 20),
              ],
              
              // Recent Rides
              _buildRecentRides(context, rideState),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildGreetingAndStatus(BuildContext context, String firstName, DriverState driverState) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, $firstName',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      driverState.isAvailable ? 'You are online' : 'You are offline',
                      style: TextStyle(
                        color: driverState.isAvailable ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: driverState.isAvailable,
                  activeColor: Colors.green,
                  onChanged: driverState.isLoading
                      ? null
                      : (bool value) {
                          ref.read(driverProvider.notifier).updateAvailability(value);
                        },
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Toggle the switch to start receiving ride requests.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayEarnings(DriverRideState rideState) {
    final todayEarnings = rideState.todayEarnings;
    final ridesCompleted = rideState.todayCompletedRides;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Today\'s Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  '₦${todayEarnings.toStringAsFixed(2)}',
                  'Earnings',
                  Icons.wallet,
                ),
                _buildStatItem(
                  ridesCompleted.toString(),
                  'Rides',
                  Icons.directions_car,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 28, color: Theme.of(context).primaryColor),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
  
  Widget _buildRideRequestsSection(DriverRideState rideState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Ride Requests',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (rideState.isLoadingRequests)
              const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (rideState.rideRequests.isEmpty && !rideState.isLoadingRequests)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: Text(
                'No ride requests available',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: rideState.rideRequests.length,
            itemBuilder: (context, index) {
              final request = rideState.rideRequests[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: DriverRideRequestCard(
                  request: request,
                  onAccept: () => ref.read(driverRideProvider.notifier).acceptRide(request.id),
                ),
              );
            },
          ),
      ],
    );
  }
  
  Widget _buildRecentRides(BuildContext context, DriverRideState rideState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Rides',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => context.go('/ride-history'),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (rideState.isLoadingHistory)
          ShimmerLoading(
            child: Column(
              children: List.generate(
                3,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
          )
        else if (rideState.completedRides.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: Text(
                'No ride history yet',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          DriverRideHistorySection(
            rides: rideState.completedRides.take(3).toList(),
            onViewAll: () => context.go('/ride-history'),
          ),
      ],
    );
  }
}
