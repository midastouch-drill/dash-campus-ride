
import 'package:campus_dash/features/history/models/ride_model.dart';
import 'package:campus_dash/features/ride/models/location_model.dart';

class ActiveRide {
  final String id;
  final String pickupLocationName;
  final String dropoffLocationName;
  final List<double> pickupCoordinates;
  final List<double> dropoffCoordinates;
  final double distance;
  final int duration;
  final double fare;
  final String paymentMethod;
  final RideStatus status;
  final DateTime createdAt;
  final DriverInfo? driver;
  final double? rating;
  final String? review;
  final String riderName; // Added riderName field

  ActiveRide({
    required this.id,
    required this.pickupLocationName,
    required this.dropoffLocationName,
    required this.pickupCoordinates,
    required this.dropoffCoordinates,
    required this.distance,
    required this.duration,
    required this.fare,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
    this.driver,
    this.rating,
    this.review,
    required this.riderName, // Added riderName parameter
  });

  // Add getter for pickupLocation
  LocationInfo get pickupLocation {
    return LocationInfo(
      name: pickupLocationName,
      coordinates: [pickupCoordinates[0], pickupCoordinates[1]],
    );
  }

  // Add getter for dropoffLocation
  LocationInfo get dropoffLocation {
    return LocationInfo(
      name: dropoffLocationName,
      coordinates: [dropoffCoordinates[0], dropoffCoordinates[1]],
    );
  }

  factory ActiveRide.fromJson(Map<String, dynamic> json) {
    return ActiveRide(
      id: json['id'],
      pickupLocationName: json['pickupLocation']['name'],
      dropoffLocationName: json['dropoffLocation']['name'],
      pickupCoordinates: List<double>.from(json['pickupLocation']['coordinates'].map((x) => x.toDouble())),
      dropoffCoordinates: List<double>.from(json['dropoffLocation']['coordinates'].map((x) => x.toDouble())),
      distance: json['distance'].toDouble(),
      duration: json['duration'],
      fare: json['fare'].toDouble(),
      paymentMethod: json['paymentMethod'],
      status: _parseStatus(json['status']),
      createdAt: DateTime.parse(json['createdAt']),
      driver: json['driver'] != null ? DriverInfo.fromJson(json['driver']) : null,
      rating: json['rating']?.toDouble(),
      review: json['review'],
      riderName: json['riderName'] ?? 'Passenger', // Extract riderName with fallback
    );
  }

  static RideStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return RideStatus.pending;
      case 'accepted':
        return RideStatus.accepted;
      case 'ongoing':
        return RideStatus.ongoing;
      case 'completed':
        return RideStatus.completed;
      case 'cancelled':
        return RideStatus.cancelled;
      default:
        return RideStatus.pending;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pickupLocation': {
        'name': pickupLocationName,
        'coordinates': pickupCoordinates,
      },
      'dropoffLocation': {
        'name': dropoffLocationName,
        'coordinates': dropoffCoordinates,
      },
      'distance': distance,
      'duration': duration,
      'fare': fare,
      'paymentMethod': paymentMethod,
      'status': status.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'driver': driver?.toJson(),
      'rating': rating,
      'review': review,
      'riderName': riderName, // Added riderName to JSON output
    };
  }

  ActiveRide copyWith({
    String? id,
    String? pickupLocationName,
    String? dropoffLocationName,
    List<double>? pickupCoordinates,
    List<double>? dropoffCoordinates,
    double? distance,
    int? duration,
    double? fare,
    String? paymentMethod,
    RideStatus? status,
    DateTime? createdAt,
    DriverInfo? driver,
    double? rating,
    String? review,
    String? riderName, // Added riderName parameter
  }) {
    return ActiveRide(
      id: id ?? this.id,
      pickupLocationName: pickupLocationName ?? this.pickupLocationName,
      dropoffLocationName: dropoffLocationName ?? this.dropoffLocationName,
      pickupCoordinates: pickupCoordinates ?? this.pickupCoordinates,
      dropoffCoordinates: dropoffCoordinates ?? this.dropoffCoordinates,
      distance: distance ?? this.distance,
      duration: duration ?? this.duration,
      fare: fare ?? this.fare,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      driver: driver ?? this.driver,
      rating: rating ?? this.rating,
      review: review ?? this.review,
      riderName: riderName ?? this.riderName, // Use riderName in copyWith
    );
  }
}
