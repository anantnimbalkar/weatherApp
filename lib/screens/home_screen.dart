import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:weather_app/provider/location_provider.dart';
import 'package:weather_app/provider/weather_provider.dart';
import 'package:weather_app/screens/fav_city_screen.dart';
import 'package:weather_app/widgets/snackbar.dart';

Widget getWeatherIcon(int code) {
  switch (code) {
    case >= 200 && < 300:
      return Image.asset('images/1.png');
    case >= 300 && < 400:
      return Image.asset('images/2.png');
    case >= 500 && < 600:
      return Image.asset('images/3.png');
    case >= 600 && < 700:
      return Image.asset('images/4.png');
    case >= 700 && < 800:
      return Image.asset("images/5.png");
    case == 800:
      return Image.asset("images/6.png");
    case > 800 && <= 804:
      return Image.asset("images/7.png");
    default:
      return Image.asset("images/7.png");
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isDataFetched = false;
  bool isSearching = false;
  bool isSearchingByCityName = false;
  bool isFavorite = false;
  TextEditingController searchController = TextEditingController();
  void toggleFavorite() async {
    setState(() {
      isFavorite = !isFavorite;
    });

    if (isFavorite) {
      await addCityToFavorites();
    } else {
      await removeCityFromFavorites();
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = Provider.of<LocationProvider>(context);
    final weatherProvider = Provider.of<WeatherProvider>(context);
    if (!_isDataFetched) {
      _isDataFetched = true;

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await locationProvider.getCurrentLocation();
        await weatherProvider.getWeatherByLocation(locationProvider);
        await weatherProvider.getWeatherByCityName(searchController.text);
        await weatherProvider.getSevenDayForecast(
            searchController.text, locationProvider);
      });
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: isSearching
            ? TextField(
                controller: searchController,
                autofocus: true,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Search',
                ),
                onChanged: (val) {
                  weatherProvider.getWeatherByCityName(searchController.text);
                  weatherProvider.getSevenDayForecast(
                      searchController.text, locationProvider);
                  searchController.text = weatherProvider.cityName!;
                },
                onSubmitted: (val) {
                  weatherProvider.getWeatherByCityName(val);
                },
              )
            : Text('Weather'),
        centerTitle: true,
        actions: [
          IconButton(
              onPressed: () {
                setState(() {
                  isSearching = !isSearching;
                });
                searchController.text = '';
              },
              icon: Icon(isSearching
                  ? CupertinoIcons.clear_circled_solid
                  : CupertinoIcons.search)),
          IconButton(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => FavoritesScreen()));
              },
              icon: Icon(CupertinoIcons.square_favorites_fill))
        ],
      ),
      body: _buildWeatherDetails(weatherProvider),
    );
  }

  Widget _buildWeatherDetails(WeatherProvider weatherProvider) {
    return (weatherProvider.status == Status.loading)
        ? Center(child: CircularProgressIndicator())
        : (weatherProvider.weatherStatus == "200")
            ? SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          margin: EdgeInsets.only(left: 20),
                        ),
                        Text(
                          'Current Weather City: ${weatherProvider.name}',
                          style: TextStyle(fontSize: 18),
                        ),
                        IconButton(
                          icon: Icon(isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border),
                          onPressed: () {
                            // Toggle favorite status and update Firestore
                            toggleFavorite();
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    WeatherDetailsWidget(weatherProvider.currentWeatherData!),
                    Container(
                        margin: EdgeInsets.only(
                            bottom: MediaQuery.sizeOf(context).height * 0.01),
                        height: MediaQuery.sizeOf(context).height * 0.4,
                        child: getWeatherIcon(
                            weatherProvider.currentWeatherCode!)),
                    SevenDayForecastList(weatherProvider.sevenDayForecast)
                  ],
                ),
              )
            : Center(child: Text("No Data Found"));
  }

  Future<void> addCityToFavorites() async {
    final locationProvider =
        Provider.of<LocationProvider>(context, listen: false);
    final weatherProvider =
        Provider.of<WeatherProvider>(context, listen: false);
    try {
      final CollectionReference favorites =
          FirebaseFirestore.instance.collection('favorites');

      await favorites.add({
        'cityName': weatherProvider.name,
        'temp': weatherProvider.currentWeatherData!['temp'],
        'latitude': locationProvider.currentPosition!.latitude,
        'longitude': locationProvider.currentPosition!.longitude,
        'weatherCode': weatherProvider.currentWeatherCode,
      });

      weatherProvider.addToFavorites({
        'cityName': weatherProvider.name,
        'temp': weatherProvider.currentWeatherData!['temp'],
        'latitude': locationProvider.currentPosition!.latitude,
        'longitude': locationProvider.currentPosition!.longitude,
        'weatherCode': weatherProvider.currentWeatherCode,
      });

      showCustomSnackbar(
          context: context,
          message: "Added to favorites",
          backgroundColor: Colors.green);
    } catch (e) {
      print('Error adding to favorites: $e');

      showCustomSnackbar(
          context: context,
          message: "Failed to add to favorites",
          backgroundColor: Colors.green);
    }
  }

  Future<void> removeCityFromFavorites() async {
    final locationProvider =
        Provider.of<LocationProvider>(context, listen: false);
    final weatherProvider =
        Provider.of<WeatherProvider>(context, listen: false);
    try {
      final CollectionReference favorites =
          FirebaseFirestore.instance.collection('favorites');

      QuerySnapshot querySnapshot = await favorites
          .where('cityName', isEqualTo: weatherProvider.name)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        await favorites.doc(querySnapshot.docs.first.id).delete();
        weatherProvider.removeFromFavorites(weatherProvider.name!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Removed from favorites')),
        );
      }
    } catch (e) {
      print('Error removing from favorites: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove from favorites')),
      );
    }
  }
}

