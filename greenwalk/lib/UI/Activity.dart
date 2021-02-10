import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:greenwalk/Entities/User.dart';
import 'package:rxdart/rxdart.dart';
import '../Entities/LatLng.dart' as ll;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';

import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import '../Entities/ActivityClass.dart';
import '../FlutterBlocs/LocAQIBloc.dart';
import '../FlutterBlocs/ActivityBloc.dart';
import '../FlutterBlocs/DataBloc.dart';
import '../MainViewModel.dart';
import 'Profile.dart';
import 'package:http/http.dart' as http;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:firebase_database/firebase_database.dart';

import 'dart:ui' as ui;



class ActivityScreen extends StatefulWidget {
  @override
  _ActivityScreen createState() => _ActivityScreen();
}

class _ActivityScreen extends State<ActivityScreen> {

  CameraPosition initialLocation = CameraPosition(
    target: new LatLng(0, 0),
    zoom: 14,
  );

  @override
  void initState() {
    super.initState();
  }

  List<String> tokens = new List<String>();
  Completer<GoogleMapController> _controller = Completer();
  Position userLocation;
  Uint8List imageData;

  // this set will hold my markers
  Set<Marker> _markers = {};

  // this will hold the generated polylines
  Set<Polyline> _polylines = {};
  String token;

  // this will hold each polyline coordinate as Lat and Lng pairs
  List<LatLng> polylineCoordinates = [];
  User1 currentUser;

  // this is the key object - the PolylinePoints
  // which generates every polyline between start and finish
  PolylinePoints polylinePoints = PolylinePoints();
  BitmapDescriptor sourceIcon;
  BitmapDescriptor destinationIcon;
  Activity curActivity = Activity("0");
  Timer apiTimer;

  SharedPreferences prefs;
  final databaseReference = FirebaseDatabase.instance.reference();
  String aqi = "0";

  int currentSteps;
  final firestoreInstance = FirebaseFirestore.instance;

  void setSourceAndDestinationIcons() async {
    final iconData = Icons.pin_drop;
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final textPainter = TextPainter(textDirection: ui.TextDirection.ltr);
    final iconStr = String.fromCharCode(iconData.codePoint);
    textPainter.text = TextSpan(
        text: iconStr,
        style: TextStyle(
          letterSpacing: 0.0,
          fontSize: 100.0,
          fontFamily: iconData.fontFamily,
          color: Colors.green[300],
        ));
    textPainter.layout();
    textPainter.paint(canvas, Offset(0.0, 0.0));
    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(80, 80);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    sourceIcon = BitmapDescriptor.fromBytes(bytes.buffer.asUint8List());
  }

  Future<void> __init__() async {
    token = await _firebaseMessaging.getToken();

    prefs = await SharedPreferences.getInstance();
  }

  void onMapCreated(GoogleMapController controller) {
    _controller.complete(controller);
  }

  Future<void> setMapPins() async {

  }



  int AQI = 0;

