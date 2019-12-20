# flutter_validation_login_form_BLoC_pattern_RxDart

Sample Mobile Validation using `rxdart` and `BLoC pattern`

# Screenshot

[Video demo](https://www.youtube.com/watch?v=i5gS2BToNZs&feature=youtu.be)

<p align="center">
<img src="screenshots/demo.gif" height="480" alt="Cannot load image"/>
</p>

# BLoC
### 1. Create stream controllers to receive input: email, password, submit
```dart
// Stream controllers
final emailS = BehaviorSubject.seeded('');
final passwordS = BehaviorSubject.seeded('');
final isLoadingS = BehaviorSubject.seeded(false);
final submitLoginS = StreamController<void>();
final subjects = [emailS, passwordS, isLoadingS, submitLoginS];
```
### 2. Map email text and password text to set of errors
```dart
// Email error and password error stream
final emailError$ = emailS.map(validator.validateEmail).distinct().share();
 
final passwordError$ =
    passwordS.map(validator.validatePassword).distinct().share();
```
### 3. Combine email errors stream and password errors stream to valid stream
```dart
// Submit stream
final submit$ = submitLoginS.stream
    .throttleTime(const Duration(milliseconds: 500))
    .withLatestFrom<bool, bool>(
      Rx.combineLatest<Set<ValidationError>, bool>(
        [emailError$, passwordError$],
        (listOfSets) => listOfSets.every((errorsSet) => errorsSet.isEmpty),
      ),
      (_, isValid) => isValid,
    )
    .share();
```
### 4. Perform login effect based on submit stream
```dart
// Message stream
final message$ = Rx.merge(
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
```
That's all :)

## Getting Started

For help getting started with Flutter, view our online
[documentation](https://flutter.io/).
