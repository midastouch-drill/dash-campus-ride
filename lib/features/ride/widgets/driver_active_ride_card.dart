
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_dash/features/ride/models/active_ride_model.dart';
import 'package:campus_dash/features/ride/providers/driver_ride_provider.dart';

class DriverActiveRideCard extends ConsumerWidget {
  final ActiveRide ride;
  final VoidCallback onViewDetails;
  
  const DriverActiveRideCard({
    super.key,
    required this.ride,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canStart = ride.status == 'accepted';
    final canComplete = ride.status == 'started';
    
    return Card(
      elevation: 3,
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.directions_car_filled,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Active Ride',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildStatusBadge(ride.status),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: onViewDetails,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Rider information
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                child: const Icon(Icons.person),
              ),
              title: Text(ride.riderName),
              subtitle: const Text('Passenger'),
            ),
            
            // Ride details
            _buildInfoRow('Pickup', ride.pickupLocation.name),
            const SizedBox(height: 8),
            _buildInfoRow('Dropoff', ride.dropoffLocation.name),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildInfoRow('Distance', '${ride.distance.toStringAsFixed(1)} km'),
                ),
                Expanded(
                  child: _buildInfoRow('Fare', '₦${ride.amount.toStringAsFixed(2)}'),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Action buttons
            if (canStart)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(driverRideProvider.notifier).startRide(ride.id);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('START RIDE'),
                ),
              )
            else if (canComplete)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(driverRideProvider.notifier).completeRide(ride.id);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('COMPLETE RIDE'),
                ),
              )
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatusBadge(String status) {
    Color color;
    String text;
    
    switch (status) {
      case 'pending':
        color = Colors.orange;
        text = 'Pending';
        break;
      case 'accepted':
        color = Colors.blue;
        text = 'Accepted';
        break;
      case 'started':
        color = Colors.green;
        text = 'In Progress';
        break;
      case 'completed':
        color = Colors.purple;
        text = 'Completed';
        break;
      case 'cancelled':
        color = Colors.red;
        text = 'Cancelled';
        break;
      default:
        color = Colors.grey;
        text = status.toUpperCase();
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
