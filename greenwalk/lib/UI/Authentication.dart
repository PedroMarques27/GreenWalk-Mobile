import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:greenwalk/FlutterBlocs/DataBloc.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../MainViewModel.dart';

class Authentication extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new _LoginPageState();
}

// Used for controlling whether the user is loggin or creating an account
enum FormType { login, register }

class _LoginPageState extends State<Authentication> {
  final TextEditingController _emailFilter = new TextEditingController();
  final TextEditingController _passwordFilter = new TextEditingController();
  final TextEditingController _usernameFilter = new TextEditingController();
  final DropdownButton _genderFilter = new DropdownButton();
  final databaseReference = FirebaseDatabase.instance.reference();
  Map<dynamic, dynamic> users;
  String _email = "";
  String _password = "";
  String _username = "";
  String gender = "";
  SharedPreferences prefs;
  FormType _form = FormType
      .login; // our default setting is to login, and we should switch to creating an account when the user chooses to

  _LoginPageState() {
    _emailFilter.addListener(_emailListen);
    _passwordFilter.addListener(_passwordListen);
    _usernameFilter.addListener(_usernameListen);

  }


  void __init__() async {
    await getData();
    prefs = await SharedPreferences.getInstance();

  }


  @override
  void initState() {
    __init__();
  }

  void _emailListen() {
    if (_emailFilter.text.isEmpty) {
      _email = "";
    } else {
      _email = _emailFilter.text;
    }
  }

  void _usernameListen() {
    if (_usernameFilter.text.isEmpty) {
      _username = "";
    } else {
      _username = _emailFilter.text;
    }
  }

  void _passwordListen() {
    if (_passwordFilter.text.isEmpty) {
      _password = "";
    } else {
      _password = _passwordFilter.text;
    }
  }

  // Swap in between our two forms, registering and logging in
  void _formChange() async {
    setState(() {
      if (_form == FormType.register) {
        _form = FormType.login;
      } else {
        _form = FormType.register;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: _buildBar(context),
      body: new Container(
        padding: EdgeInsets.all(16.0),
        child: new Column(
          children: <Widget>[
            _buildTextFields(),
            _buildButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildBar(BuildContext context) {
    return new AppBar(
      title: new Text(" Login "),
      centerTitle: true,
      automaticallyImplyLeading: false,
    );
  }

  Widget _buildTextFields() {
    if (_form == FormType.login) {
      return new Container(
        child: new Column(
          children: <Widget>[
            new Container(
              child: new TextField(
                controller: _emailFilter,
                decoration: new InputDecoration(labelText: 'Email'),
              ),
            ),
            new Container(
              child: new TextField(
                controller: _passwordFilter,
                decoration: new InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
            )
          ],
        ),
      );
    } else {
      return new Container(
        child: new Column(
          children: <Widget>[
            new Container(
              child: new TextField(
                controller: _emailFilter,
                decoration: new InputDecoration(labelText: 'Email'),
              ),
            ),
            new Container(
              child: new TextField(
                controller: _usernameFilter,
                decoration: new InputDecoration(labelText: 'Username'),
              ),
            ),
            new DropdownButton<String>(
              items: <String>['Male', 'Female'].map((String value) {
                return new DropdownMenuItem<String>(
                  value: value,
                  child: new Text(value),
                );
              }).toList(),
              onChanged: (value) {

                if (value.startsWith("M")){
                  gender = "M";
                }else{
                  gender = "F";
                }
              },
            ),
            new Container(
              child: new TextField(
                controller: _passwordFilter,
                decoration: new InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
            )
          ],
        ),
      );
    }
  }

  Widget _buildButtons() {

    if (_form == FormType.login) {
      return Center(child: new Container(
        child: new Column(
          children: <Widget>[
            new RaisedButton(
              child: new Text('Login'),
              onPressed: _loginPressed,
            ),
            new FlatButton(
              child: new Text('Tap here to register.'),
              onPressed:  _formChange,
            ),
          ],
        ),
      )
      );
    } else {
      return new Container(
        child: new Column(
          children: <Widget>[
            new RaisedButton(
              child: new Text('Create an Account'),
              onPressed: _createAccountPressed,
            ),
            new FlatButton(
              child: new Text('Click here to login.'),
              onPressed: _formChange,
            )
          ],
        ),
      );
    }
  }

  // These functions can self contain any user auth logic required, they all have access to _email and _password

  void _loginPressed() {
    if (users.containsKey(_email)){
      Map<dynamic, dynamic> userValues = users[_email];
      if (userValues['password']==_password){

        prefs.setString('email', _email);
        prefs.setString('gender', userValues['gender']);
        Databloc.reset();
        Navigator.pop(context, _email);
      }

    }
  }

  void _createAccountPressed() async{
    if (_email.length>4 && _password.length>4 && gender!=null && _username!=null){
      if (!users.containsKey(_email)){
        databaseReference.child('users').child(_email).set({
          'password': _password,
          'gender':gender[0],
          'username':_username
        });
        prefs.setString('email', _email);
        prefs.setString('gender', gender[0]);
        Databloc.reset();
        Navigator.pop(context, _email);
      }

    }

  }

  Future<Map> getData() async{
    var newReference = databaseReference.child('users');
    newReference.once().then((DataSnapshot snapshot) {
      Map<dynamic, dynamic> values = snapshot.value;
      users = values;
      return values;
    });
  }
}
