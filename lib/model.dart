import 'package:meta/meta.dart';

class Credential {
  final String email;
  final String password;

  Credential({this.email, this.password});
}

@immutable
abstract class Response {}

class SuccessResponse extends Response {
  final String token;

  SuccessResponse(this.token);
}

class ErrorResponse extends Response {
  final error;

  ErrorResponse(this.error);
}
