enum UserRole {
  client('client'),
  worker('worker'),
  admin('admin');

  final String value;
  const UserRole(this.value);

  static UserRole fromString(String val) {
    return UserRole.values.firstWhere(
      (e) => e.value == val.toLowerCase(),
      orElse: () => UserRole.client,
    );
  }
}
