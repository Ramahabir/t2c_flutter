class User {
  final String id;
  final String? name;
  final String? email;
  final double points;
  final String? sessionToken;
  final DateTime? lastLogin;

  User({
    required this.id,
    this.name,
    this.email,
    required this.points,
    this.sessionToken,
    this.lastLogin,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['userId'] ?? '',
      name: json['name'],
      email: json['email'],
      points: (json['points'] ?? 0).toDouble(),
      sessionToken: json['sessionToken'],
      lastLogin: json['lastLogin'] != null
          ? DateTime.parse(json['lastLogin'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'points': points,
      'sessionToken': sessionToken,
      'lastLogin': lastLogin?.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    double? points,
    String? sessionToken,
    DateTime? lastLogin,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      points: points ?? this.points,
      sessionToken: sessionToken ?? this.sessionToken,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}
