import 'package:hive/hive.dart';
part 'LatLng.g.dart';
@HiveType()
class LatLng{
  @HiveField(0)
  double latitude;
  @HiveField(1)
  double longitude;
  LatLng(this.latitude, this.longitude);
}