import 'package:cloud_firestore/cloud_firestore.dart';

/// Domain entity representing an authenticated user in SkillBridge.
class UserEntity {
  final String uid;
  final String email;
  final String displayName;
  final String phoneNumber;
  final String? photoUrl;
  final String role; // "client" | "worker" | "admin"
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final bool isCnicVerified;
  final bool isActive;
  final String? fcmToken;
  final String? cnicNumber;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Client-specific
  final String? address;
  final String? city;
  final GeoPoint? location;
  final int totalJobsPosted;
  final int totalHires;

  // Rating & Reviews
  final double rating;
  final int totalReviews;

  // Worker-specific
  final WorkerProfileEntity? workerProfile;

  const UserEntity({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.phoneNumber,
    this.photoUrl,
    required this.role,
    required this.isEmailVerified,
    required this.isPhoneVerified,
    this.isCnicVerified = false,
    required this.isActive,
    this.fcmToken,
    this.cnicNumber,
    required this.createdAt,
    required this.updatedAt,
    this.address,
    this.city,
    this.location,
    this.totalJobsPosted = 0,
    this.totalHires = 0,
    this.rating = 5.0,
    this.totalReviews = 0,
    this.workerProfile,
  });

  String? get profilePictureUrl => photoUrl;
  bool get isClient => role == 'client';
  bool get isWorker => role == 'worker';
  bool get isAdmin => role == 'admin';
  bool get isWorkerProfileComplete =>
      workerProfile != null &&
      workerProfile!.headline.isNotEmpty &&
      workerProfile!.bio.isNotEmpty &&
      workerProfile!.categoryId.isNotEmpty;

  UserEntity copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? phoneNumber,
    String? photoUrl,
    String? role,
    bool? isEmailVerified,
    bool? isPhoneVerified,
    bool? isCnicVerified,
    bool? isActive,
    String? fcmToken,
    String? cnicNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? address,
    String? city,
    GeoPoint? location,
    int? totalJobsPosted,
    int? totalHires,
    WorkerProfileEntity? workerProfile,
  }) {
    return UserEntity(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      isCnicVerified: isCnicVerified ?? this.isCnicVerified,
      isActive: isActive ?? this.isActive,
      fcmToken: fcmToken ?? this.fcmToken,
      cnicNumber: cnicNumber ?? this.cnicNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      address: address ?? this.address,
      city: city ?? this.city,
      location: location ?? this.location,
      totalJobsPosted: totalJobsPosted ?? this.totalJobsPosted,
      totalHires: totalHires ?? this.totalHires,
      workerProfile: workerProfile ?? this.workerProfile,
    );
  }
}

class WorkerProfileEntity {
  final String headline;
  final String bio;
  final String categoryId;
  final String categoryName;
  final List<String> skills;
  final int experience;
  final double hourlyRate;
  final double dailyRate;
  final List<CertificationEntity> certifications;
  final List<String> portfolioImages;
  final String availability; // "available" | "busy" | "offline"
  final bool isVerified;
  final String? verificationDocUrl;
  final String city;
  final String? address;
  final GeoPoint? location;
  final double serviceRadius;
  final int totalJobsCompleted;
  final double totalEarnings;
  final double averageRating;
  final int totalReviews;
  
  // New Module 1 Fields
  final String? coverImage;
  final List<String> languages;
  final String? responseTime;
  final List<String> beforeAfterImages;

  const WorkerProfileEntity({
    required this.headline,
    required this.bio,
    required this.categoryId,
    required this.categoryName,
    this.skills = const [],
    this.experience = 0,
    this.hourlyRate = 0,
    this.dailyRate = 0,
    this.certifications = const [],
    this.portfolioImages = const [],
    this.availability = 'available',
    this.isVerified = false,
    this.verificationDocUrl,
    required this.city,
    this.address,
    this.location,
    this.serviceRadius = 10,
    this.totalJobsCompleted = 0,
    this.totalEarnings = 0,
    this.averageRating = 0,
    this.totalReviews = 0,
    this.coverImage,
    this.languages = const [],
    this.responseTime,
    this.beforeAfterImages = const [],
  });
}

class CertificationEntity {
  final String name;
  final String issuedBy;
  final int year;
  final String? imageUrl;

  const CertificationEntity({
    required this.name,
    required this.issuedBy,
    required this.year,
    this.imageUrl,
  });
}
