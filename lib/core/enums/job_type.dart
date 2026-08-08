enum JobType {
  temporary('temporary'),
  permanent('permanent');

  final String value;
  const JobType(this.value);

  static JobType fromString(String val) {
    return JobType.values.firstWhere(
      (e) => e.value == val.toLowerCase(),
      orElse: () => JobType.temporary,
    );
  }
}