  StreamSubscription mapMarkerSub;
  @override
  Widget build(BuildContext context) {
    setSourceAndDestinationIcons();
    __init__();
    var size = MediaQuery.of(context).size;
    final double itemHeight = (size.height - kToolbarHeight - 24) / 2;
    final double itemWidth = size.width / 2;
    final vm = Provider.of<MainViewModel>(context);
    currentUser = vm.currentUser;
    bool isPrivate = curActivity.isPrivate;
    bool isRecording = false;



          return Scaffold(
              body: StreamBuilder(
                        stream: Activitybloc.getActivityDetail,
                        builder: (context, snapshot) {

                          if (!snapshot.hasData) return Container();
                          ActivityDetail details = snapshot.data;
                          initialLocation = CameraPosition(
                            target: LatLng(details.locAQIBlocData.currentPosition.latitude, details.locAQIBlocData.currentPosition.longitude),
                            zoom: 14,
                          );
                          return Column(
                            children: <Widget>[
                              Container(
                                height: MediaQuery.of(context).size.height / 3,
                                width: MediaQuery.of(context).size.width,
                                margin: EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
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
                                    Switch(
                                        value: isPrivate,
                                        onChanged: (value) {
                                          setState(() {
                                            isPrivate = value;
                                            if (curActivity != null)
                                              curActivity.isPrivate = value;

                                            final snackBar = SnackBar(
                                                content: value == true
                                                    ? Text("Private")
                                                    : Text("Public"));
                                            Scaffold.of(context)
                                                .showSnackBar(snackBar);
                                          });
                                        }),
                                    IconButton(
                                      padding: EdgeInsets.all(5.0),
                                      icon: FaIcon(FontAwesomeIcons.play),
                                      onPressed: () {
                                        DateTime now = DateTime.now();
                                        DateFormat formatter =
                                            DateFormat('yyyy-MM-dd hh:mm');
                                        String formatted =
                                            formatter.format(now);
                                        curActivity = Activity(formatted);
                                        isRecording = true;
                                        curActivity.avgSpeed=0;
                                        Activitybloc.startCapturing();
                                        curActivity.isPrivate = isPrivate;
                                        curActivity.time = details.trackData.latestTime.inSeconds;
                                        curActivity.coordinates = [];

                                        curActivity.distance = details.trackData.totalDistance;
                                        curActivity.steps = details.trackData.steps;
                                        curActivity.AQI = details.trackData.avgAQI;


                                        Stream stream = Activitybloc.getActivityDetail;



                                        mapMarkerSub = stream.listen((event) {
                                          curActivity.coordinates.addAll(event.trackData.locations);

                                            _markers.add(Marker(
                                                markerId: MarkerId('Source'),
                                                position: LatLng(event.trackData.locations.first.latitude,
                                                    event.trackData.locations.first.longitude),
                                                icon: sourceIcon));
                                            // destination pin
                                            _markers.add(Marker(
                                                markerId: MarkerId('Destination'),
                                                position: LatLng(event.trackData.locations.last.latitude,
                                                    event.trackData.locations.last.longitude),
                                                icon: destinationIcon));


                                          Polyline polyline = Polyline(
                                              polylineId: PolylineId("Polyline"),
                                              color: Color.fromARGB(255, 40, 122, 198),
                                              points: toLatLng(event.trackData.locations));

                                          // add the constructed polyline as a set of points
                                          // to the polyline set, which will eventually
                                          // end up showing up on the map
                                          _polylines.add(polyline);
                                        });



                                        curActivity.isPrivate = isPrivate;
                                      },
                                    ),
                                    IconButton(
                                        padding: EdgeInsets.all(5.0),
                                        icon: FaIcon(FontAwesomeIcons.pause),
                                        onPressed: () {
                                          Activitybloc.stop();

                                          stop(vm);
                                        }),
                                  ]),
                              Expanded(
                                  child: GridView.count(
                                childAspectRatio: itemWidth / (itemHeight / 4),
                                primary: false,
                                padding: const EdgeInsets.all(20),
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                crossAxisCount: 2,
                                children: <Widget>[
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    child: Center(
                                        child: Text(
                                            details.trackData.steps.toString() +
                                                " Steps")),
                                    color: Colors.teal[50],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    child: Center(
                                        child: Text(details.trackData.latestTime.inSeconds.toString() +
                                            " seconds")),
                                    color: Colors.teal[100],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    child: Center(
                                        child: details.trackData.avgSpeed!=null ?  Text(
                                            details.trackData.avgSpeed.toString() +
                                                "km/h"): Text("0km/h")),
                                    color: Colors.teal[200],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    child: Center(
                                        child: Text(
                                            details.trackData.totalDistance.toString() +
                                                "km")),
                                    color: Colors.teal[300],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    child: Center(
                                        child: Text("AQI: " + details.trackData.avgAQI.toString())),
                                    color: Colors.teal[400],
                                  ),
                                ],
                              )),
                              Expanded(
                                  child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: <Widget>[
                                    Expanded(
                                        flex: 2,
                                        child: IconButton(
                                            padding: EdgeInsets.all(10.0),
                                            icon:
                                                FaIcon(FontAwesomeIcons.camera),
                                            onPressed: () {

                                                getImage().then((value) =>
                                                    uploadImageToFirebase(
                                                        context, _image));
                                            })),
                                    Expanded(
                                        flex: 8,
                                        child: ListView.builder(
                                            shrinkWrap: true,
                                            padding: const EdgeInsets.all(4),
                                            itemCount:
                                                curActivity.images.length,
                                            itemBuilder: (BuildContext context,
                                                int index) {
                                              return new GestureDetector(
                                                  onTap: () {
                                                    showDialog(
                                                        context: context,
                                                        builder: (_) =>
                                                            AlertDialog(
                                                                backgroundColor:
                                                                    Colors
                                                                        .transparent,
                                                                content: Column(
                                                                    mainAxisSize:
                                                                        MainAxisSize
                                                                            .min,
                                                                    children: <
                                                                        Widget>[
                                                                      Image.network(
                                                                          curActivity
                                                                              .images[index]),
                                                                      IconButton(
                                                                          padding: EdgeInsets.all(
                                                                              10.0),
                                                                          color: Colors.red[
                                                                              200],
                                                                          icon: FaIcon(FontAwesomeIcons
                                                                              .trash),
                                                                          onPressed:
                                                                              () {
                                                                            setState(() {
                                                                              curActivity.images.removeAt(index);
                                                                            });
                                                                          })
                                                                    ])));
                                                  },
                                                  child: Container(
                                                    height: 200,
                                                    child: Image.network(
                                                        curActivity
                                                            .images[index]),
                                                  ));
                                            }))
                                  ]))
                            ],
                          );
                        }
                  ));

  }

  File _image;
  final picker = ImagePicker();

  Future getImage() async {
    final pickedFile = await picker.getImage(source: ImageSource.camera);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  Future<User1> getUser(String email) async {
    var newReference = databaseReference.child('users');
    newReference.once().then((DataSnapshot snapshot) {
      Map<dynamic, dynamic> values = snapshot.value;
      currentUser = User1.fromMap(values[email]);
      currentUser.email = email;
      return currentUser;
    });
  }

  stop(MainViewModel vm) async {
    vm.getTokens();
    List<String> tokens = vm.tokens;

    debugPrint(tokens.toString());
    createRecord(tokens);

    setSourceAndDestinationIcons();

  }

  Future<void> updateUser(currentUser, token) async {
    databaseReference.child('users').child(currentUser.email).set({
      'password': currentUser.password,
      'username': currentUser.username,
      'gender': currentUser.gender,
      'image_url': currentUser.image_url,
      'token': token
    });
  }

  Future uploadImageToFirebase(BuildContext context, File _imageFile) async {
    String fileName = basename(_imageFile.path);
    StorageReference firebaseStorageRef =
        FirebaseStorage.instance.ref().child('uploads/$fileName');
    StorageUploadTask uploadTask = firebaseStorageRef.putFile(_imageFile);
    StorageTaskSnapshot taskSnapshot = await uploadTask.onComplete;
    taskSnapshot.ref.getDownloadURL().then((value) {
      setState(() {
        curActivity.images.add(value);
      });
    });
  }

  void createRecord(List tks) {
      if (curActivity.images.length == 0) {
        curActivity.images.add("TEST");
      }
      databaseReference.child('activities').push().set({
        'type': "W",
        "date": curActivity.date,
        "time": curActivity.time,
        "steps": curActivity.steps,
        'distance': curActivity.distance,
        'AQI': curActivity.AQI,
        "coordinates": toList(toLatLng(curActivity.coordinates)),
        'avgSpeed': curActivity.avgSpeed,
        'user_email': prefs.getString('email'),
        'images': curActivity.images,
        'isPrivate': curActivity.isPrivate
      });


      for (String tk in tks) {
        sendAndRetrieveMessage(tk);
      }
    Databloc.getData();
  }

  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

  Future<Map<String, dynamic>> sendAndRetrieveMessage(token) async {
    await _firebaseMessaging.requestNotificationPermissions(
      const IosNotificationSettings(
          sound: true, badge: true, alert: true, provisional: false),
    );
    debugPrint("-----------------------------");
    debugPrint(token);
    await http.post(
      'https://fcm.googleapis.com/fcm/send',
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization':
            'key=AAAAsG67RJk:APA91bFYWMNa0tYqKhH7P-_pAzI8j60T6lwnPHbCurJYwPZ210YlWPbb37hGchyQSAwy7fOaiyOrxZeCl_HjtoKDaO1-RmEx9mOk4D-vJwJc5tP0XXgZZDwBuT8u9cJ934teXTMci0hT',
      },
      body: jsonEncode(
        <String, dynamic>{
          'notification': {
            'body': 'Activity ' +
                curActivity.distance.toString() +
                "km in " +
                curActivity.time.toString() +
                " seconds",
            'title': 'New Activity From ' + currentUser.username
          },
          'priority': 'high',
          'to': token,
        },
      ),
    );
  }

  List<Map<String, double>> toList(List<LatLng> locations) {
    Map<int, LatLng> coords = locations.asMap();
    List<Map<String, double>> list = new List<Map<String, double>>();
    for (int index in coords.keys) {
      var c = {'lat': coords[index].latitude, 'lng': coords[index].longitude};
      list.insert(index, c);
    }
    return list;
  }

  toLatLng(List<ll.LatLng> coordinates) {
    List<LatLng> coords = new List<LatLng>();
    for (ll.LatLng l in coordinates){
      coords.add(LatLng(l.latitude, l.longitude));
    }
    return coords;
  }
}
