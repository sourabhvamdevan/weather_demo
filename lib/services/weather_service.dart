import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  static const String apiKey = 'YOUR_API_KEY';

  Future<Map<String, dynamic>> fetchByCity(String city) async {
    final geoUrl = Uri.parse(
      'https://api.openweathermap.org/geo/1.0/direct?q=$city&limit=1&appid=$apiKey',
    );

    final geoRes = await http.get(geoUrl);
    final geoData = json.decode(geoRes.body);

    if (geoData.isEmpty) throw Exception('City not found');

    return fetchByLatLon(geoData[0]['lat'], geoData[0]['lon']);
  }

  Future<Map<String, dynamic>> fetchByLatLon(double lat, double lon) async {
    final url = Uri.parse(
      'https://api.openweathermap.org/data/2.5/onecall'
      '?lat=$lat&lon=$lon'
      '&units=metric'
      '&exclude=minutely,hourly,alerts'
      '&appid=$apiKey',
    );

    final res = await http.get(url);
    return json.decode(res.body);
  }
}
