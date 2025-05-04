
import 'package:flutter/material.dart';
import 'package:campus_dash/features/history/models/ride_model.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

class DriverRideHistorySection extends StatelessWidget {
  final List<Ride> rides;
  final VoidCallback onViewAll;

  const DriverRideHistorySection({
    super.key,
    required this.rides,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: rides.map((ride) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: _buildRideItem(context, ride),
        );
      }).toList(),
    );
  }

  Widget _buildRideItem(BuildContext context, Ride ride) {
    return Card(
      elevation: 1,
      child: InkWell(
        onTap: () {
          context.go('/ride/${ride.id}');
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('MMM d, h:mm a').format(ride.createdAt),
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  Text(
                    '₦${ride.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Icon(
                        Icons.trip_origin,
                        size: 16,
                        color: Colors.green.shade700,
                      ),
                      SizedBox(
                        height: 20,
                        child: VerticalDivider(
                          color: Colors.grey.shade400,
                          thickness: 1,
                          width: 20,
                        ),
                      ),
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.red.shade700,
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ride.pickupLocation.name,
                          style: const TextStyle(fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          ride.dropoffLocation.name,
                          style: const TextStyle(fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  // Distance
                  Row(
                    children: [
                      Icon(
                        Icons.directions_car_outlined,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${ride.distance.toStringAsFixed(1)} km',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  // Duration
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${ride.duration} min',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // View details
                  Row(
                    children: [
                      Text(
                        'Details',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
