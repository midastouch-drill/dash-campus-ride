
import 'package:flutter/material.dart';
import 'package:campus_dash/features/ride/models/ride_request_model.dart';
import 'package:intl/intl.dart';

class DriverRideRequestCard extends StatelessWidget {
  final RideRequest request;
  final VoidCallback onAccept;
  
  const DriverRideRequestCard({
    super.key,
    required this.request,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
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
                Text(
                  '₦${request.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                Text(
                  DateFormat('MMM d, h:mm a').format(request.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Pickup location
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.trip_origin, size: 16, color: Colors.green.shade800),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pickup',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        request.pickupLocation.name,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Dotted line
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: SizedBox(
                height: 20,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    3,
                    (index) => Container(
                      width: 2,
                      height: 2,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ),
              ),
            ),
            
            // Dropoff location
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.place, size: 16, color: Colors.red.shade800),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dropoff',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        request.dropoffLocation.name,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Trip details
            Row(
              children: [
                Icon(
                  Icons.directions_car_outlined,
                  size: 16,
                  color: Colors.grey.shade700,
                ),
                const SizedBox(width: 4),
                Text(
                  '${request.distance.toStringAsFixed(1)} km',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.grey.shade700,
                ),
                const SizedBox(width: 4),
                Text(
                  '${request.duration} min',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  request.paymentMethod == 'cash' ? Icons.payments_outlined : Icons.credit_card,
                  size: 16,
                  color: Colors.grey.shade700,
                ),
                const SizedBox(width: 4),
                Text(
                  request.paymentMethod.toUpperCase(),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Accept button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onAccept,
                child: const Text('ACCEPT RIDE'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
