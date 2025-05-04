
import 'package:campus_dash/features/ride/models/location_model.dart';

class RideRequest {
  final String id;
  final String riderId;
  final String riderName;
  final LocationInfo pickupLocation;
  final LocationInfo dropoffLocation;
  final double distance;
  final int duration; // in minutes
  final double amount;
  final String status;
  final String paymentMethod;
  final DateTime createdAt;
  
  RideRequest({
    required this.id,
    required this.riderId,
    required this.riderName,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.distance,
    required this.duration,
    required this.amount,
    required this.status,
    required this.paymentMethod,
    required this.createdAt,
  });
  
  factory RideRequest.fromJson(Map<String, dynamic> json) {
    return RideRequest(
      id: json['id'],
      riderId: json['riderId'],
      riderName: json['riderName'] ?? 'Rider',
      pickupLocation: LocationInfo.fromJson(json['pickupLocation']),
      dropoffLocation: LocationInfo.fromJson(json['dropoffLocation']),
      distance: (json['distance'] is int)
          ? (json['distance'] as int).toDouble()
          : json['distance'],
      duration: json['duration'],
      amount: (json['amount'] is int)
          ? (json['amount'] as int).toDouble()
          : json['amount'],
      status: json['status'],
      paymentMethod: json['paymentMethod'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'riderId': riderId,
      'riderName': riderName,
      'pickupLocation': pickupLocation.toJson(),
      'dropoffLocation': dropoffLocation.toJson(),
      'distance': distance,
      'duration': duration,
      'amount': amount,
      'status': status,
      'paymentMethod': paymentMethod,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
