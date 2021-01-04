import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'AQI.dart';
import 'ActivityViewModel.dart';
import 'LocationService.dart';
import 'dart:ui' as ui;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'MainViewModel.dart';
import 'TimerService.dart';
import 'package:http/http.dart' as http;

import 'package:provider/provider.dart';
import 'package:firebase_database/firebase_database.dart';

class Activity {
  DateTime timestamp;
  String type, date;
  int time = 0;
  int steps = 0;
  int AQI;
  double avgSpeed = 0;
  double distance;
  DocumentReference reference;
  List<LatLng> coordinates = List<LatLng>();

  Activity(this.date, this.type);

  Activity.fromMap(Map<String, dynamic> map, {this.reference})
      : assert(map['type'] != null),
        assert(map['date'] != null),
        assert(map['steps'] != null),
        assert(map['AQI'] != null),
        assert(map['time'] != null),
        assert(map['distance'] != null),
        assert(map['avgSpeed'] != null),
        type = map['type'],
        date = map['date'],
        AQI = map['AQI'],
        time = map['time'],
        steps = map['steps'],
        distance = map['distance'].toDouble(),
        avgSpeed = map['avgSpeed'].toDouble();

  Activity.fromSnapshot(DocumentSnapshot snapshot)
      : this.fromMap(snapshot.data(), reference: snapshot.reference);
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////HomeScreen
class ActivityScreen extends StatefulWidget {
  @override
  _ActivityScreen createState() => _ActivityScreen();
}

class _ActivityScreen extends State<ActivityScreen> {
  final model = ActivityViewModel();
  static final CameraPosition initialLocation = CameraPosition(
    target: LatLng(0, 0),
    zoom: 14,
  );

  @override
  void initState() {
    super.initState();
  }

  Completer<GoogleMapController> _controller = Completer();
  Position userLocation;
  Uint8List imageData;

  // this set will hold my markers
  Set<Marker> _markers = {};

  // this will hold the generated polylines
  Set<Polyline> _polylines = {};

  // this will hold each polyline coordinate as Lat and Lng pairs
  List<LatLng> polylineCoordinates = [];

  // this is the key object - the PolylinePoints
  // which generates every polyline between start and finish
  PolylinePoints polylinePoints = PolylinePoints();
  BitmapDescriptor sourceIcon;
  BitmapDescriptor destinationIcon;
  Activity curActivity = Activity("0", "W");
  TimerService timerService = TimerService();
  Timer apiTimer;

  String aqi = "0";
  Stream airData;

  int currentSteps;
  final firestoreInstance = FirebaseFirestore.instance;


  void setSourceAndDestinationIcons() async {
    sourceIcon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(devicePixelRatio: 2.5), 'images/user.png');
    destinationIcon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(devicePixelRatio: 2.5), 'images/user.png');
  }

  Future<void> __init__() async {

    await setSourceAndDestinationIcons();
  }

  void onMapCreated(GoogleMapController controller) {
    _controller.complete(controller);
  }

  void setMapPins() {
    setState(() {
      _markers.add(Marker(
          markerId: MarkerId('sourcePin'),
          position: LatLng(curActivity.coordinates.first.latitude,
              curActivity.coordinates.first.longitude),
          icon: sourceIcon));
      // destination pin
      _markers.add(Marker(
          markerId: MarkerId('destPin'),
          position: LatLng(curActivity.coordinates.last.latitude,
              curActivity.coordinates.last.longitude),
          icon: destinationIcon));
    });
  }

  setPolylines() async {
    setState(() {
      // create a Polyline instance
      // with an id, an RGB color and the list of LatLng pairs
      Polyline polyline = Polyline(
          polylineId: PolylineId("Polyline"),
          color: Color.fromARGB(255, 40, 122, 198),
          points: curActivity.coordinates);

      // add the constructed polyline as a set of points
      // to the polyline set, which will eventually
      // end up showing up on the map
      _polylines.add(polyline);
    });
  }

  @override
  Widget build(BuildContext context) {
    __init__();
    return ChangeNotifierProvider<ActivityViewModel>(
        create: (BuildContext context) => ActivityViewModel(),
        child: Consumer<ActivityViewModel>(builder: (context, model, child) {
          return Scaffold(
              body: Column(
            children: <Widget>[
              Container(
                height: MediaQuery.of(context).size.height / 3,
                width: MediaQuery.of(context).size.width,
                margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: GoogleMap(
                    myLocationEnabled: true,
                    compassEnabled: true,
                    tiltGesturesEnabled: false,
                    markers: _markers,
                    polylines: _polylines,
                    mapType: MapType.normal,
                    initialCameraPosition: initialLocation,
                    onMapCreated: onMapCreated),
              ),
              Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    IconButton(
                      padding: EdgeInsets.all(5.0),
                      icon: FaIcon(FontAwesomeIcons.play),
                      onPressed: () {
                        DateTime now = DateTime.now();
                        DateFormat formatter =
                            DateFormat('yyyy-MM-dd hh:mm:ss');
                        String formatted = formatter.format(now);
                        curActivity = Activity(formatted, 'W');
                        curActivity.timestamp = now;
                        model.start();
                        curActivity.coordinates = model.locations;
                        curActivity.distance = model.totalDistance;

                        if (model.steps!=null)
                          curActivity.steps = model.steps;
                        timerService.reset();
                        timerService.start();
                        timerService.addListener(() {
                          curActivity.time =
                              timerService.currentDuration.inSeconds;
                          curActivity.avgSpeed = model.totalDistance/(curActivity.time/3600);
                          setMapPins();
                          setPolylines();
                        });
                      },
                    ),
                    IconButton(
                        padding: EdgeInsets.all(5.0),
                        icon: FaIcon(FontAwesomeIcons.pause),
                        onPressed: () {
                          createRecord();
                          setSourceAndDestinationIcons();
                          timerService.stop();
                        }),
                  ]),
              Expanded(
                  child: GridView.count(
                primary: false,
                padding: const EdgeInsets.all(20),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                crossAxisCount: 2,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(8),
                    child: curActivity.steps!=null ? Text(curActivity.steps.toString()) : Text("0") ,
                    color: Colors.teal[100],
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    child: Text(curActivity.time.toString()),
                    color: Colors.teal[200],
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    child: Text(curActivity.avgSpeed.toString()),
                    color: Colors.teal[300],
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    child: Text(curActivity.distance.toString()),
                    color: Colors.teal[400],
                  ),
                ],
              ))
            ],
          ));
        }));
  }


  void createRecord(){
    firestoreInstance.collection('activities').add({
    "type" : curActivity.type,
    "date" : curActivity.date,
    "time" : curActivity.time,
    "steps" : curActivity.steps,
    'distance': curActivity.distance,
    'AQI':50,
    "coordinates" : toList(curActivity.coordinates),
    'avgSpeed':curActivity.avgSpeed
    }).then((value){
    print(value.id);
    });


  }
  List<Map<String,double>> toList(List<LatLng> locations) {
    Map<int, LatLng> coords = locations.asMap();
    List<Map<String,double>> list = new List< Map<String,double>>();
    for(int index in coords.keys ){
        var c = {'lat':coords[index].latitude, 'lng':coords[index].longitude};
        list.insert(index, c);
    }
    return list;
  }

}
