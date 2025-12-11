class Community {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final int memberCount;
  final bool isJoined;
  final List<String> tags;

  Community({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.memberCount,
    required this.isJoined,
    required this.tags,
  });
}
