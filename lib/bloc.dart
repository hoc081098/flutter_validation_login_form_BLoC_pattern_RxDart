import 'dart:async';

import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';
import 'package:validation_form_bloc/api.dart';
import 'package:validation_form_bloc/model.dart';

///
///
///

class Validator {
  Validator._();

  static bool isValidPassword(String password) {
    return password.length >= 6;
  }

  static bool isValidEmail(String email) {
    final _emailRegExpString = r'[a-zA-Z0-9\+\.\_\%\-\+]{1,256}\@[a-zA-Z0-9]'
        r'[a-zA-Z0-9\-]{0,64}(\.[a-zA-Z0-9][a-zA-Z0-9\-]{0,25})+';
    return RegExp(_emailRegExpString, caseSensitive: false).hasMatch(email);
  }
}

///
/// Login message
///

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

///
/// BLoC handle validate form and login
///
class LoginBloc {
  ///
  /// Input functions
  ///
  final void Function(String) emailChanged;
  final void Function(String) passwordChanged;
  final void Function() submitLogin;

  ///
  /// Streams
  ///
  final Stream<String> emailError$;
  final Stream<String> passwordError$;
  final ValueObservable<bool> isValidSubmit$;
  final ValueObservable<bool> isLoading$;
  final Stream<LoginMessage> message$;

  ///
  /// Clean up
  ///
  final void Function() dispose;

  LoginBloc._({
    @required this.emailChanged,
    @required this.passwordChanged,
    @required this.submitLogin,
    @required this.emailError$,
    @required this.passwordError$,
    @required this.isLoading$,
    @required this.message$,
    @required this.isValidSubmit$,
    @required this.dispose,
  });

  factory LoginBloc(LoginApi api) {
    assert(api != null);

    ///
    /// Controllers
    ///
    final emailController = PublishSubject<String>(); // ignore: close_sinks
    final passwordController = PublishSubject<String>(); // ignore: close_sinks
    final isLoadingController =
        BehaviorSubject<bool>(seedValue: false); // ignore: close_sinks
    final submitLoginController = PublishSubject<void>(); // ignore: close_sinks
    final controllers = <StreamController>[
      emailController,
      passwordController,
      isLoadingController,
      submitLoginController,
    ];

    ///
    /// Streams
    ///

    final isValidSubmit$ = Observable.combineLatest3(
      emailController.stream.map(Validator.isValidEmail),
      passwordController.stream.map(Validator.isValidPassword),
      isLoadingController.stream,
      (isValidEmail, isValidPassword, isLoading) {
        return isValidEmail && isValidPassword && !isLoading;
      },
    ).shareValue(seedValue: false);

    final credential$ = Observable.combineLatest2(
      emailController.stream,
      passwordController.stream,
      (email, password) => Credential(email: email, password: password),
    );

    final message$ = submitLoginController.stream
        .withLatestFrom(isValidSubmit$, (_, bool isValid) => isValid)
        .where((isValid) => isValid)
        .withLatestFrom(credential$, (_, Credential c) => c)
        .switchMap(
            (credential) => performLogin(api, credential, isLoadingController))
        .share();

    final emailError$ = emailController.stream
        .map((email) {
          if (Validator.isValidEmail(email)) return null;
          return 'Invalid email address';
        })
        .distinct()
        .share();

    final passwordError$ = passwordController.stream
        .map((password) {
          if (Validator.isValidPassword(password)) return null;
          return 'Password must be at least 6 characters';
        })
        .distinct()
        .share();

    final streams = <String, Stream>{
      'emailError': emailError$,
      'passwordError': passwordError$,
      'isLoading': isLoadingController,
      'isValidSubmit': isValidSubmit$,
      'message': message$,
    };
    final subscriptions = streams.keys
        .map((tag) =>
            streams[tag].listen((data) => print('[DEBUG] [$tag] = $data')))
        .toList();

    return LoginBloc._(
      emailChanged: emailController.add,
      passwordChanged: passwordController.add,
      submitLogin: () => submitLoginController.add(null),
      emailError$: emailError$,
      passwordError$: passwordError$,
      isLoading$: isLoadingController.stream,
      message$: message$,
      isValidSubmit$: isValidSubmit$,
      dispose: () async {
        await Future.wait(subscriptions.map((s) => s.cancel()));
        await Future.wait(controllers.map((c) => c.close()));
      },
    );
  }

  static Stream<LoginMessage> performLogin(
    LoginApi api,
    Credential credential,
    BehaviorSubject<bool> isLoadingController,
  ) {
    return Observable.fromFuture(api.login(credential))
        .doOnListen(() => isLoadingController.add(true))
        .doOnData((_) => isLoadingController.add(false))
        .doOnError((_) => isLoadingController.add(false))
        .onErrorReturnWith((e) => ErrorResponse(e))
        .map(_responseToMessage);
  }

  static LoginMessage _responseToMessage(response) {
    if (response is SuccessResponse) {
      return LoginSuccessMessage(response.token);
    }
    if (response is ErrorResponse) {
      return LoginErrorMessage(response.error);
    }
    return LoginErrorMessage("Unknown response $response");
  }
}
