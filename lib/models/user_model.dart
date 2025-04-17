class User {
  final String        email;
  final String     fullName;
  final String     password;
  final String   profilePic;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    required this.email,
    required this.fullName,
    required this.password,
    this.profilePic = "",
    this.createdAt,
    this.updatedAt,
  });

  // Factory constructor to create a User instance from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      email:      json['email']    as String,
      fullName:   json['fullName'] as String,
      password:   json['password'] as String,
      profilePic: json['profilePic'] ?? "",
      createdAt:  json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:  json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  // Method to convert a User instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'fullName': fullName,
      'password': password,
      'profilePic': profilePic,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
