import 'dart:async';

import 'package:disposebag/disposebag.dart';
import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';
import 'package:validation_form_bloc/login/login_contract.dart';
import 'package:validation_form_bloc/validator.dart';

// ignore_for_file: close_sinks

/// BLoC handle validate form and login
class LoginBloc {
  /// Input functions
  final void Function(String) emailChanged;
  final void Function(String) passwordChanged;
  final void Function() submitLogin;

  /// Streams
  final Stream<Set<ValidationError>> emailError$;
  final Stream<Set<ValidationError>> passwordError$;
  final ValueObservable<bool> isLoading$;
  final Stream<LoginMessage> message$;

  /// Clean up
  final void Function() dispose;

  LoginBloc._({
    @required this.emailChanged,
    @required this.passwordChanged,
    @required this.submitLogin,
    @required this.emailError$,
    @required this.passwordError$,
    @required this.isLoading$,
    @required this.message$,
    @required this.dispose,
  });

  factory LoginBloc(LoginInteractor interactor) {
    assert(interactor != null);
    const validator = Validator();

    // Stream controllers
    final emailS = BehaviorSubject.seeded('');
    final passwordS = BehaviorSubject.seeded('');
    final isLoadingS = BehaviorSubject.seeded(false);
    final submitLoginS = PublishSubject<void>();
    final subjects = [emailS, passwordS, isLoadingS, submitLoginS];

    // Email error and password error stream
    final emailError$ = emailS.map(validator.validateEmail).distinct().share();

    final passwordError$ =
        passwordS.map(validator.validatePassword).distinct().share();

    // Submit stream
    final submit$ = submitLoginS
        .throttleTime(const Duration(milliseconds: 500))
        .withLatestFrom<bool, bool>(
          Observable.combineLatest<Set<ValidationError>, bool>(
            [emailError$, passwordError$],
            (listOfSets) => listOfSets.every((errorsSet) => errorsSet.isEmpty),
          ),
          (_, isValid) => isValid,
        )
        .share();

    // Message stream
    final message$ = Observable.merge(
      [
        submit$
            .where((isValid) => isValid)
            .withLatestFrom2(
              emailS,
              passwordS,
              (_, email, password) => Credential(
                email: email,
                password: password,
              ),
            )
            .exhaustMap(
              (credential) => interactor.performLogin(
                credential,
                isLoadingS,
              ),
            ),
        submit$
            .where((isValid) => !isValid)
            .map((_) => const InvalidInformationMessage()),
      ],
    ).publish();

    return LoginBloc._(
      emailChanged: emailS.add,
      passwordChanged: passwordS.add,
      submitLogin: () => submitLoginS.add(null),
      emailError$: emailError$,
      passwordError$: passwordError$,
      isLoading$: isLoadingS.stream,
      message$: message$,
      dispose: DisposeBag([message$.connect(), ...subjects]).dispose,
    );
  }
}
