class HelpLocation {
  const HelpLocation({
    required this.lat,
    required this.lng,
    this.address,
  });

  final double lat;
  final double lng;
  final String? address;

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lng': lng,
        if (address != null) 'address': address,
      };

  factory HelpLocation.fromJson(Map<String, dynamic> json) {
    return HelpLocation(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      address: json['address'] as String?,
    );
  }
}
