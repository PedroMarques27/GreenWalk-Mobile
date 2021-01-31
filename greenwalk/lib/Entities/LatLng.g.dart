// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'LatLng.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LatLngAdapter extends TypeAdapter<LatLng> {
  @override
  LatLng read(BinaryReader reader) {
    var numOfFields = reader.readByte();
    var fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LatLng(
      fields[0] as double,
      fields[1] as double,
    );
  }

  @override
  void write(BinaryWriter writer, LatLng obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.latitude)
      ..writeByte(1)
      ..write(obj.longitude);
  }

  @override
  // TODO: implement typeId
  int get typeId => 1;
}
