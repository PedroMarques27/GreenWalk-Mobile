
import 'package:hive/hive.dart';

import 'LatLng.dart';

part 'ActivityClass.g.dart';

@HiveType()
class Activity {
  @HiveField(0)
  String date;
  @HiveField(1)
  int time = 0;
  @HiveField(2)
  int steps = 0;
  @HiveField(3)
  int AQI;
  @HiveField(4)
  double avgSpeed = 0;
  @HiveField(5)
  double distance = 0;
  @HiveField(6)
  String user_email;
  @HiveField(7)
  String id;
  @HiveField(8)
  List<String> images = new List<String>();
  @HiveField(9)
  List<LatLng> coordinates = List<LatLng>();
  @HiveField(10)
  bool isPrivate = true;

  Activity(this.date);

  Activity.fromMap(Map<dynamic, dynamic> map) {
    assert(map['type'] != null);
    assert(map['date'] != null);
    assert(map['steps'] != null);
    assert(map['AQI'] != null);
    assert(map['time'] != null);
    assert(map['avgSpeed'] != null);
    date = map['date'];
    AQI = map['AQI'];
    time = map['time'];
    steps = map['steps'];
    distance = map['distance'].toDouble();
    avgSpeed = map['avgSpeed'].toDouble();
    user_email = map['user_email'].toString();
    List<dynamic> coords = map['coordinates'];
    List<dynamic> img = map['images'];
    if (coords == null) coords = new List<dynamic>();
    for (Map<dynamic, dynamic> c in coords) {
      coordinates.add(LatLng(c['lat'].toDouble(), c['lng'].toDouble()));
    }
    if (map['isPrivate'] != null) isPrivate = map['isPrivate'];
    for (String c in img) {
      if (c != "TEST") images.add(c);
    }
  }

}


