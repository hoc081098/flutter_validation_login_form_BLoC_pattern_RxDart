import 'package:validation_form_bloc/model.dart';

///
/// Login api
///
class LoginApi {
  bool _success = false;

  ///
  /// Simulate login
  ///
  Future<Response> login(Credential credential) {
    final token =
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibm'
        'FtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c';

    final response =
        _success ? SuccessResponse(token) : ErrorResponse("Error api response");
    _success = !_success;

    return Future.delayed(
      const Duration(seconds: 3),
      () => response,
    );
  }
}
