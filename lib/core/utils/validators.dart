import 'package:skill_bridge/core/extensions/string_extensions.dart';

class Validators {
  static String? required(
    String? value, {
    String fieldName = 'Field',
    int maxLength = 255,
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    if (value.length > maxLength) {
      return '$fieldName must not exceed $maxLength characters';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    if (value.length > 254) {
      return 'Email must not exceed 254 characters';
    }
    if (!value.isValidEmail) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Password is required';
    }
    if (value.length > 128) {
      return 'Password must not exceed 128 characters';
    }
    if (!value.isValidPassword) {
      return 'Password must be at least 6 characters without special control symbols';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.trim().isEmpty) {
      return 'Confirm password is required';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    if (value.length > 15) {
      return 'Phone number is too long';
    }
    if (!value.isValidPhone) {
      return 'Enter a valid Pakistani phone number (e.g., 03xxxxxxxxx)';
    }
    return null;
  }

  static String? numeric(String? value, {String fieldName = 'Value'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    if (double.tryParse(value) == null) {
      return '$fieldName must be a number';
    }
    return null;
  }
}

