import 'dart:async';

import 'package:disposebag/disposebag.dart';
import 'package:rxdart/rxdart.dart';

import '../validator.dart';
import 'login_contract.dart';

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
  final ValueStream<bool> isLoading$;
  final Stream<LoginMessage> message$;

  /// Clean up
  final void Function() dispose;

  LoginBloc._({
    required this.emailChanged,
    required this.passwordChanged,
    required this.submitLogin,
    required this.emailError$,
    required this.passwordError$,
    required this.isLoading$,
    required this.message$,
    required this.dispose,
  });

  factory LoginBloc(LoginInteractor interactor, Validator validator) {
    // Stream controllers
    final emailS = PublishSubject<String>(sync: true);
    final passwordS = PublishSubject<String>(sync: true);
    final isLoadingS = BehaviorSubject.seeded(false, sync: true);
    final submitLoginS = StreamController<void>(sync: true);
    final subjects = [emailS, passwordS, isLoadingS, submitLoginS];

    // Email error and password error stream
    final emailError$ = emailS.map(validator.validateEmail).distinct().share();

    final passwordError$ =
        passwordS.map(validator.validatePassword).distinct().share();

    // Submit stream
    final submit$ = submitLoginS.stream
        .throttleTime(const Duration(milliseconds: 500))
        .withLatestFrom<bool, bool>(
          Rx.combineLatest<Set<ValidationError>, bool>(
            [emailError$, passwordError$],
            (listOfSets) => listOfSets.every((errorsSet) => errorsSet.isEmpty),
          ).startWith(false),
          (_, isValid) => isValid,
        )
        .share();

    // Message stream
    final message$ = Rx.merge(
      [
        submit$
            .where((isValid) => isValid)
            .withLatestFrom2(
              emailS,
              passwordS,
              (_, String email, String password) => Credential(
                email: email,
                password: password,
              ),
            )
            .exhaustMap(
              (credential) => interactor
                  .performLogin(credential)
                  .doOnListen(() => isLoadingS.add(true))
                  .doOnCancel(() => isLoadingS.add(false)),
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
      dispose: DisposeBag([...subjects, message$.connect()]).dispose,
    );
  }
}
