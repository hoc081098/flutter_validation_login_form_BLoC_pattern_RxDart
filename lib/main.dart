import 'dart:async';

import 'package:flutter/material.dart';
import 'package:validation_form_bloc/api.dart';
import 'package:validation_form_bloc/bloc.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter BLoC login form',
      theme: ThemeData.dark(),
      home: LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  LoginBloc _loginBloc;
  StreamSubscription _subscription;

  @override
  void initState() {
    super.initState();

    _loginBloc = LoginBloc(LoginApi());
    _subscription = _loginBloc.message$.listen(_handleLoginMessage);
  }

  _handleLoginMessage(LoginMessage message) async {
    if (message is LoginSuccessMessage) {
      await _showSnackBar('Sign in successfully');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage(message.token)),
      );
    } else if (message is LoginErrorMessage) {
      _showSnackBar(message.error.toString());
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    _loginBloc.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const sizedBox = SizedBox(height: 24.0);

    return Scaffold(
      key: _scaffoldKey,
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
    return Container(
      width: double.infinity,
      child: StreamBuilder<bool>(
        initialData: _loginBloc.isValidSubmit$.value,
        stream: _loginBloc.isValidSubmit$,
        builder: (context, snapshot) {
          return RaisedButton(
            padding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            elevation: 8,
            splashColor: Colors.cyanAccent.shade100,
            color: Colors.cyan.shade400,
            child: Text('Login'),
            onPressed: snapshot.data ? _loginBloc.submitLogin : null,
          );
        },
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return StreamBuilder<bool>(
      stream: _loginBloc.isLoading$,
      initialData: _loginBloc.isLoading$.value,
      builder: (context, snapshot) {
        return Opacity(
          opacity: snapshot.data ? 1.0 : 0.0,
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  Widget _buildPasswordField() {
    return StreamBuilder<String>(
      stream: _loginBloc.passwordError$,
      builder: (context, snapshot) {
        return TextField(
          keyboardType: TextInputType.text,
          obscureText: true,
          maxLines: 1,
          onChanged: _loginBloc.passwordChanged,
          decoration: InputDecoration(
            errorText: snapshot.data,
            labelText: 'Password',
          ),
        );
      },
    );
  }

  Widget _buildEmailField() {
    return StreamBuilder<String>(
      stream: _loginBloc.emailError$,
      builder: (context, snapshot) {
        return TextField(
          keyboardType: TextInputType.emailAddress,
          maxLines: 1,
          onChanged: _loginBloc.emailChanged,
          decoration: InputDecoration(
            errorText: snapshot.data,
            labelText: 'Email',
          ),
        );
      },
    );
  }

  Future<void> _showSnackBar(String msg) {
    return _scaffoldKey.currentState
        ?.showSnackBar(
          SnackBar(
            content: Text(msg),
            duration: const Duration(seconds: 2),
          ),
        )
        ?.closed;
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
          style: Theme.of(context).textTheme.body1,
        ),
      ),
    );
  }
}
