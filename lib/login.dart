import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_flutter/register.dart';

import 'api.dart';
import 'auth.dart';
import 'home.dart';

class LoginPage extends StatefulWidget {
  static String tag = '/login-page';

  @override
  LoginState createState() => new LoginState();
}

class LoginState extends State<LoginPage> {
  final _formKey = new GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  SharedPreferences _sharedPreferences;

  Function decoration = (String text, Icon icon) => InputDecoration(
        prefixIcon: icon,
        hintText: text,
        contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(32.0)),
      );

  final myControllerEmail = TextEditingController();
  final myControllerPassword = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchSessionAndNavigate();

  }

  _fetchSessionAndNavigate() async  {
    _sharedPreferences = await _prefs;
    String authToken = Auth.getToken(_sharedPreferences);
    if(authToken != null) {
      Navigator.of(_scaffoldKey.currentContext).pushReplacementNamed(HomePage.tag);
    }
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    myControllerEmail.dispose();
    myControllerPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build

    final logo = Hero(
      tag: 'hero',
      child: CircleAvatar(
        backgroundColor: Colors.transparent,
        radius: 48.0,
        child: Image.asset('assets/logo.png'),
      ),
    );

    final form = Form(
      key: _formKey,
      child: Column(children: <Widget>[
        TextFormField(
          controller: myControllerEmail,
          keyboardType: TextInputType.emailAddress,
          autofocus: true,
          decoration: decoration(
              "Enter email", new Icon(Icons.email, color: Colors.green)),
          validator: (value) {
            if (value.isEmpty) {
              return 'Please enter your email';
            }
            return null;
          },
        ),
        SizedBox(height: 8.0),
        TextFormField(
          controller: myControllerPassword,
          keyboardType: TextInputType.text,
          autofocus: false,
          obscureText: true,
          decoration: decoration(
              'Enter password', new Icon(Icons.lock, color: Colors.green)),
          validator: (value) {
            if (value.isEmpty) {
              return 'Please enter your password';
            }
            return null;
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: ButtonTheme(
            minWidth: double.infinity,
            child: Builder(
              builder: (context) => RaisedButton(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                onPressed: () {
                  // Validate returns true if the form is valid, or false
                  // otherwise.
                  if (_formKey.currentState.validate()) {
                    String loginRequest = jsonEncode({
                      'email': myControllerEmail.text,
                      'password': myControllerPassword.text
                    });

                    Future<dynamic> response = APIUtil.post(
                        'http://172.31.128.20:4000/api/v1/sign_in',
                        loginRequest);

                    Scaffold.of(context).showSnackBar(
                      SnackBar(
                        content: Container(
                          child: FutureBuilder<dynamic>(
                            future: response,
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                Map<String, dynamic> jwt = jsonDecode(snapshot.data);
                                Auth.setToken(jwt['jwt'], _sharedPreferences);
                                return Text(snapshot.data);
                              } else if (snapshot.hasError) {
                                print('error');
                                return Text("${snapshot.error}");
                              }

                              // By default, show a loading spinner.
                              return new Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [CircularProgressIndicator()]);
                            },
                          ),
                        ),
                      ),
                    );
                  }
                },
                padding: EdgeInsets.all(12),
                color: Colors.green,
                child: Text('Log In', style: TextStyle(color: Colors.white)),
              ),
            ),
          ),
        ),
      ]),
    );

    final registerLabel = FlatButton(
      child: Text(
        'Create a new account',
        style: TextStyle(color: Colors.blue),
      ),
      onPressed: () {
        Navigator.of(context).pushReplacementNamed(RegisterPage.tag);
      },
    );

    return Scaffold(
      key: _scaffoldKey,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(left: 24.0, right: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              logo,
              SizedBox(height: 48.0),
              form,
              new Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [registerLabel])
            ],
          ),
        ),
      ),
    );
  }
}
