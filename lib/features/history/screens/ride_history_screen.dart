
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_dash/features/history/providers/ride_history_provider.dart';
import 'package:campus_dash/features/history/widgets/ride_history_item.dart';
import 'package:campus_dash/shared/widgets/shimmer_loading.dart';

class RideHistoryScreen extends ConsumerStatefulWidget {
  const RideHistoryScreen({super.key});

  @override
  ConsumerState<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends ConsumerState<RideHistoryScreen> {
  final ScrollController _scrollController = ScrollController();
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    
    // Fetch ride history when screen loads
    Future.microtask(() {
      ref.read(rideHistoryProvider.notifier).fetchRideHistory();
    });
    
    // Add scroll listener for pagination
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final historyState = ref.read(rideHistoryProvider);
      
      if (!historyState.isLoading && historyState.hasMore) {
        ref.read(rideHistoryProvider.notifier).fetchRideHistory();
      }
    }
  }

  void _onStatusChanged(String status) {
    setState(() {
      _selectedStatus = status;
    });
    
    ref.read(rideHistoryProvider.notifier).fetchRideHistory(
      page: 1,
      status: status,
    );
  }

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(rideHistoryProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride History'),
      ),
      body: Column(
        children: [
          // Status filter chips
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  _buildFilterChip('all', 'All'),
                  const SizedBox(width: 8),
                  _buildFilterChip('completed', 'Completed'),
                  const SizedBox(width: 8),
                  _buildFilterChip('ongoing', 'Ongoing'),
                  const SizedBox(width: 8),
                  _buildFilterChip('cancelled', 'Cancelled'),
                ],
              ),
            ),
          ),
          
          // Divider
          const Divider(height: 1),
          
          // Ride history list
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(rideHistoryProvider.notifier).refreshRideHistory(),
              child: historyState.rides.isEmpty && !historyState.isLoading
                  ? _buildEmptyState()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: historyState.rides.length + (historyState.isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        // Show loading indicator at the bottom while paginating
                        if (index == historyState.rides.length) {
                          return const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final ride = historyState.rides[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: RideHistoryItem(ride: ride),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedStatus == value;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          _onStatusChanged(value);
        }
      },
      showCheckmark: false,
      backgroundColor: Colors.grey.shade100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No rides found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your ride history will appear here',
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
