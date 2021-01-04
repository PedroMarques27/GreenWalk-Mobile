
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'activity_details.dart';
import 'activity.dart';

Widget BuildBody(BuildContext context) {
  return FutureBuilder(
    // Initialize FlutterFire
    future: getData(),
    builder: (context, snapshot) {
      // Check for errors
      if (!snapshot.hasData) return LinearProgressIndicator();
      // Once complete, show your application
      if (snapshot.connectionState == ConnectionState.done) {
        return _buildList(context, snapshot.data);
      }
      // Otherwise, show something whilst waiting for initialization to complete
      return _loading(context);
    },
  );
}

Future<List<QueryDocumentSnapshot>> getData() async {
  await Firebase.initializeApp();
  QuerySnapshot querySnapshot =
  await Firestore.instance.collection("activities").getDocuments();
  return querySnapshot.documents;
}

Widget _loading(BuildContext context) {
  return Text("Loading");
}

Widget _buildList(BuildContext context, List<DocumentSnapshot> snapshot) {
  return CustomScrollView(primary: false, slivers: <Widget>[
    SliverPadding(
        padding: const EdgeInsets.all(20),
        sliver: SliverGrid.count(
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          crossAxisCount: 2,
          children:
          snapshot.map((data){
            final activity = Activity.fromSnapshot(data);
            return GestureDetector(child: _buildListItem(context, data ), onTap: () {
              goToDetailsPage(context, activity);
            },);
          }).toList(),

        ))
  ]);
}
goToDetailsPage(BuildContext context, Activity activity) {
  Navigator.push(
    context,
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (BuildContext context) => ActivityDetails(
        curActivity: activity,
      ),
    ),
  );
}
Widget _buildListItem(BuildContext context, DocumentSnapshot data) {
  final activity = Activity.fromSnapshot(data);

  return Padding(

    key: ValueKey(activity.type),
    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),

    child: Container(

        decoration: BoxDecoration(
          color: activity.AQI > 50 ? Colors.red : Colors.green,
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(5.0),
        ),
        child: Container(
          height: 50,
          child: Wrap(
              children: <Widget>[
                Row(children: <Widget>[
                  Text(activity.type)
                ]),
                Row(children: <Widget>[
                  Text(activity.date)
                ]),
                Row(children: <Widget>[
                  Text(activity.distance.toString() + "km"),
                ]),
                Row(children: <Widget>[Text("AQI:" + activity.AQI.toString())]),
                Row(children: <Widget>[Text(activity.steps.toString() + "Steps")])
              ]),
        ),


    ),
  );
}
