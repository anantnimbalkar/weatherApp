import 'dart:async';
import 'dart:developer';

import 'package:connectivity/connectivity.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:geolocator/geolocator.dart';

import 'package:weather_app/screens/home_screen.dart';

import 'package:weather_app/screens/login_phone_screen.dart';
import 'package:weather_app/widgets/snackbar.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

//886285
class _SplashScreenState extends State<SplashScreen> {
  late Connectivity _connectivity;
  late StreamSubscription<ConnectivityResult> _subscription;
  @override
  void initState() {
    getCurrentLocation();
    Future.delayed(
      Duration(seconds: 5),
      () {
        if (FirebaseAuth.instance.currentUser != null) {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const HomeScreen()));
        } else {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const PhoneLoginScreen()));
        }
      },
    );
    _connectivity = Connectivity();
    _subscription = _connectivity.onConnectivityChanged.listen(
      (ConnectivityResult result) {
        _showConnectionSnackbar(result);
      },
    );
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    var connectivityResult = await _connectivity.checkConnectivity();
    _showConnectionSnackbar(connectivityResult);
  }

  void _showConnectionSnackbar(ConnectivityResult result) {
    String message = '';
    Color color = Colors.green; // Default color for connected state

    switch (result) {
      case ConnectivityResult.none:
        message = 'No Internet connection';
        color = Colors.red;
        break;
      case ConnectivityResult.mobile:
        message = 'Mobile data connection';
        break;
      case ConnectivityResult.wifi:
        message = 'WiFi connection';
        break;
      default:
        message = 'Unknown';
    }

    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: color,
    );

    // Show the snackbar
    ScaffoldMessenger.of(context).showSnackBar(snackBar);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.sizeOf(context);
    return Scaffold(
      backgroundColor: Color(0xFF3eabe4),
      body: Column(
        children: [
          Container(
            height: mediaQuery.height,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('images/splash.jpg'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> getCurrentLocation() async {
    Position? currentPosition;

    try {
      Geolocator.requestPermission();
      currentPosition = await Geolocator.getCurrentPosition();

      log('location Fetched successfully');
      // notifyListeners();
    } catch (e) {
      print('Error getting location: $e');
    }
  }
}
