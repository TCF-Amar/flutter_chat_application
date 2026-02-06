class NormalizePhoneNumber {
  // add +91 if not present
  static String normalizeIndianPhoneTypeFirst(String phone) {
    final value = phone.replaceAll(RegExp(r'\s+'), '');

    if (value.startsWith('+91')) {
      return value;
    }

    if (value.startsWith('91') && value.length == 12) {
      return '+$value';
    }

    if (value.startsWith('0') && value.length == 11) {
      return '+91${value.substring(1)}';
    }

    if (value.length == 10) {
      return '+91$value';
    }
    if (value.length < 10) {
      throw Exception('Invalid phone number length');
    }

    throw Exception('Invalid phone number format');
  }

  // remove +91 if present
  static String normalizeIndianPhoneTypeSecond(String phone) {
    final value = phone.replaceAll(RegExp(r'\s+'), '');

    if (value.startsWith('+91')) {
      return value.substring(3);
    }

    if (value.startsWith('91') && value.length == 12) {
      return value.substring(2);
    }

    if (value.startsWith('0') && value.length == 11) {
      return value.substring(1);
    }

    if (value.length == 10) {
      return value;
    }
    if (value.length < 10) {
      throw Exception('Invalid phone number length');
    }

    throw Exception('Invalid phone number format');
  }
}
