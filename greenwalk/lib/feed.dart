import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'LocationService.dart';
import 'MainViewModel.dart';
import 'activity.dart';
import 'activity_functions.dart';
import 'AQI.dart';
import 'Home.dart';
class FeedScreen extends StatefulWidget{
  State currentState;
  @override
  _FeedScreen createState() => currentState = _FeedScreen();
}
class _FeedScreen extends State<FeedScreen> {
  String aqi = "0";
  Stream airData;
  Stream<Position> locationStream = LocationService().locationStream;
  Position userLocation;
  Geolocator locator = Geolocator();
  String description="Current AQI";
  void initState() {
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<MainViewModel>(context);
    return Column(
      children: <Widget>[
        Container(
            margin: const EdgeInsets.all(15.0),
            padding: const EdgeInsets.all(3.0),
            decoration: BoxDecoration(
                border: Border.all(color: Colors.blueAccent)
            ),
            child:Column(children:<Widget> [
              Text("Current AQI"),
              vm.currentAirData!=null ?  Text(vm.currentAirData.data.first.aqi.toString()) : Text("Loading..."),
            ])
        ),

        Expanded(
          child: BuildBody(context),
        )
      ],
    );
  }

}
