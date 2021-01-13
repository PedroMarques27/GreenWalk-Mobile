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

  double totalDistance = 0;

  Position currentLocation;
  AirData currentAirData;
  Stream<Position> locationStream = LocationService().locationStream;
  List<LatLng> locations = List();
  List<AirData> airData = List();
  Stream<StepCount> _stepCountStream;
  int steps ;
  DateTime timestamp;
  Timer scheduler;
  int AQI;
  int finalSteps;
  bool recording = false;


  Future<void> start() async {
    recording = true;
    finalSteps = null;
    steps = 0;
    AQI = 0;
    totalDistance = 0;
    airData.clear();
    timestamp = DateTime.now();
    initPlatformState();
    locationStream.listen((position) {
      if (recording){
        currentLocation = position;
        locations.add(LatLng(position.latitude, position.longitude));
        notifyListeners();
        fetchAQI().then((value){
          airData.add(value);
          AQI = value.data.last.aqi.toInt();
          notifyListeners();
        });
      }

    });

    scheduler = Timer.periodic(new Duration(seconds: 45), (timer) {
      fetchAQI().then((value){
        airData.add(value);
        int sum = 0;

        for (AirData air in airData){
          sum+=air.data.last.aqi.toInt();
        }
        AQI = (sum/airData.length).floor();
        notifyListeners();
      });
    });
  }


  void onStepCount(StepCount event) {
    if (recording){
      if (finalSteps == null){
        finalSteps = event.steps;
      }
      if (event.timeStamp.isAfter(timestamp)){
        steps = event.steps-finalSteps;
        notifyListeners();
      }
      calculateDistance(steps);
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
    totalDistance = double.parse(totalDistance.toStringAsFixed(2));
    notifyListeners();

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
        'lat=$latitude&lon=$longitude&key=d367b455453f495d88622c24e902bc4e');
    if (response.statusCode == 200) {
      return AirData.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load AQI Data');
    }
  }



}