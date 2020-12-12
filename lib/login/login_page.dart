import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_disposebag/flutter_disposebag.dart';
import 'package:pedantic/pedantic.dart';

import '../api/api.dart';
import '../ext.dart';
import '../login/login_bloc.dart';
import '../login/login_contract.dart';
import '../login/login_interactor_impl.dart';
import '../validator.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with DisposeBagMixin<LoginPage> {
  late final LoginBloc loginBloc = LoginBloc(
    LoginInteractorImpl(LoginApi()),
    const Validator(),
  );

  late final Future<bool> listen =
      loginBloc.message$.listen(_handleLoginMessage).disposedBy(bag);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final _ =
        listen; // do not remove this line, it triggers lazy variable valuation.
  }

  @override
  void dispose() {
    super.dispose();
    loginBloc.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const sizedBox = SizedBox(height: 24.0);

    return Scaffold(
      appBar: AppBar(
        title: Text('Validation form BLoC'),
      ),
      body: Container(
        constraints: const BoxConstraints.expand(),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              Color(0xff243b55),
              Color(0xff141e30),
            ],
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  FlutterLogo(
                    size: 96,
                    duration: Duration(seconds: 3),
                    curve: Curves.easeInOut,
                  ),
                  _buildEmailField(),
                  _buildPasswordField(),
                  sizedBox,
                  _buildLoadingIndicator(),
                  sizedBox,
                  _buildLoginButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      child: RaisedButton(
        padding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        elevation: 8,
        splashColor: Colors.cyanAccent.shade100,
        color: Colors.cyan.shade400,
        child: Text('Login'),
        onPressed: loginBloc.submitLogin,
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return StreamBuilder<bool>(
      stream: loginBloc.isLoading$,
      initialData: loginBloc.isLoading$.value,
      builder: (context, snapshot) {
        return Opacity(
          opacity: snapshot.requireData ? 1.0 : 0.0,
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  Widget _buildPasswordField() {
    return StreamBuilder<Set<ValidationError>>(
      stream: loginBloc.passwordError$,
      builder: (context, snapshot) {
        return TextField(
          keyboardType: TextInputType.text,
          obscureText: true,
          maxLines: 1,
          onChanged: loginBloc.passwordChanged,
          decoration: InputDecoration(
            errorText: _getMessage(snapshot.data),
            labelText: 'Password',
          ),
          textInputAction: TextInputAction.done,
        );
      },
    );
  }

  Widget _buildEmailField() {
    return StreamBuilder<Set<ValidationError>>(
      stream: loginBloc.emailError$,
      builder: (context, snapshot) {
        return TextField(
          keyboardType: TextInputType.emailAddress,
          maxLines: 1,
          onChanged: loginBloc.emailChanged,
          decoration: InputDecoration(
            errorText: _getMessage(snapshot.data),
            labelText: 'Email',
          ),
          textInputAction: TextInputAction.next,
        );
      },
    );
  }

  /// Here, we can show SnackBar or navigate to other page based on [message]
  void _handleLoginMessage(LoginMessage message) async {
    if (message is LoginSuccessMessage) {
      showSnackBar('Sign in successfully');

      await Future.delayed(const Duration(seconds: 2));
      return unawaited(
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage(message.token)),
        ),
      );
    }
    if (message is LoginErrorMessage) {
      return showSnackBar(message.error.toString());
    }
    if (message is InvalidInformationMessage) {
      return showSnackBar('Invalid information');
    }
  }

  /// Here, we can return localized description from [errors]
  static String? _getMessage(Set<ValidationError>? errors) {
    if (errors == null || errors.isEmpty) {
      return null;
    }
    if (errors.contains(ValidationError.invalidEmail)) {
      return 'Invalid email address';
    }
    if (errors.contains(ValidationError.tooShortPassword)) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }
}

class HomePage extends StatelessWidget {
  final String token;

  const HomePage(this.token);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home page'),
      ),
      body: Center(
        child: Text(
          token,
          style: Theme.of(context).textTheme.bodyText2,
        ),
      ),
    );
  }
}
