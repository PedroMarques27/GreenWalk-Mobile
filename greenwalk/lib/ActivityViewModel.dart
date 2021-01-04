import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mvvm/mvvm.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'AQI.dart';
import 'LocationService.dart';
import 'package:http/http.dart' as http;


class ActivityViewModel extends ChangeNotifier {

  double totalDistance;

  Position currentLocation;
  AirData currentAirData;
  Stream<Position> locationStream = LocationService().locationStream;
  List<LatLng> locations = List();
  List<AirData> airData = List();
  Stream<StepCount> _stepCountStream;
  int steps ;
  DateTime timestamp;
  Timer scheduler;
  bool recording = false;
  Future<void> start() async {
    recording = true;
    steps = 0;
    totalDistance = 0;
    timestamp = DateTime.now();
    initPlatformState();
    locationStream.listen((position) {
      if (recording){
        locations.add(LatLng(position.latitude, position.longitude));
        notifyListeners();
      }

    });

    scheduler = Timer.periodic(new Duration(seconds: 45), (timer) {
      fetchAQI().then((value){
        airData.add(value);
        notifyListeners();
      });
    });
  }


  void onStepCount(StepCount event) {
    if (recording){
      if (steps == 0){
        steps = event.steps;
      }
      if (event.timeStamp.isAfter(timestamp)){
        int toAdd = event.steps-steps;
        steps = toAdd;
      }
      calculateDistance(steps);

      notifyListeners();
    }


  }

  Future<double> calculateDistance(int count) async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (count == 0){
      totalDistance= 0;
    }else{
      switch(prefs.getString('gender')) {
        case 'F':
          totalDistance = (count * 70) / 100000;
          break;
        case 'M':
          totalDistance = (count * 78) /100000;
          break;

      }
    }


  }

  void onStepCountError(error) {
    print('onStepCountError: $error');
    steps = 0;
  }

  void initPlatformState() {
    debugPrint("Initialized Step Count");
    _stepCountStream = Pedometer.stepCountStream;
    _stepCountStream.listen(onStepCount).onError(onStepCountError);

  }

  void stop(){
    scheduler.cancel();
    recording = false;
  }


  Future<AirData> fetchAQI() async {
    String latitude = currentLocation.latitude.toString();
    String longitude = currentLocation.longitude.toString();
    var response =
    await http.get('https://api.weatherbit.io/v2.0/current/airquality?'
        'lat=$latitude&lon=$longitude&key=961c6a4baa7b4f2e92b04cc7ee42354b');
    if (response.statusCode == 200) {
      return AirData.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load AQI Data');
    }
  }



}