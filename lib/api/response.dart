import 'package:meta/meta.dart';

@immutable
abstract class LoginResponse {}

class SuccessResponse extends LoginResponse {
  final String token;

  SuccessResponse(this.token);
}

class ErrorResponse extends LoginResponse {
  final error;

  ErrorResponse(this.error);
}
