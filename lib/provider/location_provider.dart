// location_provider.dart
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationProvider with ChangeNotifier {
  Position? _currentPosition;

  Position? get currentPosition => _currentPosition;

  Future<void> getCurrentLocation() async {
    try {
      Geolocator.requestPermission();
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      log('location Fetched Successfully');
      notifyListeners();
    } catch (e) {
      print('Error getting location: $e');
    }
  }
}
