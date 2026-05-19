class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoURL;
  final String? bio;
  final String? phoneNumber;
  final List<String> followers;
  final List<String> following;
  final bool isAdmin;
  final DateTime createdAt;
  final DateTime? lastActive;
  final double sellerRatingAverage;
  final int sellerRatingCount;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoURL,
    this.bio,
    this.phoneNumber,
    this.followers = const [],
    this.following = const [],
    this.isAdmin = false,
    required this.createdAt,
    this.lastActive,
    this.sellerRatingAverage = 0.0,
    this.sellerRatingCount = 0,
  });

  // Convert to Map for API
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'bio': bio,
      'phoneNumber': phoneNumber,
      'followers': followers,
      'following': following,
      'isAdmin': isAdmin,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastActive': lastActive?.millisecondsSinceEpoch,
      'sellerRatingAverage': sellerRatingAverage,
      'sellerRatingCount': sellerRatingCount,
    };
  }

  // Create from JSON
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      photoURL: map['photoURL'],
      bio: map['bio'],
      phoneNumber: map['phoneNumber'],
      followers: List<String>.from(map['followers'] ?? []),
      following: List<String>.from(map['following'] ?? []),
      isAdmin: map['isAdmin'] == 1 || map['isAdmin'] == true, // Handle tinyint (1) or bool
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] is int ? map['createdAt'] : int.parse(map['createdAt'].toString())),
      lastActive: map['lastActive'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastActive'] is int ? map['lastActive'] : int.parse(map['lastActive'].toString()))
          : null,
      sellerRatingAverage:
          (map['sellerRatingAverage'] is int)
            ? (map['sellerRatingAverage'] as int).toDouble()
            : (double.tryParse(map['sellerRatingAverage'].toString()) ?? 0.0),
      sellerRatingCount: int.tryParse(map['sellerRatingCount'].toString()) ?? 0,
    );
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    String? bio,
    String? phoneNumber,
    List<String>? followers,
    List<String>? following,
    bool? isAdmin,
    DateTime? createdAt,
    DateTime? lastActive,
    double? sellerRatingAverage,
    int? sellerRatingCount,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      bio: bio ?? this.bio,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      isAdmin: isAdmin ?? this.isAdmin,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
      sellerRatingAverage: sellerRatingAverage ?? this.sellerRatingAverage,
      sellerRatingCount: sellerRatingCount ?? this.sellerRatingCount,
    );
  }
}
