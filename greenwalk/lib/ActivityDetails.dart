import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:firebase_database/firebase_database.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Activity.dart';

import 'package:image_picker/image_picker.dart';

import 'MainViewModel.dart';
import 'Profile.dart';

class ActivityDetails extends StatefulWidget {
  Activity curActivity;
  MainViewModel vm;
  ActivityDetails({@required this.curActivity, this.vm});



  @override
  ActivityDetailsState createState() => ActivityDetailsState();
}

class ActivityDetailsState extends State<ActivityDetails> {
  Completer<GoogleMapController> _controller = Completer();
  final databaseReference = FirebaseDatabase.instance.reference();
  LatLng _center;
  CameraPosition _centerposition;
  Activity curActivity;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  List<LatLng> polylineCoordinates = [];
  BitmapDescriptor sourceIcon;
  BitmapDescriptor destinationIcon;
  String username = " Loading...";
  SharedPreferences prefs;
  String useremail;
  @override
  void initState() {
    super.initState();
    curActivity = widget.curActivity;
    _center = widget.curActivity.coordinates.last;
    _centerposition = CameraPosition(target: _center, zoom: 10);
    __init__();
    // ignore: unnecessary_statements
    setState(() {
      useremail= widget.vm.currentUser.email;
    });

  }

  File _image;
  final picker = ImagePicker();

