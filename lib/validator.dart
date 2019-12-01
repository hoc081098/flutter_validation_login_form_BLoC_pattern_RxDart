extension ValidationExtension on String {
  bool isValidPassword() {
    return this.length >= 6;
  }

  bool isValidEmail() {
    const _emailRegExpString = r'[a-zA-Z0-9\+\.\_\%\-\+]{1,256}\@[a-zA-Z0-9]'
        r'[a-zA-Z0-9\-]{0,64}(\.[a-zA-Z0-9][a-zA-Z0-9\-]{0,25})+';
    return RegExp(_emailRegExpString, caseSensitive: false).hasMatch(this);
  }
}

enum ValidationError { invalidEmail, tooShortPassword }

class Validator {
  const Validator();

  /// return set of [ValidationError]s (return empty set if email is valid)
  Set<ValidationError> validateEmail(String email) {
    if (email.isValidEmail()) {
      return const {};
    }
    return {ValidationError.invalidEmail};
  }

  /// return set of [ValidationError]s (return empty set if password is valid)
  Set<ValidationError> validatePassword(String password) {
    if (password.isValidPassword()) {
      return const {};
    }
    return {ValidationError.tooShortPassword};
  }
}
