import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  static const String apiKey = 'YOUR_API_KEY';

  /// Fetch weather using city name
  Future<Map<String, dynamic>> fetchByCity(String city) async {
    final geoUrl = Uri.parse(
      'https://api.openweathermap.org/geo/1.0/direct'
      '?q=$city&limit=1&appid=$apiKey',
    );

    final geoRes = await http.get(geoUrl);

    if (geoRes.statusCode != 200) {
      throw Exception('Failed to fetch location');
    }

    final geoData = json.decode(geoRes.body);

    if (geoData.isEmpty) {
      throw Exception('City not found');
    }

    final double lat = geoData[0]['lat'];
    final double lon = geoData[0]['lon'];

    return fetchByLatLon(lat, lon);
  }

  /// Fetch weather using latitude & longitude (GPS)
  Future<Map<String, dynamic>> fetchByLatLon(double lat, double lon) async {
    final weatherUrl = Uri.parse(
      'https://api.openweathermap.org/data/2.5/onecall'
      '?lat=$lat&lon=$lon'
      '&units=metric'
      '&exclude=minutely,hourly,alerts'
      '&appid=$apiKey',
    );

    final res = await http.get(weatherUrl);

    if (res.statusCode != 200) {
      throw Exception('Failed to fetch weather data');
    }

    return json.decode(res.body);
  }
}
