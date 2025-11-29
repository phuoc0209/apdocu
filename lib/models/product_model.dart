import 'package:cloud_firestore/cloud_firestore.dart';

enum ProductCategory {
  homeAppliances, // đồ gia dụng
  fashion, // thời trang
  electronics, // điện tử
  books, // sách vở
  other // khác
}

enum ProductCondition {
  new90to100, // mới 90-100%
  usedLittle, // dùng ít
  usedModerate, // dùng vừa
  usedMuch, // dùng nhiều
}

enum ProductStatus {
  pending, // chờ duyệt
  approved, // đã duyệt
  rejected, // bị từ chối
  soldOut, // đã trao đổi
}

class ProductModel {
  final String id;
  final String title;
  final String description;
  final List<String> imageUrls;
  final ProductCategory category;
  final ProductCondition condition;
  final ProductStatus status;
  final String ownerId;
  final String ownerName;
  final String? ownerPhotoURL;
  final GeoPoint? location;
  final String? locationAddress;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int viewCount;
  final List<String> tags;

  ProductModel({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrls,
    required this.category,
    required this.condition,
    this.status = ProductStatus.pending,
    required this.ownerId,
    required this.ownerName,
    this.ownerPhotoURL,
    this.location,
    this.locationAddress,
    required this.createdAt,
    required this.updatedAt,
    this.viewCount = 0,
    this.tags = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrls': imageUrls,
      'category': category.toString().split('.').last,
      'condition': condition.toString().split('.').last,
      'status': status.toString().split('.').last,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'ownerPhotoURL': ownerPhotoURL,
      'location': location,
      'locationAddress': locationAddress,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'viewCount': viewCount,
      'tags': tags,
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      category: _categoryFromString(map['category']),
      condition: _conditionFromString(map['condition']),
      status: _statusFromString(map['status']),
      ownerId: map['ownerId'] ?? '',
      ownerName: map['ownerName'] ?? '',
      ownerPhotoURL: map['ownerPhotoURL'],
      location: map['location'] as GeoPoint?,
      locationAddress: map['locationAddress'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? 0),
      viewCount: map['viewCount'] ?? 0,
      tags: List<String>.from(map['tags'] ?? []),
    );
  }

  factory ProductModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductModel.fromMap({...data, 'id': doc.id});
  }

  static ProductCategory _categoryFromString(String? category) {
    switch (category) {
      case 'homeAppliances':
        return ProductCategory.homeAppliances;
      case 'fashion':
        return ProductCategory.fashion;
      case 'electronics':
        return ProductCategory.electronics;
      case 'books':
        return ProductCategory.books;
      default:
        return ProductCategory.other;
    }
  }

  static ProductCondition _conditionFromString(String? condition) {
    switch (condition) {
      case 'new90to100':
        return ProductCondition.new90to100;
      case 'usedLittle':
        return ProductCondition.usedLittle;
      case 'usedModerate':
        return ProductCondition.usedModerate;
      case 'usedMuch':
        return ProductCondition.usedMuch;
      default:
        return ProductCondition.usedLittle;
    }
  }

  static ProductStatus _statusFromString(String? status) {
    switch (status) {
      case 'pending':
        return ProductStatus.pending;
      case 'approved':
        return ProductStatus.approved;
      case 'rejected':
        return ProductStatus.rejected;
      case 'soldOut':
        return ProductStatus.soldOut;
      default:
        return ProductStatus.pending;
    }
  }

  ProductModel copyWith({
    String? id,
    String? title,
    String? description,
    List<String>? imageUrls,
    ProductCategory? category,
    ProductCondition? condition,
    ProductStatus? status,
    String? ownerId,
    String? ownerName,
    String? ownerPhotoURL,
    GeoPoint? location,
    String? locationAddress,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? viewCount,
    List<String>? tags,
  }) {
    return ProductModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrls: imageUrls ?? this.imageUrls,
      category: category ?? this.category,
      condition: condition ?? this.condition,
      status: status ?? this.status,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      ownerPhotoURL: ownerPhotoURL ?? this.ownerPhotoURL,
      location: location ?? this.location,
      locationAddress: locationAddress ?? this.locationAddress,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      viewCount: viewCount ?? this.viewCount,
      tags: tags ?? this.tags,
    );
  }

  // Helper methods
  String get categoryDisplayName {
    switch (category) {
      case ProductCategory.homeAppliances:
        return 'Đồ gia dụng';
      case ProductCategory.fashion:
        return 'Thời trang';
      case ProductCategory.electronics:
        return 'Điện tử';
      case ProductCategory.books:
        return 'Sách vở';
      case ProductCategory.other:
        return 'Khác';
    }
  }

  String get conditionDisplayName {
    switch (condition) {
      case ProductCondition.new90to100:
        return 'Mới 90-100%';
      case ProductCondition.usedLittle:
        return 'Dùng ít';
      case ProductCondition.usedModerate:
        return 'Dùng vừa';
      case ProductCondition.usedMuch:
        return 'Dùng nhiều';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case ProductStatus.pending:
        return 'Chờ duyệt';
      case ProductStatus.approved:
        return 'Đã duyệt';
      case ProductStatus.rejected:
        return 'Bị từ chối';
      case ProductStatus.soldOut:
        return 'Sold Out';
    }
  }
}
