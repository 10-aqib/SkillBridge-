import 'dart:async';

import 'package:skill_bridge/features/jobs/data/datasources/job_remote_datasource.dart';
import 'package:skill_bridge/features/jobs/data/models/job_model.dart';

/// Records job writes (mocked — not real Firebase).
class FakeJobDataSource implements JobRemoteDataSource {
  final created = <JobModel>[];
  final edited = <JobModel>[];
  final statusChanges = <(String, String)>[];
  bool fail = false;
  bool queueOffline = false;
  Completer<void>? gate;

  @override
  Future<JobCreateResult> createJob(JobModel job) async {
    if (gate != null) await gate!.future;
    if (fail) throw Exception('PERMISSION_DENIED');
    created.add(job);
    return JobCreateResult(id: 'new_job_${created.length}', queuedOffline: queueOffline);
  }

  @override
  Future<void> editJob(JobModel job) async {
    if (fail) throw Exception('PERMISSION_DENIED');
    edited.add(job);
  }

  @override
  Future<void> setJobStatus(String jobId, String status) async {
    if (fail) throw Exception('PERMISSION_DENIED');
    statusChanges.add((jobId, status));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
