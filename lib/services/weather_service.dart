import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  static const String apiKey = 'YOUR_API_KEY';

  Future<Map<String, dynamic>> fetchWeather(String city) async {
    final geoUrl = Uri.parse(
      'http://api.openweathermap.org/geo/1.0/direct?q=$city&limit=1&appid=$apiKey',
    );

    final geoRes = await http.get(geoUrl);
    final geoData = json.decode(geoRes.body);

    if (geoData.isEmpty) {
      throw Exception('City not found');
    }

    final lat = geoData[0]['lat'];
    final lon = geoData[0]['lon'];

    final weatherUrl = Uri.parse(
      'https://api.openweathermap.org/data/2.5/onecall?lat=$lat&lon=$lon&exclude=minutely,hourly,alerts&units=metric&appid=$apiKey',
      //yha api daalo
    );

    final weatherRes = await http.get(weatherUrl);

    return json.decode(weatherRes.body);
  }
}
