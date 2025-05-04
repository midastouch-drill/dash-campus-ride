
enum RideStatus {
  pending,
  accepted,
  ongoing,
  completed,
  cancelled
}

class Ride {
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
  final String? driverId;
  final DriverInfo? driver;
  final double? rating;
  final String? review;

  Ride({
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
    this.driverId,
    this.driver,
    this.rating,
    this.review,
  });

  factory Ride.fromJson(Map<String, dynamic> json) {
    return Ride(
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
      driverId: json['driverId'],
      driver: json['driver'] != null ? DriverInfo.fromJson(json['driver']) : null,
      rating: json['rating']?.toDouble(),
      review: json['review'],
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
      'driverId': driverId,
      'driver': driver?.toJson(),
      'rating': rating,
      'review': review,
    };
  }
}

class DriverInfo {
  final String id;
  final String firstName;
  final String lastName;
  final String? profilePicture;
  final String phone;
  final VehicleInfo vehicle;

  DriverInfo({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.profilePicture,
    required this.phone,
    required this.vehicle,
  });

  String get fullName => '$firstName $lastName';

  factory DriverInfo.fromJson(Map<String, dynamic> json) {
    return DriverInfo(
      id: json['id'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      profilePicture: json['profilePicture'],
      phone: json['phone'],
      vehicle: VehicleInfo.fromJson(json['vehicle']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'profilePicture': profilePicture,
      'phone': phone,
      'vehicle': vehicle.toJson(),
    };
  }
}

class VehicleInfo {
  final String type;
  final String make;
  final String model;
  final String color;
  final String licensePlate;

  VehicleInfo({
    required this.type,
    required this.make,
    required this.model,
    required this.color,
    required this.licensePlate,
  });

  factory VehicleInfo.fromJson(Map<String, dynamic> json) {
    return VehicleInfo(
      type: json['type'],
      make: json['make'],
      model: json['model'],
      color: json['color'],
      licensePlate: json['licensePlate'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'make': make,
      'model': model,
      'color': color,
      'licensePlate': licensePlate,
    };
  }
}
