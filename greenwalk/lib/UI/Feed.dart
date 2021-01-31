import 'dart:async';
import 'dart:convert';
import '../FlutterBlocs/LocAQIBloc.dart';
import '../FlutterBlocs/TimerBloc.dart';
import '../FlutterBlocs/DataBloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import '../MainViewModel.dart';
import 'Activity.dart';
import '../Entities/ActivityClass.dart';
import 'ActivityDetails.dart';
import 'Home.dart' as home;
import 'Profile.dart';
import 'package:rxdart/rxdart.dart';

class FeedScreen extends StatefulWidget {
  State currentState;
  FlutterLocalNotificationsPlugin fltrNotification;

  FeedScreen(this.fltrNotification);

  @override
  _FeedScreen createState() => currentState = _FeedScreen();
}

class _FeedScreen extends State<FeedScreen> {
  String aqi = "0";
  Stream airData;
  Position userLocation;
  Geolocator locator = Geolocator();
  List<Activity> activities = new List<Activity>();
  SharedPreferences prefs;

  FlutterLocalNotificationsPlugin fltrNotification;
  String _selectedParam;
  String task;
  int val;
  String tip = "";

  void initState() {
    super.initState();
    __init__();

    fltrNotification = widget.fltrNotification;

  }

  Future _showNotification(double _aqi, String _tip) async {
    var androidDetails = new AndroidNotificationDetails(
        "GreenWalk", "GreenWalk AQI Notification", "Tip",
        importance: Importance.max);
    var iSODetails = new IOSNotificationDetails();
    var generalNotificationDetails =
        new NotificationDetails(android: androidDetails, iOS: iSODetails);

    String finalString = "AQI: " + _aqi.toString() + "\n " + _tip;
    fltrNotification.schedule(1, "New Greenwalk Report", finalString,
        DateTime.now().add(Duration(minutes: 15)), generalNotificationDetails);
  }

  void __init__() async {
    prefs = await SharedPreferences.getInstance();
  }

  Widget BuildBody(BuildContext context, MainViewModel vm) {
    final vm = Provider.of<MainViewModel>(context);

    return Container(child: _buildList(context, vm));
  }

  @override
  void dispose() {
    Timerbloc
        .dispose(); // call the dispose method to close our StreamController
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        // Wrap our widget with a StreamBuilder
        stream: AQIbloc.getAQI,
        // pass our Stream getter here
        initialData: LocAQIBlocData(
            null, "0", Color.fromARGB(0, 0, 0, 0), new Position()),
        // provide an initial data
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Container();
          LocAQIBlocData current = snapshot.data;
          _showNotification(current.aqi, current.tip);
          final vm = Provider.of<MainViewModel>(context);

          return Column(
            children: <Widget>[
              Container(
                  margin: const EdgeInsets.all(15.0),
                  padding: const EdgeInsets.all(3.0),
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.blueAccent)),
                  child: Column(children: <Widget>[
                    Text("Current AQI"),
                    current.aqi != null
                        ? Text(
                            current.aqi.toString(),
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: current.color),
                          )
                        : CircularProgressIndicator(),
                    current.aqi != null ? Text(current.tip) : Text("")
                  ])),
              Expanded(
                child: BuildBody(context, vm),
              )
            ],
          );
        } // access the data in our Stream here
        );
  }

  Widget _buildList(BuildContext context, MainViewModel vm) {

    return StreamBuilder(
        // Wrap our widget with a StreamBuilder
        stream: Databloc.getAllPublicActivities,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Container();
          List<Activity> current = snapshot.data;

          final vm = Provider.of<MainViewModel>(context);

          return CustomScrollView(primary: false, slivers: <Widget>[
            SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverGrid.count(
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  crossAxisCount: 2,
                  children: current.map((data) {
                    Color toSelect;
                    if (data.AQI <= 50) {
                      toSelect = Color.fromARGB(100, 16, 204, 10);
                    } else if (data.AQI <= 100 && data.AQI > 50) {
                      toSelect = Color.fromARGB(100, 244, 208, 63);
                    } else if (data.AQI <= 150 && data.AQI > 100) {
                      toSelect = Color.fromARGB(100, 243, 156, 18);
                    } else if (data.AQI <= 200 && data.AQI > 150) {
                      toSelect = Color.fromARGB(100, 231, 76, 60);
                    } else if (data.AQI <= 300 && data.AQI > 200) {
                      toSelect = Color.fromARGB(100, 142, 68, 173);
                    } else if (data.AQI > 300) {
                      toSelect = Color.fromARGB(100, 100, 30, 22);
                    }

                    return GestureDetector(
                      child: _buildListItem(context, data, toSelect),
                      onTap: () {
                        goToDetailsPage(context, data, vm);
                      },
                    );
                  }).toList(),
                ))
          ]);
        });
  }

  goToDetailsPage(BuildContext context, Activity activity, MainViewModel vm) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => ActivityDetails(curActivity: activity, vm: vm)),
    );
  }

  Widget _buildListItem(BuildContext context, Activity data, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Container(
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: Center(
              child: Container(
            child: Column(children: <Widget>[
              Row(children: <Widget>[
                Text("AQI:" + data.AQI.toString(),
                    style: TextStyle(fontWeight: FontWeight.bold))
              ]),
              Row(children: <Widget>[Text(data.date)]),
              Row(children: <Widget>[
                Text(data.distance.toString() + "km"),
              ]),
              Row(children: <Widget>[Text(data.steps.toString() + "Steps")])
            ]),
          ))),
    );
  }


}
