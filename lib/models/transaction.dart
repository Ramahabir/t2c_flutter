class Transaction {
  final String id;
  final String userId;
  final String type; // 'deposit', 'redemption'
  final double amount; // points or cash amount
  final String? itemType; // plastic, metal, glass, etc.
  final double? weight; // kg
  final String? stationId;
  final DateTime timestamp;
  final String status; // 'completed', 'pending', 'failed'
  final String? description;

  Transaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    this.itemType,
    this.weight,
    this.stationId,
    required this.timestamp,
    required this.status,
    this.description,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] ?? '',
      userId: json['userId'] ?? json['user_id'] ?? '',
      type: json['type'] ?? 'deposit',
      amount: (json['amount'] ?? 0).toDouble(),
      itemType: json['itemType'] ?? json['item_type'],
      weight: json['weight'] != null ? (json['weight'] as num).toDouble() : null,
      stationId: json['stationId'] ?? json['station_id'],
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      status: json['status'] ?? 'completed',
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'amount': amount,
      'itemType': itemType,
      'weight': weight,
      'stationId': stationId,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
      'description': description,
    };
  }

  bool get isDeposit => type == 'deposit';
  bool get isRedemption => type == 'redemption';
  bool get isCompleted => status == 'completed';
}
