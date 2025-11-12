

import 'package:cloud_firestore/cloud_firestore.dart';

enum FriendRequestStatus { pending, accepted, declined }

class FriendRequestModel {
  final String id;
  final String senderId;
  final String receiverId;
  final FriendRequestStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;
  final String? message;

  FriendRequestModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    this.status = FriendRequestStatus.pending,
    required this.createdAt,
    this.respondedAt,
    this.message,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'status': status.name,
      // FIX 1: Use native DateTime objects. Firestore handles conversion to Timestamp.
      'createdAt': createdAt, 
      'respondedAt': respondedAt, 
      'message': message,
    };
  }

  static FriendRequestModel fromMap(Map<String, dynamic> map) {
    // Note: When reading back, the map values will be Firestore Timestamp objects, 
    // which need to be converted to DateTime in the static method.
    
    // Helper function to safely convert Timestamp (or int/null) to DateTime
    DateTime? _convertToDateTime(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      return null;
    }
    
    return FriendRequestModel(
      id: map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      status: FriendRequestStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => FriendRequestStatus.pending,
      ),
      // FIX 2: Safely convert map value (which should be Timestamp from Firestore) to DateTime
      createdAt: _convertToDateTime(map['createdAt']) ?? DateTime.now(), 
      respondedAt: _convertToDateTime(map['respondedAt']), 
      message: map['message'],
    );
  }

  FriendRequestModel copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    FriendRequestStatus? status,
    DateTime? createdAt,
    DateTime? respondedAt,
    String? message,
  }) {
    return FriendRequestModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
      message: message ?? this.message,
    );
  }
}