import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mvvm/mvvm.dart';
import 'package:path/path.dart';
import 'package:permission_handler/permission_handler.dart';

import 'Entities/AQI.dart';
import 'UI/Activity.dart';
import 'Entities/ActivityClass.dart';
import 'package:http/http.dart' as http;

import 'UI/Profile.dart';


class MainViewModel extends ChangeNotifier {
  final databaseReference = FirebaseDatabase.instance.reference();
  List<Activity> activities = new List<Activity>();

  AirData currentAirData;
  User1 currentUser;

  String tip;
  Color toSelect;

  Future<void> start() async {
    saveToken();
    getTokens();
    currentUser = new User1();
  }

  Future<void> getUser(String email) async {
    var newReference = databaseReference.child('users');
    newReference.once().then((DataSnapshot snapshot) {
      Map<dynamic, dynamic> values = snapshot.value;
      currentUser = User1.fromMap(values[email]);
      currentUser.email = email;
      notifyListeners();
    });
  }
  Future<void> updateUser() async {
    databaseReference.child('users').child(currentUser.email).set({
      'password': currentUser.password,
      'username': currentUser.username,
      'gender': currentUser.gender,
      'image_url':  currentUser.image_url
    });
    notifyListeners();
  }

  Future uploadImageToFirebase(BuildContext context, File _imageFile) async {
    String fileName = basename(_imageFile.path);
    StorageReference firebaseStorageRef =
    FirebaseStorage.instance.ref().child('uploads/$fileName');
    StorageUploadTask uploadTask = firebaseStorageRef.putFile(_imageFile);
    StorageTaskSnapshot taskSnapshot = await uploadTask.onComplete;
    taskSnapshot.ref.getDownloadURL().then((value) {
      currentUser.image_url=value;
      updateUser();
    });
  }

  List<String> tokens = new List<String>();
  Future<List> getTokens() async {
    final databaseReference = FirebaseDatabase.instance.reference();
    var newReference = databaseReference.child('tokens');
    newReference.once().then((DataSnapshot snapshot) {
      debugPrint(snapshot.value.toString() + "----------------------------------------------");
      Map<dynamic, dynamic> values = snapshot.value;
      for (String key in values.keys) {
        tokens.add(key);
      }
      return tokens;
    });
  }
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  void saveToken() async{
    String token = await _firebaseMessaging.getToken();
    final databaseReference = FirebaseDatabase.instance.reference();
    var newReference = databaseReference.child('tokens');
    newReference.set(token);
  }






}