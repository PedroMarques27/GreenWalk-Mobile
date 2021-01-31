// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ActivityClass.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ActivityAdapter extends TypeAdapter<Activity> {
  @override
  Activity read(BinaryReader reader) {
    var numOfFields = reader.readByte();
    var fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Activity(
      fields[0] as String,
    )
      ..time = fields[1] as int
      ..steps = fields[2] as int
      ..AQI = fields[3] as int
      ..avgSpeed = fields[4] as double
      ..distance = fields[5] as double
      ..user_email = fields[6] as String
      ..id = fields[7] as String
      ..images = (fields[8] as List)?.cast<String>()
      ..coordinates = (fields[9] as List)?.cast<LatLng>()
      ..isPrivate = fields[10] as bool;
  }

  @override
  void write(BinaryWriter writer, Activity obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.time)
      ..writeByte(2)
      ..write(obj.steps)
      ..writeByte(3)
      ..write(obj.AQI)
      ..writeByte(4)
      ..write(obj.avgSpeed)
      ..writeByte(5)
      ..write(obj.distance)
      ..writeByte(6)
      ..write(obj.user_email)
      ..writeByte(7)
      ..write(obj.id)
      ..writeByte(8)
      ..write(obj.images)
      ..writeByte(9)
      ..write(obj.coordinates)
      ..writeByte(10)
      ..write(obj.isPrivate);
  }

  @override
  // TODO: implement typeId
  int get typeId => 0;
}
