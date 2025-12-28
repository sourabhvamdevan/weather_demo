import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import '../services/weather_service.dart';

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
  bool loading = false;
  String error = '';

  @override
  void initState() {
    super.initState();
    _loadLastCity();
  }

  // save and load city

  Future<void> _saveCity(String city) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_city', city);
  }

  Future<void> _loadLastCity() async {
    final prefs = await SharedPreferences.getInstance();
    final city = prefs.getString('last_city');
    if (city != null) {
      _controller.text = city;
      _getWeatherByCity(city);
    }
  }

  // fetch weather

  Future<void> _getWeatherByCity(String city) async {
    setState(() {
      loading = true;
      error = '';
    });

    try {
      final data = await _service.fetchByCity(city);
      setState(() => weatherData = data);
      _saveCity(city);
    } catch (e) {
      setState(() => error = 'City not found');
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
    } catch (e) {
      setState(() => error = 'Location permission denied');
    }

    setState(() => loading = false);
  }

  // for UI

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
