
class LocationInfo {
  final String name;
  final List<double> coordinates;

  LocationInfo({
    required this.name,
    required this.coordinates,
  });

  factory LocationInfo.fromJson(Map<String, dynamic> json) {
    return LocationInfo(
      name: json['name'],
      coordinates: List<double>.from(json['coordinates'].map((x) => x.toDouble())),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'coordinates': coordinates,
    };
  }

  double get latitude => coordinates[0];
  double get longitude => coordinates[1];
}
