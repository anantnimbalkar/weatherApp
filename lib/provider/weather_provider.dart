import 'dart:convert';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;
import 'package:weather_app/provider/location_provider.dart';

enum Status { loading, success, failure }

class WeatherProvider extends ChangeNotifier {
  final String apiKey = 'f4dd7b43955b433c6dcea0cbb4c2a39e';
  Status status = Status.loading;
  Status get statusgetter => status;
  String? _currentWeather;

  String? get currentWeather => _currentWeather;

  int? _currentWeatherCode;

  int? get currentWeatherCode => _currentWeatherCode;

  String? _name;

  String? cityName;

  String? get name => _name;
  String? _cityWeathername;
  String? get weatherStatus => _weatherStatus;
  String? _weatherStatus;

  String? get cityWeather => _cityWeathername;

  Map<String, dynamic>? get currentWeatherData => _currentWeatherData;
  Map<String, dynamic>? _currentWeatherData;

  List<Map<String, dynamic>>? _sevenDayForecast;
  List<Map<String, dynamic>>? get sevenDayForecast => _sevenDayForecast;
  List<Map<String, dynamic>> _favoriteCities = [];

  List<Map<String, dynamic>> get favoriteCities => _favoriteCities;

  void addToFavorites(Map<String, dynamic> cityData) {
    _favoriteCities.add(cityData);
    notifyListeners();
  }

  void removeFromFavorites(String cityName) {
    _favoriteCities.removeWhere((city) => city['cityName'] == cityName);
    notifyListeners();
  }

  Future<void> getWeatherByLocation(LocationProvider locationProvider) async {
    if (locationProvider.currentPosition != null) {
      double lat = locationProvider.currentPosition!.latitude;
      double lon = locationProvider.currentPosition!.longitude;

      final url =
          'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric';

      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          log(data.toString());
          _currentWeather = data['weather'][0]['main'];
          _currentWeatherCode = data['weather'][0]['id'];
          _currentWeatherData = data['main'];
          _name = data['name'];

          notifyListeners();
        } else {
          print('Error fetching weather: ${response.statusCode}');
        }
      } catch (e) {
        print('Error fetching weather: $e');
      }
    }
  }

  Future<void> getWeatherByCityName(String cityName) async {
    final url =
        'https://api.openweathermap.org/data/2.5/weather?q=$cityName&appid=$apiKey&units=metric';

    try {
      status = Status.loading;
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        _weatherStatus = response.statusCode.toString();
        final data = json.decode(response.body);
        log(data.toString());
        _currentWeather = data['weather'][0]['main'];
        _currentWeatherCode = data['weather'][0]['id'];
        _currentWeatherData = data['main'];
        _name = data['name'];
        status = Status.success;
        notifyListeners();
      } else {
        _weatherStatus = response.statusCode.toString();
        print('Error fetching weather: ${response.statusCode}');
        status = Status.failure;
      }
    } catch (e) {
      print('Error fetching weather: $e');
    }
  }

  Future<void> getSevenDayForecast(
      String cityName, LocationProvider locationProvider) async {
    double lat = locationProvider.currentPosition!.latitude;
    double lon = locationProvider.currentPosition!.longitude;
    final url = cityName.isNotEmpty
        ? 'https://api.openweathermap.org/data/2.5/forecast?q=$cityName&appid=$apiKey&units=metric'
        : 'https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&appid=$apiKey&units=metric';

    try {
      status = Status.loading;
      final response = await http.get(Uri.parse(url));
      log(response.statusCode.toString());
      if (response.statusCode == 200) {
        _weatherStatus = response.statusCode.toString();
        final data = await json.decode(response.body);
        _sevenDayForecast = List<Map<String, dynamic>>.from(data['list']);
        log(response.body.toString());
        status = Status.success;
        log("Weather Forecast");
        log(_sevenDayForecast.toString());
        notifyListeners();
      } else {
        _weatherStatus = response.statusCode.toString();
        status = Status.failure;
        print('Error fetching 7-day forecast: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching 7-day forecast: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAllFavoriteCities() async {
    try {
      final CollectionReference favorites =
          FirebaseFirestore.instance.collection('favorites');

      QuerySnapshot querySnapshot = await favorites.get();

      return querySnapshot.docs
          .map((doc) => Map<String, dynamic>.from(doc.data() as Map))
          .toList();
    } catch (e) {
      print('Error fetching favorites: $e');
      return [];
    }
  }
}
