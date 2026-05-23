class UserProfile {
  final String userId;
  final String? nickname;
  final String email;
  final String authProvider;
  final String createdAt;

  UserProfile({
    required this.userId,
    this.nickname,
    required this.email,
    required this.authProvider,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        userId: json['userId'] as String,
        nickname: json['nickname'] as String?,
        email: json['email'] as String? ?? '',
        authProvider: json['authProvider'] as String? ?? 'EMAIL',
        createdAt: json['createdAt'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'nickname': nickname,
        'email': email,
        'authProvider': authProvider,
        'createdAt': createdAt,
      };

  bool get hasNickname => nickname != null && nickname!.isNotEmpty;
}
