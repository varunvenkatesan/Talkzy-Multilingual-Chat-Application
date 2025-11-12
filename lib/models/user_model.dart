import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String photoURL;
  final String gender;
  final String? avatarCode;
  final String bio;
  final bool isOnline;
  final DateTime lastSeen;
  final DateTime createdAt;
  
  // Privacy Settings
  final bool showLastSeen;
  final bool readReceipts;
  final String profilePhotoVisibility; // everyone, friends, nobody
  final String bioVisibility; // everyone, friends, nobody
  final List<String> blockedUsers; // List of blocked user IDs

  UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoURL = "",
    this.gender = "",
    this.avatarCode,
    this.bio = "Hey there! I am using Talkzy",
    this.isOnline = false,
    required this.lastSeen,
    required this.createdAt,
    this.showLastSeen = true,
    this.readReceipts = true,
    this.profilePhotoVisibility = 'everyone',
    this.bioVisibility = 'everyone',
    this.blockedUsers = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'gender': gender,
      'avatarCode': avatarCode,
      'bio': bio,
      'isOnline': isOnline,
      'lastSeen': Timestamp.fromDate(lastSeen),
      'createdAt': Timestamp.fromDate(createdAt),
      'showLastSeen': showLastSeen,
      'readReceipts': readReceipts,
      'profilePhotoVisibility': profilePhotoVisibility,
      'bioVisibility': bioVisibility,
      'blockedUsers': blockedUsers,
    };
  }

  static UserModel fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      photoURL: map['photoURL'] ?? '',
      gender: map['gender'] ?? '',
      avatarCode: map['avatarCode'],
      bio: map['bio'] ?? "Hey there! I am using Talkzy",
      isOnline: map['isOnline'] ?? false,
      lastSeen: map['lastSeen'] is Timestamp ? (map['lastSeen'] as Timestamp).toDate() : DateTime.now(),
      createdAt: map['createdAt'] is Timestamp ? (map['createdAt'] as Timestamp).toDate() : DateTime.now(),
      showLastSeen: map['showLastSeen'] ?? true,
      readReceipts: map['readReceipts'] ?? true,
      profilePhotoVisibility: map['profilePhotoVisibility'] ?? 'everyone',
      bioVisibility: map['bioVisibility'] ?? 'everyone',
      blockedUsers: map['blockedUsers'] != null ? List<String>.from(map['blockedUsers']) : [],
    );
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoURL,
    String? gender,
    String? avatarCode,
    String? bio,
    bool? isOnline,
    DateTime? lastSeen,
    DateTime? createdAt,
    bool? showLastSeen,
    bool? readReceipts,
    String? profilePhotoVisibility,
    String? bioVisibility,
    List<String>? blockedUsers,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      gender: gender ?? this.gender,
      avatarCode: avatarCode ?? this.avatarCode,
      bio: bio ?? this.bio,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt ?? this.createdAt,
      showLastSeen: showLastSeen ?? this.showLastSeen,
      readReceipts: readReceipts ?? this.readReceipts,
      profilePhotoVisibility: profilePhotoVisibility ?? this.profilePhotoVisibility,
      bioVisibility: bioVisibility ?? this.bioVisibility,
      blockedUsers: blockedUsers ?? this.blockedUsers,
    );
  }
}
