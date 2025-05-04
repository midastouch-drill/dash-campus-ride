
import 'package:flutter/material.dart';
import 'package:campus_dash/features/history/models/ride_model.dart';
import 'package:campus_dash/features/history/widgets/ride_history_item.dart';

class RecentRidesSection extends StatelessWidget {
  final List<Ride> rides;
  final VoidCallback onViewAll;

  const RecentRidesSection({
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
          child: RideHistoryItem(ride: ride),
        );
      }).toList(),
    );
  }
}
