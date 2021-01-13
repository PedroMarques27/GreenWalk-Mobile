import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mvvm/mvvm.dart';
import 'package:path/path.dart';
import 'package:permission_handler/permission_handler.dart';

import 'AQI.dart';
import 'Activity.dart';
import 'LocationService.dart';
import 'package:http/http.dart' as http;

import 'Profile.dart';


class MainViewModel extends ChangeNotifier {
  final databaseReference = FirebaseDatabase.instance.reference();
  List<Activity> activities = new List<Activity>();
  Position currentLocation;
  AirData currentAirData;
  User1 currentUser;
  int AQI;
  String tip;
  Color toSelect;

  Stream<Position> locationStream = LocationService().locationStream;
  Future<void> start() async {
    getTokens();
    currentUser = new User1();
    AQI = 0;
    getData();
    locationStream.listen((position) {
      if (currentLocation == null){
        currentLocation = position;
        notifyListeners();
        fetchAQI().then((value){
          currentAirData = value;
          AQI = currentAirData.data.last.aqi.toInt();
          notifyListeners();
        });
      }else{
        currentLocation = position;
      }
    });
    Timer.periodic(new Duration(seconds: 45), (timer) {
      fetchAQI().then((value){
        currentAirData = value;
        notifyListeners();
      });
    });

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
  Future<void> getData() async {
    final databaseReference = FirebaseDatabase.instance.reference();
    var newReference = databaseReference.child('activities');
    List<Activity> acs = new List<Activity>();
    newReference.once().then((DataSnapshot snapshot) {

      Map<dynamic, dynamic> values = snapshot.value;
      for (String key in values.keys) {
        Map<dynamic, dynamic> o = values[key];
        Activity cur = Activity.fromMap(o);
        cur.id = key;
        acs.add(cur);
      }
      activities = acs;
      notifyListeners();
    });
  }
  List<String> tokens = new List<String>();
  Future<List> getTokens() async {
    final databaseReference = FirebaseDatabase.instance.reference();
    var newReference = databaseReference.child('tokens');
    newReference.once().then((DataSnapshot snapshot) {
      Map<dynamic, dynamic> values = snapshot.value;
      for (String key in values.keys) {
        tokens.add(key);
      }
      return tokens;
    });
  }




  Future<bool> _requestPermission(PermissionGroup permission) async {
    final PermissionHandler _permissionHandler = PermissionHandler();
    var result = await _permissionHandler.requestPermissions([permission]);
    if (result[permission] == PermissionStatus.granted) {
      return true;
    }
    return false;
  }

/*Checking if your App has been Given Permission*/
  Future<bool> requestLocationPermission({Function onPermissionDenied}) async {
    var granted = await _requestPermission(PermissionGroup.locationAlways);
    if (granted != true) {
      requestLocationPermission();
    }
    debugPrint('requestContactsPermission $granted');
    return granted;
  }
  /*Checking if your App has been Given Permission*/
  Future<bool> requestCameraPermission({Function onPermissionDenied}) async {
    var granted = await _requestPermission(PermissionGroup.camera);
    if (granted != true) {
      requestCameraPermission();
    }
    debugPrint('requestCameraPermission $granted');
    return granted;
  }


  Future<bool> requestActivityRecognitionPermission({Function onPermissionDenied}) async {
    var granted = await _requestPermission(PermissionGroup.activityRecognition);
    if (granted != true) {
      requestActivityRecognitionPermission();
    }
    debugPrint('requestActivityRecognitionPermission $granted');
    return granted;
  }

  Future<AirData> fetchAQI() async {
    String latitude = currentLocation.latitude.toString();
    String longitude = currentLocation.longitude.toString();
    var response =
    await http.get('https://api.weatherbit.io/v2.0/current/airquality?'
        'lat=$latitude&lon=$longitude&key=d367b455453f495d88622c24e902bc4e');
    if (response.statusCode == 200) {
      AirData airData = AirData.fromJson(jsonDecode(response.body));
      double aqi = airData.data.last.aqi;
      if (aqi <= 50) {
        tip=("Air quality is considered  satisfactory and air pollution poses little or no risk");
        toSelect =  Color.fromARGB(100, 16, 204, 10);
      } else if (aqi <= 100 && aqi > 50) {
        tip=("Air quality is acceptable; However, for some pollutants, there may be a moderate health concern for a very small number of people who are unusually sensitive to air pollution");
        toSelect = Color.fromARGB(100, 244, 208, 63);
      } else if (aqi <= 150 && aqi > 100) {
        tip=("Members of sensitive groups may experience health effects. The general public is not likely to be affected");
        toSelect = Color.fromARGB(100, 243, 156, 18);
      } else if (aqi <= 200 && aqi > 150) {
        tip=("Everyone may begin to experience health effects; members of sensitive groups may experience more serious health effects");
        toSelect = Color.fromARGB(100, 231, 76, 60);
      } else if (aqi <= 300 && aqi > 200) {
        tip=("Health alert: everyone may experience more serious health effects");
        toSelect = Color.fromARGB(100, 142, 68, 173);
      } else if (aqi > 300) {
        tip=("Health Warnings of emergency conditions. The entire population is more likely to be affected");
      }

      return AirData.fromJson(jsonDecode(response.body));

    } else {
      throw Exception('Failed to load AQI Data');
    }
  }


}