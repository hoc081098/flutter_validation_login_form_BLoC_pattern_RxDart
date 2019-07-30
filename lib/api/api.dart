import 'package:validation_form_bloc/api/response.dart';

///
/// Login api
///
class LoginApi {
  bool _success = false;

  ///
  /// Simulate login
  ///
  Future<LoginResponse> login(String email, String password) {
    print('[API] login email=$email, password=$password');

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
