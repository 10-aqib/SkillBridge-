import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skill_bridge/features/auth/domain/entities/user_entity.dart';

/// Data model that extends UserEntity and handles Firestore serialization.
class UserModel extends UserEntity {
  const UserModel({
    required super.uid,
    required super.email,
    required super.displayName,
    required super.phoneNumber,
    super.photoUrl,
    required super.role,
    required super.isEmailVerified,
    required super.isPhoneVerified,
    super.isCnicVerified = false,
    required super.isActive,
    super.fcmToken,
    super.cnicNumber,
    required super.createdAt,
    required super.updatedAt,
    super.address,
    super.city,
    super.location,
    super.totalJobsPosted,
    super.totalHires,
    super.rating,
    super.totalReviews,
    super.workerProfile,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: data['uid'] as String? ?? doc.id,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      phoneNumber: data['phoneNumber'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      role: data['role'] as String? ?? 'client',
      isEmailVerified: data['isEmailVerified'] as bool? ?? false,
      isPhoneVerified: data['isPhoneVerified'] as bool? ?? false,
      isCnicVerified: data['isCnicVerified'] as bool? ?? false,
      isActive: data['isActive'] as bool? ?? true,
      fcmToken: data['fcmToken'] as String?,
      cnicNumber: data['cnicNumber'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      address: data['address'] as String?,
      city: data['city'] as String?,
      location: data['location'] as GeoPoint?,
      totalJobsPosted: data['totalJobsPosted'] as int? ?? 0,
      totalHires: data['totalHires'] as int? ?? 0,
      rating: (data['rating'] as num?)?.toDouble() ?? 5.0,
      totalReviews: data['totalReviews'] as int? ?? 0,
      workerProfile: data['workerProfile'] != null
          ? WorkerProfileModel.fromMap(
              data['workerProfile'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      if (photoUrl != null) 'photoUrl': photoUrl,
      'role': role,
      'isEmailVerified': isEmailVerified,
      'isPhoneVerified': isPhoneVerified,
      'isCnicVerified': isCnicVerified,
      'isActive': isActive,
      if (fcmToken != null) 'fcmToken': fcmToken,
      if (cnicNumber != null) 'cnicNumber': cnicNumber,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (address != null) 'address': address,
      if (city != null) 'city': city,
      if (location != null) 'location': location,
      'totalJobsPosted': totalJobsPosted,
      'totalHires': totalHires,
      'rating': rating,
      'totalReviews': totalReviews,
      if (workerProfile != null)
        'workerProfile':
            WorkerProfileModel.fromEntity(workerProfile!).toMap(),
    };
  }

  /// Creates an initial Firestore document for a newly registered user.
  factory UserModel.newUser({
    required String uid,
    required String email,
    required String displayName,
    required String phoneNumber,
    required String role,
    String? city,
  }) {
    final now = DateTime.now();
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName,
      phoneNumber: phoneNumber,
      role: role,
      city: city,
      isEmailVerified: false,
      isPhoneVerified: false,
      isCnicVerified: false,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );
  }
}

class WorkerProfileModel extends WorkerProfileEntity {
  const WorkerProfileModel({
    required super.headline,
    required super.bio,
    required super.categoryId,
    required super.categoryName,
    super.skills,
    super.experience,
    super.hourlyRate,
    super.dailyRate,
    super.certifications,
    super.portfolioImages,
    super.availability,
    super.isVerified,
    super.verificationDocUrl,
    required super.city,
    super.address,
    super.location,
    super.serviceRadius,
    super.totalJobsCompleted,
    super.totalEarnings,
    super.averageRating,
    super.totalReviews,
    super.coverImage,
    super.languages,
    super.responseTime,
    super.beforeAfterImages,
  });

  factory WorkerProfileModel.fromMap(Map<String, dynamic> map) {
    return WorkerProfileModel(
      headline: map['headline'] as String? ?? '',
      bio: map['bio'] as String? ?? '',
      categoryId: map['categoryId'] as String? ?? '',
      categoryName: map['categoryName'] as String? ?? '',
      skills: List<String>.from(map['skills'] as List? ?? []),
      experience: map['experience'] as int? ?? 0,
      hourlyRate: (map['hourlyRate'] as num?)?.toDouble() ?? 0,
      dailyRate: (map['dailyRate'] as num?)?.toDouble() ?? 0,
      certifications: (map['certifications'] as List? ?? [])
          .map((e) => CertificationModel.fromMap(e as Map<String, dynamic>))
          .toList(),
      portfolioImages: List<String>.from(map['portfolioImages'] as List? ?? []),
      availability: map['availability'] as String? ?? 'available',
      isVerified: map['isVerified'] as bool? ?? false,
      verificationDocUrl: map['verificationDocUrl'] as String?,
      city: map['city'] as String? ?? '',
      address: map['address'] as String?,
      location: map['location'] as GeoPoint?,
      serviceRadius: (map['serviceRadius'] as num?)?.toDouble() ?? 10,
      totalJobsCompleted: map['totalJobsCompleted'] as int? ?? 0,
      totalEarnings: (map['totalEarnings'] as num?)?.toDouble() ?? 0,
      averageRating: (map['averageRating'] as num?)?.toDouble() ?? 0,
      totalReviews: map['totalReviews'] as int? ?? 0,
      coverImage: map['coverImage'] as String?,
      languages: List<String>.from(map['languages'] as List? ?? []),
      responseTime: map['responseTime'] as String?,
      beforeAfterImages: List<String>.from(map['beforeAfterImages'] as List? ?? []),
    );
  }

  factory WorkerProfileModel.fromEntity(WorkerProfileEntity entity) {
    return WorkerProfileModel(
      headline: entity.headline,
      bio: entity.bio,
      categoryId: entity.categoryId,
      categoryName: entity.categoryName,
      skills: entity.skills,
      experience: entity.experience,
      hourlyRate: entity.hourlyRate,
      dailyRate: entity.dailyRate,
      certifications: entity.certifications,
      portfolioImages: entity.portfolioImages,
      availability: entity.availability,
      isVerified: entity.isVerified,
      verificationDocUrl: entity.verificationDocUrl,
      city: entity.city,
      address: entity.address,
      location: entity.location,
      serviceRadius: entity.serviceRadius,
      totalJobsCompleted: entity.totalJobsCompleted,
      totalEarnings: entity.totalEarnings,
      averageRating: entity.averageRating,
      totalReviews: entity.totalReviews,
      coverImage: entity.coverImage,
      languages: entity.languages,
      responseTime: entity.responseTime,
      beforeAfterImages: entity.beforeAfterImages,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'headline': headline,
      'bio': bio,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'skills': skills,
      'experience': experience,
      'hourlyRate': hourlyRate,
      'dailyRate': dailyRate,
      'certifications': certifications
          .map((c) => CertificationModel.fromEntity(c).toMap())
          .toList(),
      'portfolioImages': portfolioImages,
      'availability': availability,
      'isVerified': isVerified,
      if (verificationDocUrl != null) 'verificationDocUrl': verificationDocUrl,
      'city': city,
      if (address != null) 'address': address,
      if (location != null) 'location': location,
      'serviceRadius': serviceRadius,
      'totalJobsCompleted': totalJobsCompleted,
      'totalEarnings': totalEarnings,
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      if (coverImage != null) 'coverImage': coverImage,
      'languages': languages,
      if (responseTime != null) 'responseTime': responseTime,
      'beforeAfterImages': beforeAfterImages,
    };
  }
}

class CertificationModel extends CertificationEntity {
  const CertificationModel({
    required super.name,
    required super.issuedBy,
    required super.year,
    super.imageUrl,
  });

  factory CertificationModel.fromMap(Map<String, dynamic> map) {
    return CertificationModel(
      name: map['name'] as String? ?? '',
      issuedBy: map['issuedBy'] as String? ?? '',
      year: map['year'] as int? ?? 0,
      imageUrl: map['imageUrl'] as String?,
    );
  }

  factory CertificationModel.fromEntity(CertificationEntity entity) {
    return CertificationModel(
      name: entity.name,
      issuedBy: entity.issuedBy,
      year: entity.year,
      imageUrl: entity.imageUrl,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'issuedBy': issuedBy,
        'year': year,
        if (imageUrl != null) 'imageUrl': imageUrl,
      };
}
