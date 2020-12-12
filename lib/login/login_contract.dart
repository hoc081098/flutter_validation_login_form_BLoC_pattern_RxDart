import 'package:meta/meta.dart';

/// Credential contains email and password
class Credential {
  final String email;
  final String password;

  const Credential({required this.email, required this.password});

  @override
  String toString() => 'Credential{email: $email, password: $password}';
}

/// Interactor
abstract class LoginInteractor {
  Stream<LoginMessage> performLogin(Credential credential);
}

/// Login message
@immutable
abstract class LoginMessage {}

class LoginSuccessMessage implements LoginMessage {
  final String token;

  const LoginSuccessMessage(this.token);
}

class LoginErrorMessage implements LoginMessage {
  final Object error;

  const LoginErrorMessage(this.error);
}

class InvalidInformationMessage implements LoginMessage {
  const InvalidInformationMessage();
}