class WeatherDetailsWidget extends StatelessWidget {
  final Map<String, dynamic> weatherDetails;

  WeatherDetailsWidget(this.weatherDetails);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Temperature: ${weatherDetails['temp']} °C'),
        Text('Feels Like: ${weatherDetails['feels_like']} °C'),
        Text('Min Temperature: ${weatherDetails['temp_min']} °C'),
        Text('Max Temperature: ${weatherDetails['temp_max']} °C'),
        Text('Humidity: ${weatherDetails['humidity']}%'),
      ],
    );
  }

  double convertKelvinToCelsius(double? kelvin) {
    if (kelvin == null) {
      return 0.0;
    }
    return kelvin - 273.15;
  }

  String formatTemperature(double? temperature) {
    if (temperature == null) {
      return 'N/A';
    }
    return temperature.toStringAsFixed(2);
  }
}

class SevenDayForecastList extends StatelessWidget {
  final List<Map<String, dynamic>>? sevenDayForecast;

  SevenDayForecastList(this.sevenDayForecast);

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.sizeOf(context);
    if (sevenDayForecast == null || sevenDayForecast!.isEmpty) {
      return CircularProgressIndicator();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        children: [
          Row(
            children: sevenDayForecast!.map((forecast) {
              final DateTime forecastDate =
                  DateTime.fromMillisecondsSinceEpoch(forecast['dt'] * 1000);
              final String formattedDate =
                  "${forecastDate.day}/${forecastDate.month}";

              return Container(
                margin: EdgeInsets.only(left: 5, right: 5),
                decoration: BoxDecoration(
                    border: Border.all(
                      color: Color(0xFFE2E2E2),
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.grey.shade100.withOpacity(0.4),
                          blurRadius: 2)
                    ]),
                width: mediaQuery.width * 0.35,
                child: Column(
                  children: [
                    getWeatherIcon(forecast['weather'][0]['id']),
                    ListTile(
                      title: Text(formattedDate),
                      subtitle: Text(
                        'Temperature: ${forecast['main']['temp']} °C',
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  double convertKelvinToCelsius(double? kelvin) {
    if (kelvin == null) {
      return 0.0; // or handle as needed
    }
    return kelvin - 273.15;
  }

  String formatTemperature(double? temperature) {
    if (temperature is int) {
      return temperature!.toStringAsFixed(2);
    } else if (temperature is double) {
      return temperature.toStringAsFixed(2);
    } else {
      return 'N/A';
    }
  }
}
