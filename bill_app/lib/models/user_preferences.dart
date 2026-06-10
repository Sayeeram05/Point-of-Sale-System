class UserEmoji {
  final int? id;
  final String emojiText;

  UserEmoji({this.id, required this.emojiText});

  factory UserEmoji.fromJson(Map<String, dynamic> json) {
    return UserEmoji(id: json['id'], emojiText: json['emoji_text'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'emoji_text': emojiText};
  }
}

class UserColor {
  final int? id;
  final String color;

  UserColor({this.id, required this.color});

  factory UserColor.fromJson(Map<String, dynamic> json) {
    return UserColor(id: json['id'], color: json['color'] ?? '#2196F3');
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'color': color};
  }
}
