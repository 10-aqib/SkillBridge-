import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? _date(Object? v) => v is Timestamp ? v.toDate() : null;

/// A progress update the hired worker posted (contracts/{id}/updates).
/// Written only by contractActionCall, at server time.
class ContractUpdate {
  const ContractUpdate({required this.id, required this.note, required this.authorId, required this.createdAt});
  final String id;
  final String note;
  final String authorId;
  final DateTime createdAt;

  factory ContractUpdate.fromMap(String id, Map<String, dynamic> d) => ContractUpdate(
        id: id,
        note: (d['note'] ?? '').toString(),
        authorId: (d['authorId'] ?? '').toString(),
        createdAt: _date(d['createdAt']) ?? DateTime.now(),
      );
}

/// One submission of the work, and the client's answer if they asked for
/// changes (contracts/{id}/submissions/{number}). Server-written.
class ContractSubmission {
  const ContractSubmission({
    required this.number,
    required this.note,
    required this.attachments,
    this.submittedAt,
    this.revisionNote,
    this.revisionRequestedAt,
  });
  final int number;
  final String note;
  final List<String> attachments;
  final DateTime? submittedAt;
  final String? revisionNote;
  final DateTime? revisionRequestedAt;

  bool get sentBack => revisionNote != null && revisionNote!.isNotEmpty;

  factory ContractSubmission.fromMap(String id, Map<String, dynamic> d) => ContractSubmission(
        number: (d['number'] as num?)?.toInt() ?? int.tryParse(id) ?? 0,
        note: (d['note'] ?? '').toString(),
        attachments: (d['attachments'] as List?)?.whereType<String>().toList() ?? const [],
        submittedAt: _date(d['submittedAt']),
        revisionNote: d['revisionNote'] as String?,
        revisionRequestedAt: _date(d['revisionRequestedAt']),
      );
}
