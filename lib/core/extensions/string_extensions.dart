extension StringExtensions on String {
  // Validation checks
  bool get isValidEmail {
    final emailRegExp = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegExp.hasMatch(trim());
  }

  bool get isValidPassword {
    // Minimum 6 characters (Firebase Auth requirement), max 128, no control/null chars
    return length >= 6 && length <= 128 && !contains(RegExp(r'[\x00-\x1F]'));
  }

  bool get isValidPhone {
    // Strict Pakistani mobile format: (+92xxxxxxxxx or 03xxxxxxxxx)
    final phoneRegExp = RegExp(r'^(?:\+92|0)3[0-9]{9}$');
    return phoneRegExp.hasMatch(trim());
  }

  // Capitalize first letter
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  // Parse double or return 0.0
  double get toDouble {
    return double.tryParse(this) ?? 0.0;
  }

  // Parse int or return 0
  int get toInt {
    return int.tryParse(this) ?? 0;
  }
}