  Future getImageFromCamera() async {
    final pickedFile = await picker.getImage(source: ImageSource.camera);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  Future getImageFromGallery() async {
    final pickedFile = await picker.getImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
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
        updateActivity();
      });
    });
  }

  void updateActivity() {
    if (curActivity.images.length == 0) {
      curActivity.images.add("TEST");
    }
    databaseReference.child('activities').child(curActivity.id).set({
      "type": curActivity.type,
      "date": curActivity.date,
      "time": curActivity.time,
      "steps": curActivity.steps,
      'distance': curActivity.distance,
      'AQI': curActivity.AQI,
      "coordinates": toList(curActivity.coordinates),
      'avgSpeed': curActivity.avgSpeed,
      'user_email': curActivity.user_email,
      'images': curActivity.images,
      'isPrivate': curActivity.isPrivate
    });
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

  void __init__() async {

    prefs = await SharedPreferences.getInstance();
    await setPolylines();
    await getUsername();
    await setSourceAndDestinationIcons();
    await setMapPins();
  }

  Future<ui.Image> getImageFromNetwork(String path) async {
    Completer<ImageInfo> completer = Completer();
    var img = new NetworkImage(path);
    img
        .resolve(ImageConfiguration())
        .addListener(ImageStreamListener((ImageInfo info, bool _) {
      completer.complete(info);
    }));
    ImageInfo imageInfo = await completer.future;
    return imageInfo.image;
  }
  Future<void> setSourceAndDestinationIcons() async {
    final iconData = Icons.pin_drop;
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
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

  void _onMapCreated(GoogleMapController controller) {
    _controller.complete(controller);
  }

  User1 currentActivityUser;

  Future<User1> getUsername() {
    var newReference = databaseReference.child('users');
    newReference.once().then((DataSnapshot snapshot) {
      Map<dynamic, dynamic> values = snapshot.value;

      for (String k in values.keys) {
        if (k == curActivity.user_email) {
          Map<dynamic, dynamic> user = values[k];
          setState(() {
            currentActivityUser = User1.fromMap(user);
            currentActivityUser.email = curActivity.user_email;
            username = user['username'].toString();
            return currentActivityUser;
          });
        }
      }
    });
  }

  void setMapPins() {
    setState(() {
      _markers.add(Marker(
          markerId: MarkerId('sourcePin'),
          position: LatLng(curActivity.coordinates.first.latitude,
              curActivity.coordinates.first.longitude),
          icon: sourceIcon,
          onTap: () {
            Fluttertoast.showToast(
                msg: "Activity Start Point",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.CENTER,
                timeInSecForIos: 1);
          }));
      // destination pin
      _markers.add(Marker(
          markerId: MarkerId('destPin'),
          position: LatLng(curActivity.coordinates.last.latitude,
              curActivity.coordinates.last.longitude),
          icon: destinationIcon,
          onTap: () {
            Fluttertoast.showToast(
                msg: "Activity End Point",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.CENTER,
                timeInSecForIos: 1);
          }));
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
    var size = MediaQuery.of(context).size;
    final double itemHeight = (size.height - kToolbarHeight - 24) / 2;
    final double itemWidth = size.width / 2;
    final GlobalKey<ScaffoldState> _scaffoldKey =
        new GlobalKey<ScaffoldState>();

    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text(username + "\n" + curActivity.date),
        ),
        body: Padding(
          padding: const EdgeInsets.only(
            left: 5,
            top: 20,
            right: 10,
            bottom: 15,
          ),
          child: Column(children: <Widget>[
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
                  initialCameraPosition: _centerposition,
                  onMapCreated: _onMapCreated),
            ),
            Expanded(
                child: GridView.count(
              primary: false,
              childAspectRatio: itemWidth / (itemHeight / 4),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              crossAxisCount: 2,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(5),
                  child: Center(
                      child:
                          Text(widget.curActivity.steps.toString() + " Steps")),
                  color: Colors.green[50],
                ),
                Container(
                  padding: const EdgeInsets.all(5),
                  child: Center(
                      child: Text((widget.curActivity.time / 3600)
                              .toInt()
                              .toString() +
                          ":" +
                          (widget.curActivity.time / 60).toInt().toString() +
                          ":" +
                          (widget.curActivity.time % 60).toInt().toString())),
                  color: Colors.green[100],
                ),
                Container(
                  padding: const EdgeInsets.all(5),
                  child: Center(
                      child: Text((widget.curActivity.distance /
                                  (widget.curActivity.time / 3600))
                              .toStringAsFixed(2) +
                          "km/h")),
                  color: Colors.green[200],
                ),
                Container(
                  padding: const EdgeInsets.all(5),
                  child: Center(
                      child:
                          Text(widget.curActivity.distance.toString() + "km")),
                  color: Colors.green[300],
                ),
                Container(
                  padding: const EdgeInsets.all(5),
                  child: Center(
                      child: Text(
                          "Average AQI: " + widget.curActivity.AQI.toString())),
                  color: Colors.green[400],
                )
              ],
            )),
            Expanded(
                child:Padding(
                    padding: const EdgeInsets.all(12.0),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: <
                      Widget>[
                    Expanded(
                        flex: 3,
                        child: Center(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
                                  Text(""),
                                  curActivity.user_email==  useremail?
                                  Switch(
                                      value: curActivity.isPrivate,
                                      onChanged: (value) {
                                        setState(() {
                                          curActivity.isPrivate = value;
                                          Fluttertoast.showToast(
                                              msg: value == true ? "Private" : "Public",
                                              toastLength: Toast.LENGTH_SHORT,
                                              gravity: ToastGravity.BOTTOM,
                                              timeInSecForIos: 1,
                                              backgroundColor: Colors.black45,
                                              textColor: Colors.white);
                                          updateActivity();
                                        });
                                      }): Text(""),
                                  IconButton(
                                      padding: EdgeInsets.all(10.0),
                                      icon: FaIcon(FontAwesomeIcons.camera),
                                      onPressed: () {
                                        getImageFromCamera().then((value) =>
                                            uploadImageToFirebase(context, _image));
                                      }),
                                  IconButton(
                                      padding: EdgeInsets.all(10.0),
                                      icon: FaIcon(FontAwesomeIcons.image),
                                      onPressed: () {
                                        getImageFromGallery().then((value) =>
                                            uploadImageToFirebase(context, _image));
                                      })
                                ]))),
                    Expanded(
                        flex: 4,
                        child: ListView.builder(
                            shrinkWrap: true,
                            padding: const EdgeInsets.all(4),
                            itemCount: curActivity.images.length,
                            itemBuilder: (BuildContext context, int index) {
                              return new GestureDetector(
                                  onTap: () {
                                    showDialog(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                            backgroundColor: Colors.transparent,
                                            content: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: <Widget>[
                                                  Image.network(
                                                      curActivity.images[index]),
                                                  IconButton(
                                                      padding: EdgeInsets.all(10.0),
                                                      color: Colors.red[200],
                                                      icon: FaIcon(
                                                          FontAwesomeIcons.trash),
                                                      onPressed: () {
                                                        setState(() {
                                                          curActivity.images.removeAt(index);
                                                          updateActivity();
                                                        });
                                                      }
                                                  )
                                                ])));
                                  },
                                  child: Container(
                                    height: 200,
                                    child: Image.network(curActivity.images[index]),
                                  ));
                            }))
                  ])
                )
                   )
          ]),
        ));
  }
}
