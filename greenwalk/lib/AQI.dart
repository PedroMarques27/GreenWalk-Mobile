import 'dart:core';

class AirData {
  double latitude, longitude;
  String timezone, cityName, countryCode, stateCode;
  List<Data> data;

  AirData(
      {this.latitude,
      this.longitude,
      this.timezone,
      this.cityName,
      this.countryCode,
      this.stateCode,
      this.data});

  factory AirData.fromJson(Map<String, dynamic> json) {
    var dataObjsJson = json['data'] as List;
    List<Data> _data =
        dataObjsJson.map((dataJson) => Data.fromJson(dataJson)).toList();
    return AirData(
        latitude: json['lat'],
        longitude: json['lon'],
        timezone: json['timezone'],
        cityName: json['city_name'],
        countryCode: json['country_code'],
        stateCode: json['state_code'],
        data: _data);
  }
}

class Data {
  double mold_level, aqi, pm10,o3,pollen_level_tree,pollen_level_weed,pollen_level_grass;
  String predominant_pollen_type;
  double no2, co,so2,pm25;
  Data(
      {this.aqi,
      this.o3,
      this.so2,
      this.no2,
      this.co,
      this.pm10,
      this.pm25,
      this.pollen_level_tree,
      this.pollen_level_grass,
      this.pollen_level_weed,
      this.mold_level,
      this.predominant_pollen_type});

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
        aqi: json["aqi"].toDouble(),
        o3: json['o3'].toDouble(),
        so2: json['so2'].toDouble(),
        no2: json['no2'].toDouble(),
        co: json['co'].toDouble(),
        pm10: json['pm10'].toDouble(),
        pm25: json['pm25'].toDouble(),
        pollen_level_tree: json['pollen_level_tree'].toDouble(),
        pollen_level_grass: json['pollen_level_grass'].toDouble(),
        pollen_level_weed: json['pollen_level_weed'].toDouble(),
        mold_level: json['mold_level'].toDouble(),
        predominant_pollen_type: json['predominant_pollen_type']);
  }
}
