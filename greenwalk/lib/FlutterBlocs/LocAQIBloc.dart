import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../Entities/AQI.dart';
import 'package:http/http.dart' as http;

class AQIBloc {

  StreamController<LocAQIBlocData> aqiStreamController = StreamController<LocAQIBlocData>.broadcast();
  Stream get getAQI => aqiStreamController.stream;

  AirData currentAirData;
  int AQI;
  String tip;
  Color toSelect;
  Stream<Position> locationStream;
  Timer _taskTimer;
  Geolocator location = Geolocator();
  Position currentPosition = new Position();

  AQIBloc(){
    bool isValueNull = true;;


    location.checkGeolocationPermissionStatus().then((granted) {
      if (true) {
        // If granted listen to the onLocationChanged stream and emit over our controller
        location.getPositionStream().listen((position) {
          if (position != null) {
            currentPosition = position;
            update();
            if (isValueNull){
              startFetchingAQI();
              isValueNull=false;
            }

          }
        });
      }
    });

  }
  void startFetchingAQI(){

    fetchAQI().then((value){
      currentAirData = value;
      update();
      Timer.periodic(new Duration(seconds: 45), (timer) {
        _taskTimer = timer;
        fetchAQI().then((value){
          currentAirData = value;
          update();
        });
      });
    });

  }

  Future<AirData> fetchAQI() async {
    String latitude = currentPosition.latitude.toString();
    String longitude = currentPosition.longitude.toString();
    var response =
    await http.get('https://api.weatherbit.io/v2.0/current/airquality?'
        'lat=$latitude&lon=$longitude&key=d367b455453f495d88622c24e902bc4e');
    debugPrint('https://api.weatherbit.io/v2.0/current/airquality?'
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
        toSelect = Color.fromARGB(100, 142, 68, 73);
      }
      update();

      return AirData.fromJson(jsonDecode(response.body));

    } else {
      throw Exception('Failed to load AQI Data');
    }
  }

  void update() {
    LocAQIBlocData temp;
    if (currentAirData==null)
      temp = new LocAQIBlocData(0,"0",Color.fromARGB(0,0,0,0), currentPosition);
    else{
      temp = new LocAQIBlocData(currentAirData.data.last.aqi, tip, toSelect, currentPosition);
    }

    aqiStreamController.sink.add(temp); // add whatever data we want into the Sink
  }



}

final AQIbloc = AQIBloc(); // create an instance of the counter bloc

class LocAQIBlocData {
  double aqi;
  String tip;
  Color color;
  Position currentPosition;

  LocAQIBlocData(this.aqi, this.tip, this.color, this.currentPosition);

  }

