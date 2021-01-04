import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'activity_functions.dart';
import 'activity.dart';

class ProfileScreen extends StatefulWidget {
  ProfileScreen({Key key}) : super(key: key);

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<ProfileScreen> {
  User1 currentUser;

  @override
  void initState() {
    currentUser = new User1(email:"pedromarques@gmail.com",password:"123456", username:"Pedro", gender:"M");
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          SizedBox(height: 20),
          AnimatedSwitcher(
            duration: Duration(milliseconds: 750),
            transitionBuilder: (Widget child, Animation<double> animation) => SlideTransition(
              child: child,
              position: Tween<Offset>(begin: Offset(0.0, 1.0), end: Offset(0.0, 0.0)).animate(animation),
            ),
            child: HeaderSection(
              profile: currentUser,
            ),
          ),
          Expanded(
            child: BuildBody(context),
          )
         ]
      ),
    );
  }
}



class HeaderSection extends StatelessWidget {
  final User1 profile;
  const HeaderSection({
    Key key,
    this.profile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: <Widget>[
          Container(
            height: 110,
            width: 100,

            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),

              image: DecorationImage(image: AssetImage('images/user.png'), fit: BoxFit.cover)
            ),
          ),
          SizedBox(height: 20),
          Container(
            alignment: Alignment.center,
            child: Text(
              profile.username,
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
            ),
          ),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 20),
            alignment: Alignment.center,
            child: Text(
              profile.email,
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 20),
          Container(
            alignment: Alignment.center,
            child: Text(
                profile.gender== "M" ? "Male" : "Female",
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class User1 {
  String email, username, password, gender;
  User1({this.email, this.password, this.username, this.gender});

  factory User1.fromJson(Map<String, dynamic> responseData) {
    return User1(
        email: responseData['email'],
        password: responseData['password'],
        username:responseData['username'],
        gender: responseData['gender']
    );
  }
}