class AvatarStats {
  final int hp;
  final int attack;
  final int defense;
  final int speed;

  AvatarStats({required this.hp, required this.attack, required this.defense, required this.speed});

  factory AvatarStats.fromJson(Map<String, dynamic> json) => AvatarStats(
        hp: json['hp'] as int? ?? 0,
        attack: json['attack'] as int? ?? 0,
        defense: json['defense'] as int? ?? 0,
        speed: json['speed'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {'hp': hp, 'attack': attack, 'defense': defense, 'speed': speed};
}

class Avatar {
  final String avatarId;
  final String userId;
  final String name;
  final int totalPoints;
  final int level;
  final int evolutionStage;
  final String? currentSpeciesId;
  final AvatarStats stats;
  final List<String> skillIds;

  Avatar({
    required this.avatarId,
    required this.userId,
    required this.name,
    required this.totalPoints,
    required this.level,
    required this.evolutionStage,
    this.currentSpeciesId,
    required this.stats,
    required this.skillIds,
  });

  factory Avatar.fromJson(Map<String, dynamic> json) => Avatar(
        avatarId: json['avatarId'] as String,
        userId: json['userId'] as String,
        name: json['name'] as String? ?? '',
        totalPoints: json['totalPoints'] as int? ?? 0,
        level: json['level'] as int? ?? 1,
        evolutionStage: json['evolutionStage'] as int? ?? 1,
        currentSpeciesId: json['currentSpeciesId'] as String?,
        stats: AvatarStats.fromJson(json['stats'] as Map<String, dynamic>? ?? {}),
        skillIds: (json['skillIds'] as List<dynamic>?)?.cast<String>() ?? [],
      );

  Map<String, dynamic> toJson() => {
        'avatarId': avatarId,
        'userId': userId,
        'name': name,
        'totalPoints': totalPoints,
        'level': level,
        'evolutionStage': evolutionStage,
        'currentSpeciesId': currentSpeciesId,
        'stats': stats.toJson(),
        'skillIds': skillIds,
      };
}
