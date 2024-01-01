import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:weather_app/provider/weather_provider.dart';

class FavoritesScreen extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    final weatherProvider = Provider.of<WeatherProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Favorite Cities'),
        centerTitle: true,
      ),
      body: FutureBuilder(
        future: weatherProvider.getAllFavoriteCities(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error fetching favorites'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No favorite cities found.'));
          } else {
            List<Map<String, dynamic>> favoriteCities = snapshot.data!;

            return _buildFavoriteCitiesList(favoriteCities);
          }
        },
      ),
    );
  }

  Widget _buildFavoriteCitiesList(List<Map<String, dynamic>> favoriteCities) {
    return ListView.builder(
      itemCount: favoriteCities.length,
      itemBuilder: (context, index) {
        return _buildFavoriteCityCard(context, favoriteCities[index]);
      },
    );
  }

  Widget _buildFavoriteCityCard(
      BuildContext context, Map<String, dynamic> cityData) {
    return Card(
      margin: EdgeInsets.all(10),
      color: Colors.blue.shade50.withOpacity(0.9),
      borderOnForeground: true,
      elevation: 0.2,
      child: ListTile(
        title: Text(cityData['cityName']),
        subtitle: Text('Temp : ${cityData['temp']} \n'
            'Latitude: ${cityData['latitude']}, \nLongitude: ${cityData['longitude']}'),
        trailing: IconButton(
          icon: Icon(CupertinoIcons.delete_simple),
          onPressed: () {
            _removeFavoriteCity(context, cityData['cityName']);
          },
        ),
        leading: getWeatherIcon(cityData['weatherCode']),
      ),
    );
  }

  void _removeFavoriteCity(BuildContext context, String cityName) async {
    final weatherProvider =
        Provider.of<WeatherProvider>(context, listen: false);

    try {
      final CollectionReference favorites =
          FirebaseFirestore.instance.collection('favorites');

      QuerySnapshot querySnapshot =
          await favorites.where('cityName', isEqualTo: cityName).limit(1).get();

      if (querySnapshot.docs.isNotEmpty) {
        await favorites.doc(querySnapshot.docs.first.id).delete();
        weatherProvider.removeFromFavorites(cityName);
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
