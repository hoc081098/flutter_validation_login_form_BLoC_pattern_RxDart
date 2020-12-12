import 'package:rxdart/rxdart.dart';
import 'package:rxdart_ext/rxdart_ext.dart';

import '../api/api.dart';
import '../api/response.dart';
import 'login_contract.dart';

class LoginInteractorImpl implements LoginInteractor {
  final LoginApi _api;

  const LoginInteractorImpl(this._api);

  @override
  Stream<LoginMessage> performLogin(Credential credential) =>
      Rx.fromCallable(() => _api.login(credential.email, credential.password))
          .debug(identifier: 'LoginInteractorImpl::performLogin $credential')
          .onErrorReturnWith((e) => ErrorResponse(e))
          .map(_responseToMessage);

  /// Mapper that maps [LoginResponse] to [LoginMessage]
  static LoginMessage _responseToMessage(LoginResponse response) {
    if (response is SuccessResponse) {
      return LoginSuccessMessage(response.token);
    }
    if (response is ErrorResponse) {
      return LoginErrorMessage(response.error);
    }
    return LoginErrorMessage('Unknown response $response');
  }
}
