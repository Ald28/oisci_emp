class UserModel {
  final int userId;
  final String name;
  final String accessToken;
  final String refreshToken;
  final String role;
  final String email;

  UserModel({
    required this.userId,
    required this.name,
    required this.accessToken,
    required this.refreshToken,
    required this.role,
    required this.email,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json["user"]["id"],
      name: json["user"]["name"],
      email: json["user"]["email"],
      role: json["user"]["role"],
      accessToken: json["accessToken"],
      refreshToken: json["refreshToken"],
    );
  }
}