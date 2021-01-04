import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mvvm/mvvm.dart';
import 'package:permission_handler/permission_handler.dart';

import 'AQI.dart';
import 'LocationService.dart';
import 'package:http/http.dart' as http;


class MainViewModel extends ChangeNotifier {


  Position currentLocation;
  AirData currentAirData;
  Stream<Position> locationStream = LocationService().locationStream;
  Future<void> start() async {
    await requestLocationPermission();
    await requestActivityRecognitionPermission();
    locationStream.listen((position) {
      if (currentLocation == null){
        currentLocation = position;
        fetchAQI().then((value){
          currentAirData = value;

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

  Future<bool> requestActivityRecognitionPermission({Function onPermissionDenied}) async {
    var granted = await _requestPermission(PermissionGroup.activityRecognition);
    if (granted != true) {
      requestActivityRecognitionPermission();
    }
    debugPrint('requestActivityRecognitionPermission $granted');
    return granted;
  }

  Future<AirData> fetchAQI() async {
    debugPrint("CALLED ------------------------------------------------"+currentLocation.toString());
    String latitude = currentLocation.latitude.toString();
    String longitude = currentLocation.longitude.toString();
    var response =
    await http.get('https://api.weatherbit.io/v2.0/current/airquality?'
        'lat=$latitude&lon=$longitude&key=961c6a4baa7b4f2e92b04cc7ee42354b');
    debugPrint("CALLED ------------------------------------------------");
    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      debugPrint("......................AQI"+response.toString());
      return AirData.fromJson(jsonDecode(response.body));

    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Failed to load AQI Data');
    }
  }


}