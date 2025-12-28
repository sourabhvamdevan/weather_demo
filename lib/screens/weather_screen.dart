import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
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

class _WeatherScreenState extends State<WeatherScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final WeatherService _service = WeatherService();

  Map<String, dynamic>? weatherData;
  bool loading = false;
  String error = '';

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  void getWeather() async {
    if (_controller.text.isEmpty) return;

    setState(() {
      loading = true;
      error = '';
    });

    try {
      final data = await _service.fetchWeather(_controller.text);
      setState(() => weatherData = data);
      _animationController.forward(from: 0);
    } catch (e) {
      setState(() => error = 'City not found');
    }

    setState(() => loading = false);
  }

  String iconUrl(String iconCode) =>
      'https://openweathermap.org/img/wn/$iconCode@2x.png';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather'),
        actions: [
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
                  onPressed: getWeather,
                ),
              ),
            ),
            const SizedBox(height: 20),

            if (loading) const CircularProgressIndicator(),
            if (error.isNotEmpty)
              Text(error, style: const TextStyle(color: Colors.red)),

            if (weatherData != null)
              FadeTransition(
                opacity: _animationController,
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Image.network(
                      iconUrl(weatherData!['current']['weather'][0]['icon']),
                      width: 100,
                    ),
                    Text(
                      '${weatherData!['current']['temp']} °C',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    Text(
                      weatherData!['current']['weather'][0]['description'],
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      '7-Day Forecast',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(
                      height: 260,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 7,
                        itemBuilder: (context, index) {
                          final day = weatherData!['daily'][index];
                          return OpenContainer(
                            closedElevation: 2,
                            openElevation: 4,
                            transitionType: ContainerTransitionType.fade,
                            closedBuilder: (_, __) => Card(
                              margin: const EdgeInsets.all(8),
                              child: SizedBox(
                                width: 140,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.network(
                                      iconUrl(day['weather'][0]['icon']),
                                      width: 50,
                                    ),
                                    Text(
                                      '${day['temp']['day']} °C',
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                    Text(day['weather'][0]['main']),
                                  ],
                                ),
                              ),
                            ),
                            openBuilder: (_, __) => const SizedBox(),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
