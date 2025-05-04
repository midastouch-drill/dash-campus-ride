
import 'package:flutter/material.dart';
import 'package:campus_dash/core/themes/app_theme.dart';
import 'package:campus_dash/features/history/models/ride_model.dart';
import 'package:intl/intl.dart';

class RideHistoryItem extends StatelessWidget {
  final Ride ride;

  const RideHistoryItem({
    super.key,
    required this.ride,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status and Date Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusBadge(ride.status),
                Text(
                  DateFormat('MMM d, h:mm a').format(ride.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Pickup and Dropoff Locations
            Row(
              children: [
                Column(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 12,
                      color: Colors.green.shade700,
                    ),
                    Container(
                      width: 1,
                      height: 25,
                      color: Colors.grey.shade300,
                    ),
                    Icon(
                      Icons.place,
                      size: 12,
                      color: Colors.red.shade700,
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ride.pickupLocationName,
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        ride.dropoffLocationName,
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Divider
            const Divider(),
            
            // Price and Details Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '₦${ride.fare.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '${ride.distance.toStringAsFixed(1)} km',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '•',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${ride.duration} min',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            // Show rating if available
            if (ride.rating != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.star,
                      size: 16,
                      color: Colors.amber.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      ride.rating!.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade800,
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

  Widget _buildStatusBadge(RideStatus status) {
    Color color;
    String text;

    switch (status) {
      case RideStatus.pending:
        color = Colors.blue;
        text = 'Pending';
        break;
      case RideStatus.accepted:
        color = Colors.orange;
        text = 'Accepted';
        break;
      case RideStatus.ongoing:
        color = primaryColor;
        text = 'Ongoing';
        break;
      case RideStatus.completed:
        color = Colors.green;
        text = 'Completed';
        break;
      case RideStatus.cancelled:
        color = Colors.red;
        text = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
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
