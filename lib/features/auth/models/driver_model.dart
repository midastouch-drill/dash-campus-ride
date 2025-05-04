
import 'package:campus_dash/features/auth/models/user_model.dart';

class Driver extends User {
  final String vehicleType;
  final String vehicleMake;
  final String vehicleModel;
  final String vehicleColor;
  final String licensePlate;
  final String driversLicense;
  final String driversLicenseExpiry;
  final String vehicleInsurance;
  final String vehicleRegistration;
  final bool isAvailable;
  final List<double>? currentLocation;
  
  Driver({
    required super.id,
    required super.firstName,
    required super.lastName,
    required super.email,
    required super.phone,
    required super.role,
    required super.isVerified,
    super.wallet,
    super.profilePicture,
    required this.vehicleType,
    required this.vehicleMake,
    required this.vehicleModel,
    required this.vehicleColor,
    required this.licensePlate,
    required this.driversLicense,
    required this.driversLicenseExpiry,
    required this.vehicleInsurance,
    required this.vehicleRegistration,
    this.isAvailable = false,
    this.currentLocation,
  });
  
  factory Driver.fromJson(Map<String, dynamic> json) {
    final user = User.fromJson(json);
    
    return Driver(
      id: user.id,
      firstName: user.firstName,
      lastName: user.lastName,
      email: user.email,
      phone: user.phone,
      role: user.role,
      isVerified: user.isVerified,
      wallet: user.wallet,
      profilePicture: user.profilePicture,
      vehicleType: json['vehicleType'] ?? '',
      vehicleMake: json['vehicleMake'] ?? '',
      vehicleModel: json['vehicleModel'] ?? '',
      vehicleColor: json['vehicleColor'] ?? '',
      licensePlate: json['licensePlate'] ?? '',
      driversLicense: json['driversLicense'] ?? '',
      driversLicenseExpiry: json['driversLicenseExpiry'] ?? '',
      vehicleInsurance: json['vehicleInsurance'] ?? '',
      vehicleRegistration: json['vehicleRegistration'] ?? '',
      isAvailable: json['isAvailable'] ?? false,
      currentLocation: json['currentLocation'] != null
          ? List<double>.from(json['currentLocation'])
          : null,
    );
  }
  
  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = super.toJson();
    data.addAll({
      'vehicleType': vehicleType,
      'vehicleMake': vehicleMake,
      'vehicleModel': vehicleModel,
      'vehicleColor': vehicleColor,
      'licensePlate': licensePlate,
      'driversLicense': driversLicense,
      'driversLicenseExpiry': driversLicenseExpiry,
      'vehicleInsurance': vehicleInsurance,
      'vehicleRegistration': vehicleRegistration,
      'isAvailable': isAvailable,
      'currentLocation': currentLocation,
    });
    return data;
  }
  
  Driver copyWith({
    String? vehicleType,
    String? vehicleMake,
    String? vehicleModel,
    String? vehicleColor,
    String? licensePlate,
    bool? isAvailable,
    List<double>? currentLocation,
    String? driversLicense,
    String? driversLicenseExpiry,
    String? vehicleInsurance,
    String? vehicleRegistration,
  }) {
    return Driver(
      id: id,
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      role: role,
      isVerified: isVerified,
      wallet: wallet,
      profilePicture: profilePicture,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleMake: vehicleMake ?? this.vehicleMake,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehicleColor: vehicleColor ?? this.vehicleColor,
      licensePlate: licensePlate ?? this.licensePlate,
      driversLicense: driversLicense ?? this.driversLicense,
      driversLicenseExpiry: driversLicenseExpiry ?? this.driversLicenseExpiry,
      vehicleInsurance: vehicleInsurance ?? this.vehicleInsurance,
      vehicleRegistration: vehicleRegistration ?? this.vehicleRegistration,
      isAvailable: isAvailable ?? this.isAvailable,
      currentLocation: currentLocation ?? this.currentLocation,
    );
  }
}
