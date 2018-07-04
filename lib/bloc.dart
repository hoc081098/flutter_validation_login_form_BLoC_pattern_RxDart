import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:validation_form_bloc/model.dart';

bool _isValidPassword(String password) {
  return password.length >= 6;
}

bool _isValidEmail(String email) {
  final _emailRegExpString = r'[a-zA-Z0-9\+\.\_\%\-\+]{1,256}\@[a-zA-Z0-9]'
      r'[a-zA-Z0-9\-]{0,64}(\.[a-zA-Z0-9][a-zA-Z0-9\-]{0,25})+';
  return RegExp(_emailRegExpString, caseSensitive: false).hasMatch(email);
}

class Bloc {
  final _emailController = BehaviorSubject<String>(seedValue: '');
  final _passwordController = BehaviorSubject<String>(seedValue: '');
  final _loadingController = BehaviorSubject<bool>(seedValue: false);
  final _loginController = StreamController<Null>();

  final _emailTransformer = new StreamTransformer<String, String>.fromHandlers(
    handleData: (email, eventSink) {
      if (_isValidEmail(email)) {
        eventSink.add(email);
      } else {
        eventSink.addError('Invalid email');
      }
    },
  );

  final _passwordTransformer =
      new StreamTransformer<String, String>.fromHandlers(
    handleData: (password, eventSink) {
      if (_isValidPassword(password)) {
        eventSink.add(password);
      } else {
        eventSink.addError('Too short password');
      }
    },
  );

  // sinks
  void Function(String) get emailChanged => _emailController.sink.add;

  void Function(String) get passwordChanged => _passwordController.sink.add;

  void Function() get submitLogin => () => _loginController.add(null);

  // streams
  Stream<String> get emailStream =>
      _emailController.stream.transform(_emailTransformer);

  Stream<String> get passwordStream =>
      _passwordController.stream.transform(_passwordTransformer);

  Stream<bool> get isLoading => _loadingController.stream;

  Stream<Response> results;

  Stream<bool> validSubmit;

  final Api api;

  Bloc(this.api) : assert(api != null) {
    final credentialStream = Observable.combineLatest2(
      emailStream,
      passwordStream,
      (email, password) => Credential(email: email, password: password),
    );
    results = Observable(_loginController.stream)
        .withLatestFrom<Credential, Credential>(credentialStream, (_, e) => e)
        .flatMap(
          (credential) => Observable
              .fromFuture(api.login(credential))
              .doOnListen(() => _loadingController.add(true))
              .doOnEach((_) => _loadingController.add(false)),
        );
    validSubmit = Observable.combineLatest3(
      _emailController.map(_isValidEmail),
      _passwordController.map(_isValidPassword),
      isLoading,
      (isValidEmail, isValidPassword, isLoading) =>
          isValidEmail && isValidPassword && !isLoading,
    );
  }

  dispose() {
    _emailController.close();
    _passwordController.close();
    _loginController.close();
    _loadingController.close();
  }
}
