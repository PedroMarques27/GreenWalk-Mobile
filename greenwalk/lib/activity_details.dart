import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'activity.dart';

class ActivityDetails extends  StatefulWidget {

  final Activity curActivity;

  ActivityDetails({@required this.curActivity});

  @override
  ActivityDetailsState createState() => ActivityDetailsState();


}

  class ActivityDetailsState extends State<ActivityDetails>{
    Completer<GoogleMapController> _controller = Completer();
    static const LatLng _center =
    const LatLng(37.42796133580664, -122.085749655962);
    CameraPosition _centerposition =
    CameraPosition(target: LatLng(36.0953103, -115.1992098), zoom: 10);

    void _onMapCreated(GoogleMapController controller) {
      _controller.complete(controller);
    }
    @override
    Widget build(BuildContext context) {


      return Scaffold(
          body: Column(children: <Widget>[
            Container(
              height: MediaQuery
                  .of(context)
                  .size
                  .height / 3,
              width: MediaQuery
                  .of(context)
                  .size
                  .width,
              margin: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              child: GoogleMap(
                mapType: MapType.normal,
                initialCameraPosition: _centerposition,
                onMapCreated: (GoogleMapController controller) {
                  _controller.complete(controller);
                },
              ),
            ),

            Expanded(child:GridView.count(
              primary: false,
              padding: const EdgeInsets.all(20),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              crossAxisCount: 2,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(8),
                  child: Text( widget.curActivity.steps.toString() + " Steps"),
                  color: Colors.teal[100],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  child: Text( (widget.curActivity.time/60).toInt().toString()
                        +":"+(widget.curActivity.time%60).toInt().toString()),
                  color: Colors.teal[200],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  child:  Text("Speed:" + (widget.curActivity.distance/(widget.curActivity.time/3600)).toString()),
                  color: Colors.teal[300],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  child:  Text(widget.curActivity.distance.toString()),
                  color: Colors.teal[400],
                )
              ],
            )
            ),
            Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[IconButton(
                    padding: EdgeInsets.all(5.0),
                    icon: FaIcon(FontAwesomeIcons.camera),
                    onPressed: () {}),
                ]
            ),
            Expanded(child:GridView.count(
              primary: false,
              padding: const EdgeInsets.all(20),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              crossAxisCount: 4,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.red[100],
                ),
                Container(
                  padding: const EdgeInsets.all(8),

                  color: Colors.red[200],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.red[300],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.red[400],
                )
              ],
            )
            ),
          ],
          )
      );
    }
  }

