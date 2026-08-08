enum Availability {
  available('available'),
  busy('busy'),
  offline('offline');

  final String value;
  const Availability(this.value);

  static Availability fromString(String val) {
    return Availability.values.firstWhere(
      (e) => e.value == val.toLowerCase(),
      orElse: () => Availability.offline,
    );
  }
}
