import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:greenwalk/Entities/ActivityClass.dart';
import 'package:greenwalk/Entities/LatLng.dart';
import 'package:greenwalk/Entities/User.dart';

import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

class DataBloc {
  StreamController< List<Activity>> allActivities = StreamController< List<Activity>>.broadcast();

  Stream get getAllActivities => allActivities.stream;
  List<Activity> allActivitiesList;
  List<String> used_ids;

  User1 currentUser;

  DataBloc(){
    allActivitiesList = new List<Activity>();
    used_ids = new List<String>();
    try{
      __initdb__();
    }
    catch(e){
      getData();
    }


  }

  __initdb__() async {
    final appDocumentDir = await path_provider.getApplicationDocumentsDirectory();
    Hive.init(appDocumentDir.path);
    try{
      Hive.registerAdapter(ActivityAdapter());
      Hive.registerAdapter(LatLngAdapter());
    }
    catch(e){
    }

    getData();
  }



  List<Activity> filterPublic(){
    List<Activity> filtered = new List<Activity>();
    for (Activity a in allActivitiesList ){
      if (a.isPrivate==false){
        filtered.add(a);
      }
    }

    return filtered;
  }


  void updateList() {
    allActivities.sink.add(allActivitiesList);
     // add whatever data we want into the Sink
  }




  Future<void> getData() async {
    final box = await Hive.openBox<Activity>('activities');

    allActivitiesList = box.values.toList();
    for (Activity _activity in allActivitiesList) {
      used_ids.add(_activity.id);
    }
    updateList();
    final databaseReference = FirebaseDatabase.instance.reference();
    var newReference = databaseReference.child('activities');
    List<Activity> acs = new List<Activity>();
    newReference.once().then((DataSnapshot snapshot) {

      Map<dynamic, dynamic> values = snapshot.value;
      for (String key in values.keys) {
        if (!used_ids.contains(key)){
          Map<dynamic, dynamic> o = values[key];
          Activity cur = Activity.fromMap(o);
          cur.id = key;
          used_ids.add(key);
          box.add(cur);
          allActivitiesList.add(cur);
          updateList();
        }
      }

    });
  }

  void filterByUser(User1 cu) {currentUser = cu;}

  void reset() {
    allActivitiesList = new List<Activity>();
    used_ids = new List<String>();
    try{
      __initdb__();
    }catch(Exception){
      getData();
    }

    updateList();
  }

}

final Databloc = DataBloc(); // create an instance of the counter bloc

