class RedemptionRequest {
  final String userId;
  final double points;
  final String method; // 'cash', 'bank_transfer', 'voucher', etc.
  final Map<String, dynamic>? additionalData;

  RedemptionRequest({
    required this.userId,
    required this.points,
    required this.method,
    this.additionalData,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'points': points,
      'method': method,
      if (additionalData != null) 'additionalData': additionalData,
    };
  }
}

class RedemptionOption {
  final String id;
  final String name;
  final String description;
  final double minimumPoints;
  final String icon;
  final bool isAvailable;

  RedemptionOption({
    required this.id,
    required this.name,
    required this.description,
    required this.minimumPoints,
    required this.icon,
    this.isAvailable = true,
  });

  factory RedemptionOption.fromJson(Map<String, dynamic> json) {
    return RedemptionOption(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      minimumPoints: (json['minimumPoints'] ?? 0).toDouble(),
      icon: json['icon'] ?? '💰',
      isAvailable: json['isAvailable'] ?? true,
    );
  }
}
