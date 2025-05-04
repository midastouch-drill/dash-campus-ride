
class DriverEarnings {
  final double totalEarnings;
  final int totalTrips;
  final int completedTrips;
  final int cancelledTrips;
  final double averageRating;
  final String period;
  
  DriverEarnings({
    required this.totalEarnings,
    required this.totalTrips,
    required this.completedTrips,
    required this.cancelledTrips,
    required this.averageRating,
    required this.period,
  });
  
  factory DriverEarnings.fromJson(Map<String, dynamic> json) {
    return DriverEarnings(
      totalEarnings: (json['totalEarnings'] is int)
          ? (json['totalEarnings'] as int).toDouble()
          : json['totalEarnings'],
      totalTrips: json['totalTrips'],
      completedTrips: json['completedTrips'],
      cancelledTrips: json['cancelledTrips'],
      averageRating: (json['averageRating'] is int)
          ? (json['averageRating'] as int).toDouble()
          : json['averageRating'],
      period: json['period'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'totalEarnings': totalEarnings,
      'totalTrips': totalTrips,
      'completedTrips': completedTrips,
      'cancelledTrips': cancelledTrips,
      'averageRating': averageRating,
      'period': period,
    };
  }
}
