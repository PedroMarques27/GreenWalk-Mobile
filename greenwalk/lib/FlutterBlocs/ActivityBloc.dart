import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:greenwalk/Entities/LatLng.dart';
import 'package:mvvm/mvvm.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';


import 'package:http/http.dart' as http;

import 'LocAQIBloc.dart';
import 'TimerBloc.dart';


class ActivityBloc {
  Stream<Duration> timerCount = Timerbloc.getTime;
  Stream<LocAQIBlocData> locationWeatherStream = AQIbloc.getAQI;


  StreamController<ActivityDetail> activityStreamController = StreamController<ActivityDetail>.broadcast();
  Stream get getActivityDetail => activityStreamController.stream;

  StreamSubscription<LocAQIBlocData> locAQIsubscription;
  StreamSubscription<Duration> timerSubscription;
  StreamSubscription<StepCount> stepSubscription;

  List<double> airData = List();
  Stream<StepCount> _stepCountStream;

  DateTime timestamp;
  int finalSteps;
  double sum;

  Duration latestTime;
  TrackData latestTrackData;
  LocAQIBlocData latestLocAQIData;


  String gender = "M";
  ActivityBloc() {
    SharedPreferences.getInstance().then((value) {
      gender = value.getString('gender');
    });
    latestTrackData = new TrackData();
    latestTime = new Duration();
    locAQIsubscription = locationWeatherStream.listen((event) {
      latestLocAQIData = event;
      update();
    });
  }

  void update() {
    ActivityDetail latest = new ActivityDetail(latestLocAQIData, latestTrackData);
    activityStreamController.sink.add(latest); // add whatever data we want into the Sink
  }

  void dispose() {
    activityStreamController.close(); // close our StreamController to avoid memory leak
  }


  Future<void> startCapturing() async {
    sum = 0;
    finalSteps = null;
    Timerbloc.reset();
    Timerbloc.start();

    airData.clear();
    timestamp = DateTime.now();
    latestTrackData = new TrackData();
    latestTime = new Duration();
    initPlatformState();
    latestTrackData.locations.add(LatLng(latestLocAQIData.currentPosition.latitude, latestLocAQIData.currentPosition.longitude));
    update();

    locAQIsubscription = locationWeatherStream.listen((event) {
      latestLocAQIData = event;
      latestTrackData.locations.add(LatLng(latestLocAQIData.currentPosition.latitude, latestLocAQIData.currentPosition.longitude));
      debugPrint(latestTrackData.locations.toString());
      airData.add(latestLocAQIData.aqi);
      sum+=latestLocAQIData.aqi;
      latestTrackData.avgAQI = (sum/airData.length).floor();
      update();
    });
    timerSubscription = timerCount.listen((event) {
      latestTrackData.latestTime = event;
      update();
    });

  }
  void stop(){
    stepSubscription.cancel();
    timerSubscription.cancel();
    locAQIsubscription.cancel();
  }


  void onStepCountError(error) {
    print('onStepCountError: $error');
    latestTrackData.steps = 0;
  }

  void initPlatformState() {
    debugPrint("Initialized Step Count");
    _stepCountStream = Pedometer.stepCountStream;
    stepSubscription = _stepCountStream.listen(onStepCount);
    stepSubscription.onError(onStepCountError);

  }
  void onStepCount(StepCount event) {

    if (finalSteps == null){
      finalSteps = event.steps;
    }
    if (event.timeStamp.isAfter(timestamp)){
      latestTrackData.steps = event.steps-finalSteps;
    }
    calculateDistance(latestTrackData.steps);



  }

  calculateDistance(int count){
    if (count == 0){
      latestTrackData.totalDistance= 0;
    }else{
      switch(gender) {
        case 'F':
          latestTrackData.totalDistance = (count * 70) / 100000;
          break;
        case 'M':
          latestTrackData.totalDistance = (count * 78) /100000;

          break;

      }
    }
    double speed =  latestTrackData.totalDistance /
        (latestTrackData.latestTime.inSeconds / 3600);
    latestTrackData.avgSpeed = double.parse(
        speed.toStringAsFixed(2));


    latestTrackData.totalDistance = double.parse(latestTrackData.totalDistance.toStringAsFixed(2));
  }


}

final Activitybloc = ActivityBloc();


class ActivityDetail{
  LocAQIBlocData locAQIBlocData;
  TrackData trackData;

  ActivityDetail(this.locAQIBlocData, this.trackData);
}

class TrackData {
  double totalDistance = 0;
  int steps = 0;
  int avgAQI = 0;
  double avgSpeed = 0;
  Duration latestTime = new Duration();
  List<LatLng> locations = List();
  TrackData();
}
