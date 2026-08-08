enum JobStatus {
  open('open'),
  assigned('assigned'),
  inProgress('in_progress'),
  completed('completed'),
  cancelled('cancelled');

  final String value;
  const JobStatus(this.value);

  static JobStatus fromString(String val) {
    return JobStatus.values.firstWhere(
      (e) => e.value == val.toLowerCase(),
      orElse: () => JobStatus.open,
    );
  }
}
