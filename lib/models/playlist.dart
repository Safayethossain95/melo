class Playlist {
  final String id;
  String name;
  String description;
  List<String> trackIds;
  final DateTime createdAt;

  Playlist({
    required this.id,
    required this.name,
    this.description = '',
    required this.trackIds,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'trackIds': trackIds,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Playlist.fromMap(Map<String, dynamic> map) {
    return Playlist(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String? ?? '',
      trackIds: (map['trackIds'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
