class ConversationModel {
  final String id;
  final String doctorId;
  final String userId;
  final DateTime? lastMessageAt;
  final Map<String, dynamic>? doctorProfile;

  const ConversationModel({
    required this.id,
    required this.doctorId,
    required this.userId,
    this.lastMessageAt,
    this.doctorProfile,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] as String,
      doctorId: json['doctor_id'] as String,
      userId: json['user_id'] as String,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.tryParse(json['last_message_at'])
          : null,
      doctorProfile: json['doctor'] as Map<String, dynamic>?,
    );
  }

  String get doctorName =>
      doctorProfile?['full_name'] as String? ?? 'Doctor';
  String get doctorSpecialization =>
      doctorProfile?['doctor_specialization'] as String? ?? '';
}

class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String body;
  final DateTime createdAt;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.body,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      body: json['body'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
