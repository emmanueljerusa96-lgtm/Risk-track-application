abstract final class Validators {
  static String? fullName(String? value) {
    final name = value?.trim() ?? '';
    if (name.length < 2 || name.length > 80) {
      return 'Enter a name between 2 and 80 characters.';
    }
    return null;
  }

  static String? email(String? value) {
    final email = value?.trim() ?? '';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.length < 8) {
      return 'Use at least 8 characters.';
    }
    return null;
  }

  static String? title(String? value) {
    final title = value?.trim() ?? '';
    if (title.length < 5 || title.length > 100) {
      return 'Enter a title between 5 and 100 characters.';
    }
    return null;
  }

  static String? description(String? value) {
    final description = value?.trim() ?? '';
    if (description.length < 20 || description.length > 1500) {
      return 'Describe what was reported (20–1500 characters).';
    }
    return null;
  }

  static String? flagReason(String? value) {
    final reason = value?.trim() ?? '';
    if (reason.length < 10 || reason.length > 500) {
      return 'Explain the concern in 10–500 characters.';
    }
    return null;
  }
}
