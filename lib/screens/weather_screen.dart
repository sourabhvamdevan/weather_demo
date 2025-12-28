import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import '../services/weather_service.dart';

const String favCitiesKey = 'favorite_cities';
const String cachedWeatherKey = 'cached_weather';

class WeatherScreen extends StatefulWidget {
  final bool isDark;
  final VoidCallback toggleTheme;

  const WeatherScreen({
    super.key,
    required this.isDark,
    required this.toggleTheme,
  });

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final WeatherService _service = WeatherService();
  final TextEditingController _controller = TextEditingController();

  Map<String, dynamic>? weatherData;
  List<String> favoriteCities = [];
  bool isFavorite = false;
  bool loading = false;
  String error = '';

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _loadCachedWeather();
  }

  //for favorite cities
  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      favoriteCities = prefs.getStringList(favCitiesKey) ?? [];
    });
  }

  Future<void> _toggleFavorite(String city) async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      if (favoriteCities.contains(city)) {
        favoriteCities.remove(city);
        isFavorite = false;
      } else {
        favoriteCities.add(city);
        isFavorite = true;
      }
    });

    await prefs.setStringList(favCitiesKey, favoriteCities);
  }

  //this is for caching
  Future<void> _cacheWeather(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(cachedWeatherKey, json.encode(data));
  }

  Future<void> _loadCachedWeather() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(cachedWeatherKey);

    if (cached != null && weatherData == null) {
      setState(() {
        weatherData = json.decode(cached);
      });
    }
  }

  //this is for weather fetching
  Future<void> _getWeatherByCity(String city) async {
    setState(() {
      loading = true;
      error = '';
    });

    try {
      final data = await _service.fetchByCity(city);
      setState(() {
        weatherData = data;
        isFavorite = favoriteCities.contains(city);
      });
      _cacheWeather(data);
    } catch (e) {
      error = 'Offline mode – showing last data';
      _loadCachedWeather();
    }

    setState(() => loading = false);
  }

  Future<void> _getWeatherByLocation() async {
    setState(() {
      loading = true;
      error = '';
    });

    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final data = await _service.fetchByLatLon(pos.latitude, pos.longitude);

      setState(() => weatherData = data);
      _cacheWeather(data);
    } catch (e) {
      error = 'Location error or offline';
      _loadCachedWeather();
    }

    setState(() => loading = false);
  }

  //for UI section
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getWeatherByLocation,
          ),
          IconButton(
            icon: Icon(
              isFavorite ? Icons.star : Icons.star_border,
              color: Colors.amber,
            ),
            onPressed: () {
              if (_controller.text.isNotEmpty) {
                _toggleFavorite(_controller.text.trim());
              }
            },
          ),
          IconButton(
            icon: Icon(widget.isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.toggleTheme,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'City',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _getWeatherByCity(_controller.text.trim()),
                ),
              ),
            ),
            const SizedBox(height: 12),

            if (favoriteCities.isNotEmpty)
              Wrap(
                spacing: 8,
                children: favoriteCities.map((city) {
                  return ActionChip(
                    label: Text(city),
                    onPressed: () {
                      _controller.text = city;
                      _getWeatherByCity(city);
                    },
                  );
                }).toList(),
              ),

            const SizedBox(height: 20),

            if (loading) const CircularProgressIndicator(),
            if (error.isNotEmpty)
              Text(error, style: const TextStyle(color: Colors.red)),

            if (weatherData != null)
              Column(
                children: [
                  const SizedBox(height: 20),
                  Text(
                    '${weatherData!['current']['temp']} °C',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  Text(weatherData!['current']['weather'][0]['description']),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
