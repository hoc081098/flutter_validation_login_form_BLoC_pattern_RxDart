import 'dart:async';

import 'package:flutter/material.dart';
import 'package:validation_form_bloc/bloc.dart';
import 'package:validation_form_bloc/model.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
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
  final _api = Api();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  Bloc _bloc;
  StreamSubscription<Response> _subscription;

  @override
  void initState() {
    super.initState();
    _bloc = Bloc(_api);
    _subscription = _bloc.results.listen(_handleResponse);
  }

  _handleResponse(Response response) {
    if (response is SuccessResponse) {
      _showSnackBar('Sign in successfully').closed.then((_) {
        final route = MaterialPageRoute(
          builder: (BuildContext context) => HomePage(response.token),
        );
        Navigator.push(context, route);
      });
      return;
    }
    if (response is ErrorResponse) {
      _showSnackBar(response.error.toString());
    }
  }

  @override
  void dispose() {
    super.dispose();
    _subscription.cancel();
    _bloc.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sizedBox = SizedBox(height: 24.0);
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Validation form BLoC'),
      ),
      body: new Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              Colors.purple.withOpacity(0.8),
              Colors.teal.withOpacity(0.6),
            ],
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
          ),
        ),
        child: Center(
          child: new SingleChildScrollView(
            child: new Padding(
              padding: const EdgeInsets.all(8.0),
              child: new Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
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
    return new Container(
      constraints: new BoxConstraints.expand(
        height: 48.0,
        width: double.infinity,
      ),
      child: Material(
        borderRadius: BorderRadius.all(Radius.circular(24.0)),
        shadowColor: Theme.of(context).accentColor,
        child: new StreamBuilder<bool>(
          stream: _bloc.validSubmit,
          builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
            debugPrint('Call builder');
            return MaterialButton(
              splashColor: Colors.white70,
              color: Colors.lightBlueAccent.shade400,
              child: Text('Login'),
              onPressed: snapshot.data ? _bloc.submitLogin : null,
            );
          },
        ),
        elevation: 4.0,
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return StreamBuilder<bool>(
      stream: _bloc.isLoading,
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        debugPrint('Call builder');
        return Opacity(
          opacity: snapshot.data ? 1.0 : 0.0,
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  Widget _buildPasswordField() {
    return StreamBuilder<String>(
      stream: _bloc.passwordStream,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        debugPrint('Call builder');
        return TextField(
          keyboardType: TextInputType.text,
          obscureText: true,
          maxLines: 1,
          onChanged: _bloc.passwordChanged,
          decoration: InputDecoration(
            errorText: snapshot.error,
            labelText: 'Password',
          ),
        );
      },
    );
  }

  Widget _buildEmailField() {
    return StreamBuilder<String>(
      stream: _bloc.emailStream,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        debugPrint('Call builder');
        return TextField(
          keyboardType: TextInputType.emailAddress,
          maxLines: 1,
          onChanged: _bloc.emailChanged,
          decoration: InputDecoration(
            errorText: snapshot.error,
            labelText: 'Email',
          ),
        );
      },
    );
  }

  _showSnackBar(String msg) =>
      _scaffoldKey.currentState?.showSnackBar(SnackBar(content: Text(msg)));
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
