import 'dart:async';

import 'package:disposebag/disposebag.dart';
import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';
import 'package:validation_form_bloc/login/login_contract.dart';
import 'package:validation_form_bloc/validator.dart';

// ignore_for_file: close_sinks

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

  factory LoginBloc(LoginInteractor interactor) {
    assert(interactor != null);

    ///
    /// Stream controllers
    ///
    final emailSubject = BehaviorSubject.seeded('');
    final passwordSubject = BehaviorSubject.seeded('');
    final isLoadingSubject = BehaviorSubject.seeded(false);
    final submitLoginSubject = PublishSubject<void>();

    ///
    /// Email error and password error stream
    ///

    final emailError$ = emailSubject.stream
        .map((email) {
          if (Validator.isValidEmail(email)) {
            return null;
          }
          return 'Invalid email address';
        })
        .distinct()
        .share();

    final passwordError$ = passwordSubject.stream
        .map((password) {
          if (Validator.isValidPassword(password)) {
            return null;
          }
          return 'Password must be at least 6 characters';
        })
        .distinct()
        .share();

    ///
    /// Submit, credential stream
    ///

    final isValidSubmit$ = Observable.combineLatest(
      [emailError$, passwordError$],
      (errors) => errors.every((e) => e == null),
    );

    final submit$ = submitLoginSubject.stream
        .withLatestFrom(isValidSubmit$, (_, bool isValid) => isValid)
        .share();

    final credential$ = Observable.combineLatest2(
      emailSubject,
      passwordSubject,
      (String email, String password) =>
          Credential(email: email, password: password),
    );

    ///
    /// Message stream
    ///

    final message$ = Observable.merge(
      [
        submit$
            .where((isValid) => isValid)
            .withLatestFrom(credential$, (_, Credential c) => c)
            .switchMap((credential) =>
                interactor.performLogin(credential, isLoadingSubject)),
        submit$
            .where((isValid) => !isValid)
            .map((_) => const InvalidInformationMessage())
      ],
    ).publish();

    ///
    /// Listen to debug
    ///

    final streams = <String, Stream>{
      'emailError': emailError$,
      'passwordError': passwordError$,
      'isLoading': isLoadingSubject,
      'isValidSubmit': isValidSubmit$,
      'message': message$,
    };
    final subscriptions = streams.keys.map((tag) =>
        streams[tag].listen((data) => print('[LOGIN_BLOC] $tag=$data')));
    final disposeBag = DisposeBag([
      ...subscriptions,
      message$.connect(),
      emailSubject,
      passwordSubject,
      isLoadingSubject,
      submitLoginSubject,
    ]);

    return LoginBloc._(
      emailChanged: emailSubject.add,
      passwordChanged: passwordSubject.add,
      submitLogin: () => submitLoginSubject.add(null),
      emailError$: emailError$,
      passwordError$: passwordError$,
      isLoading$: isLoadingSubject.stream,
      message$: message$,
      isValidSubmit$: isValidSubmit$,
      dispose: disposeBag.dispose,
    );
  }
}
