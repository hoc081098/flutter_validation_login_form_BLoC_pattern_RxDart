import 'package:rxdart/rxdart.dart';
import 'package:validation_form_bloc/api/api.dart';
import 'package:validation_form_bloc/api/response.dart';
import 'package:validation_form_bloc/login/login_contract.dart';

class LoginInteractorImpl implements LoginInteractor {
  final LoginApi _api;

  const LoginInteractorImpl(this._api);

  @override
  Stream<LoginMessage> performLogin(
    Credential credential,
    Sink<bool> isLoadingSink,
  ) {
    print('[LOGIN_INTERACTOR] $credential');

    return Observable.defer(() => Stream.fromFuture(
            _api.login(credential.email, credential.password)))
        .doOnListen(() => isLoadingSink.add(true))
        .onErrorReturnWith((e) => ErrorResponse(e))
        .map(_responseToMessage)
        .doOnDone(() => isLoadingSink.add(false));
  }

  /// Mapper map [LoginResponse] to [LoginMessage]
  static LoginMessage _responseToMessage(LoginResponse response) {
    if (response is SuccessResponse) {
      return LoginSuccessMessage(response.token);
    }
    if (response is ErrorResponse) {
      return LoginErrorMessage(response.error);
    }
    return LoginErrorMessage("Unknown response $response");
  }
}
