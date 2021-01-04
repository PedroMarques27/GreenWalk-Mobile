import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationService {
  Position _currentLocation;

  Geolocator location = Geolocator();

  Future<Position> _getLocation() async {
    var currentLocation;
    try {
      currentLocation = await location.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best);
    } catch (e) {
      currentLocation = null;
    }
    return currentLocation;
  }


  StreamController<Position> _locationController =
  StreamController<Position>();

  Stream<Position> get locationStream => _locationController.stream;
  void cancel(){
    _locationController.done;
  }

  LocationService() {
    // Request permission to use location
    location.checkGeolocationPermissionStatus().then((granted) {
      if (true) {
        // If granted listen to the onLocationChanged stream and emit over our controller
        location.getPositionStream().listen((position) {
          if (position != null) {
            _locationController.add(position);
          }
        });
      }
    });
  }
}

