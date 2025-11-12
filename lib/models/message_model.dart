
import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text }

class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final bool isRead;
  final bool isEdited;
  final DateTime? editedAt;
  final String chatId;
  String? translatedContent; // For cached translation

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    this.type = MessageType.text,
    required this.timestamp,
    this.isRead = false,
    this.isEdited = false,
    this.editedAt,
    required this.chatId,
    this.translatedContent,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'type': type.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'clientTimestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'isEdited': isEdited,
      'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
      'chatId': chatId,
    };
  }

  static MessageModel fromMap(Map<String, dynamic> map) {
    DateTime? _getDateTime(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      } else if (value is String) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    final DateTime timestamp = _getDateTime(map['timestamp']) ??
        _getDateTime(map['clientTimestamp']) ??
        DateTime.now();

    return MessageModel(
      id: map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      content: map['content'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => MessageType.text,
      ),
      timestamp: timestamp,
      isRead: map['isRead'] ?? false,
      isEdited: map['isEdited'] ?? false,
      editedAt: _getDateTime(map['editedAt']),
      chatId: map['chatId'] ?? '',
    );
  }

  MessageModel copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? content,
    MessageType? type,
    DateTime? timestamp,
    bool? isRead,
    bool? isEdited,
    DateTime? editedAt,
    String? chatId,
    String? translatedContent,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      chatId: chatId ?? this.chatId,
      translatedContent: translatedContent ?? this.translatedContent,
    );
  }
}
