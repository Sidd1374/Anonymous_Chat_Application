class Message {
  final String    senderId;
  final String    receiverId;
  final String?   text;
  final String?   image;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Message({
    required this.senderId,
    required this.receiverId,
    this.text,
    this.image,
    this.createdAt,
    this.updatedAt,
  });

  // Factory constructor to create a Message instance from JSON
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      senderId:   json['senderId'] as String,
      receiverId: json['receiverId'] as String,
      text:       json['text'] as String?,
      image:      json['image'] as String?,
      createdAt:  json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:  json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  // Method to convert a Message instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'senderId':   senderId,
      'receiverId': receiverId,
      'text':       text,
      'image':      image,
      'createdAt':  createdAt?.toIso8601String(),
      'updatedAt':  updatedAt?.toIso8601String(),
    };
  }
}
