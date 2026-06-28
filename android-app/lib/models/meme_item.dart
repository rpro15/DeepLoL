class MemeItem {
  final String imageUrl;
  String caption;
  String captionBottom;
  bool isDialogue;
  int laughs;
  DateTime createdAt;

  MemeItem({
    required this.imageUrl,
    this.caption = '',
    this.captionBottom = '',
    this.isDialogue = false,
    this.laughs = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}
