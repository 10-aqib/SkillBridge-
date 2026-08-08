import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skill_bridge/core/enums/job_status.dart';
import 'package:skill_bridge/core/enums/job_type.dart';

class JobEntity {
  final String id;
  final String clientId;
  final String clientName;
  final String? clientPhotoUrl;
  final String title;
  final String description;
  final String categoryId;
  final String categoryName;
  final List<String> requiredSkills;
  final JobType jobType;
  final double budgetMin;
  final double budgetMax;
  final String budgetType; // "hourly", "daily", "fixed"
  final GeoPoint? location;
  final String address;
  final String city;
  final JobStatus status;
  final String urgency; // "normal", "urgent"
  final List<String> images;
  final int totalProposals;
  final String? selectedWorkerId;
  final String? selectedWorkerName;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPaid;

  const JobEntity({
    required this.id,
    required this.clientId,
    required this.clientName,
    this.clientPhotoUrl,
    required this.title,
    required this.description,
    required this.categoryId,
    required this.categoryName,
    required this.requiredSkills,
    required this.jobType,
    required this.budgetMin,
    required this.budgetMax,
    required this.budgetType,
    this.location,
    required this.address,
    required this.city,
    required this.status,
    required this.urgency,
    required this.images,
    required this.totalProposals,
    this.selectedWorkerId,
    this.selectedWorkerName,
    this.startDate,
    this.endDate,
    required this.createdAt,
    required this.updatedAt,
    this.isPaid = false,
  });
}
