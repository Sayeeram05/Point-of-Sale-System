class UserEmoji {
  final int? id;
  final String emojiText;

  UserEmoji({this.id, required this.emojiText});

  factory UserEmoji.fromJson(Map<String, dynamic> json) {
    return UserEmoji(
      id: json['id'] ?? json['ID'],
      emojiText: json['emoji_text'] ?? json['Emoji'] ?? json['emoji'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'Emoji': emojiText, 'emoji_text': emojiText};
  }
}

class UserColor {
  final int? id;
  final String color;

  UserColor({this.id, required this.color});

  factory UserColor.fromJson(Map<String, dynamic> json) {
    return UserColor(
      id: json['id'] ?? json['ID'],
      color: json['color'] ?? json['HexCode'] ?? '#2196F3',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'HexCode': color, 'color': color};
  }
}
