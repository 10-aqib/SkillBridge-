import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skill_bridge/core/enums/job_status.dart';
import 'package:skill_bridge/core/enums/job_type.dart';
import 'package:skill_bridge/features/jobs/domain/entities/job_entity.dart';
import 'package:skill_bridge/features/jobs/domain/job_search.dart';

class JobModel extends JobEntity {
  const JobModel({
    required super.id,
    required super.clientId,
    required super.clientName,
    super.clientPhotoUrl,
    required super.title,
    required super.description,
    required super.categoryId,
    required super.categoryName,
    required super.requiredSkills,
    required super.jobType,
    required super.budgetMin,
    required super.budgetMax,
    required super.budgetType,
    super.location,
    super.geohash,
    super.locationAccuracy,
    super.locationUpdatedAt,
    required super.address,
    required super.city,
    required super.status,
    required super.urgency,
    required super.images,
    required super.totalProposals,
    super.selectedWorkerId,
    super.selectedWorkerName,
    super.startDate,
    super.endDate,
    required super.createdAt,
    required super.updatedAt,
    super.isPaid = false,
    super.searchKeywords = const [],
  });

  factory JobModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return JobModel.fromMap(doc.id, data);
  }

  factory JobModel.fromMap(String id, Map<String, dynamic> data) {
    return JobModel(
      id: id,
      clientId: data['clientId'] ?? '',
      clientName: data['clientName'] ?? '',
      clientPhotoUrl: data['clientPhotoUrl'],
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      categoryId: data['categoryId'] ?? '',
      categoryName: data['categoryName'] ?? '',
      requiredSkills: List<String>.from(data['requiredSkills'] ?? []),
      jobType: JobType.values.firstWhere(
        (e) => e.name == data['jobType'],
        orElse: () => JobType.temporary,
      ),
      budgetMin: (data['budgetMin'] ?? 0).toDouble(),
      budgetMax: (data['budgetMax'] ?? 0).toDouble(),
      budgetType: data['budgetType'] ?? 'fixed',
      location: data['location'] as GeoPoint?,
      geohash: data['geohash'] as String?,
      locationAccuracy: data['locationAccuracy'] as String?,
      locationUpdatedAt: (data['locationUpdatedAt'] as Timestamp?)?.toDate(),
      address: data['address'] ?? '',
      city: data['city'] ?? '',
      status: JobStatus.values.firstWhere(
        (e) => e.name == data['status'] || e.value == data['status'],
        orElse: () => JobStatus.open,
      ),
      urgency: data['urgency'] ?? 'normal',
      images: List<String>.from(data['images'] ?? []),
      totalProposals: data['totalProposals'] ?? 0,
      selectedWorkerId: data['selectedWorkerId'],
      selectedWorkerName: data['selectedWorkerName'],
      startDate: (data['startDate'] as Timestamp?)?.toDate(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isPaid: data['isPaid'] ?? false,
      searchKeywords: List<String>.from(data['searchKeywords'] ?? const []),
    );
  }

  /// Derived fields kept in step with the content: search keywords and the
  /// budget band used by the job feed filters.
  Map<String, dynamic> get derivedFields => {
        'searchKeywords': JobSearchIndex.keywordsFor(
          title: title,
          categoryName: categoryName,
          categoryId: categoryId,
          skills: requiredSkills,
          description: description,
          city: city,
        ),
        'budgetBand': BudgetBand.forJob(budgetMin, budgetMax).id,
      };

  /// New job: server timestamps (rules require createdAt == request.time).
  Map<String, dynamic> toCreateMap() => {
        ...toMap(),
        ...derivedFields,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  /// Fields a client may change when editing an open job. Ownership, status,
  /// assignment, proposal count and payment are never sent.
  Map<String, dynamic> toEditMap() => {
        'title': title,
        'description': description,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'requiredSkills': requiredSkills,
        'budgetMin': budgetMin,
        'budgetMax': budgetMax,
        'budgetType': budgetType,
        'address': address,
        'city': city,
        'urgency': urgency,
        'images': images,
        'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
        ...derivedFields,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'clientName': clientName,
      'clientPhotoUrl': clientPhotoUrl,
      'title': title,
      'description': description,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'requiredSkills': requiredSkills,
      'jobType': jobType.name,
      'budgetMin': budgetMin,
      'budgetMax': budgetMax,
      'budgetType': budgetType,
      'location': location,
      if (geohash != null) 'geohash': geohash,
      if (locationAccuracy != null) 'locationAccuracy': locationAccuracy,
      if (locationUpdatedAt != null)
        'locationUpdatedAt': Timestamp.fromDate(locationUpdatedAt!),
      'address': address,
      'city': city,
      'status': status.value,
      'urgency': urgency,
      'images': images,
      'totalProposals': totalProposals,
      'selectedWorkerId': selectedWorkerId,
      'selectedWorkerName': selectedWorkerName,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
      'isPaid': isPaid,
    };
  }
}
