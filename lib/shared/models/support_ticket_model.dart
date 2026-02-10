class SupportTicket {
  final String id;
  final String userId;
  final String? userEmail;
  final String? userName;
  final String subject;
  final String category;
  final String status;
  final String priority;
  final int messageCount;
  final SupportMessage? lastMessage;
  final DateTime createdAt;
  final DateTime? updatedAt;

  SupportTicket({
    required this.id,
    required this.userId,
    this.userEmail,
    this.userName,
    required this.subject,
    required this.category,
    required this.status,
    required this.priority,
    this.messageCount = 0,
    this.lastMessage,
    required this.createdAt,
    this.updatedAt,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      userEmail: json['user_email'],
      userName: json['user_name'],
      subject: json['subject'] ?? '',
      category: json['category'] ?? 'general',
      status: json['status'] ?? 'open',
      priority: json['priority'] ?? 'medium',
      messageCount: json['message_count'] ?? 0,
      lastMessage: json['last_message'] != null
          ? SupportMessage.fromJson(json['last_message'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }
}

class SupportMessage {
  final String senderId;
  final String text;
  final bool isAdmin;
  final DateTime createdAt;
  final String? attachmentUrl;

  SupportMessage({
    required this.senderId,
    required this.text,
    required this.isAdmin,
    required this.createdAt,
    this.attachmentUrl,
  });

  factory SupportMessage.fromJson(Map<String, dynamic> json) {
    return SupportMessage(
      senderId: json['sender_id'] ?? '',
      text: json['text'] ?? '',
      isAdmin: json['is_admin'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      attachmentUrl: json['attachment_url'],
    );
  }
}

class SupportTicketDetail {
  final String id;
  final String userId;
  final String? userEmail;
  final String? userName;
  final String subject;
  final String category;
  final String status;
  final String priority;
  final List<SupportMessage> messages;
  final DateTime createdAt;
  final DateTime? updatedAt;

  SupportTicketDetail({
    required this.id,
    required this.userId,
    this.userEmail,
    this.userName,
    required this.subject,
    required this.category,
    required this.status,
    required this.priority,
    required this.messages,
    required this.createdAt,
    this.updatedAt,
  });

  factory SupportTicketDetail.fromJson(Map<String, dynamic> json) {
    return SupportTicketDetail(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      userEmail: json['user_email'],
      userName: json['user_name'],
      subject: json['subject'] ?? '',
      category: json['category'] ?? 'general',
      status: json['status'] ?? 'open',
      priority: json['priority'] ?? 'medium',
      messages:
          (json['messages'] as List<dynamic>?)
              ?.map((m) => SupportMessage.fromJson(m))
              .toList() ??
          [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }
}
