import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/weather.dart';
import 'weather_repository.dart';

/// The real implementation: HOW to get the data from Open-Meteo (no API key needed).
class OpenMeteoWeatherRepository implements WeatherRepository {
  @override
  Future<City> findCity(String name) async {
    // Geocoding API: turns "Pune" into coordinates.
    final url = Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
      'name': name,
      'count': '1',
      'language': 'en',
    });

    final data = await _getJson(url);
    final results = data['results'] as List?;
    if (results == null || results.isEmpty) {
      throw WeatherException('City "$name" not found');
    }

    final r = results.first as Map<String, dynamic>;
    return City(
      r['name'] as String,
      (r['latitude'] as num).toDouble(),
      (r['longitude'] as num).toDouble(),
    );
  }

  @override
  Future<Weather> getWeather(City city) async {
    final url = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': '${city.lat}',
      'longitude': '${city.lon}',
      'current': 'temperature_2m,wind_speed_10m,weather_code,relative_humidity_2m',
      'daily': 'weather_code,temperature_2m_max,temperature_2m_min',
      'timezone': 'auto',
      'forecast_days': '7',
    });

    return Weather.fromJson(await _getJson(url));
  }

  /// One private helper does the HTTP work and translates every low-level
  /// error into a friendly WeatherException, so the UI never sees them.
  Future<Map<String, dynamic>> _getJson(Uri url) async {
    try {
      final res = await http.get(url).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) {
        throw WeatherException('Server error (${res.statusCode})');
      }
      return jsonDecode(res.body) as Map<String, dynamic>;
    } on SocketException {
      throw WeatherException('No internet connection');
    } on http.ClientException {
      // Newer versions of the http package wrap network failures in this.
      throw WeatherException('No internet connection');
    } on TimeoutException {
      throw WeatherException('The server took too long to respond');
    } on FormatException {
      throw WeatherException('Unexpected data from the server');
    }
  }

  @override
  Future<List<City>> searchCities(String query) async {
    final url = Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
      'name': query,
      'count': '5',
      'language': 'en',
      'countryCode' : 'IN'
      
    });

    final data = await _getJson(url);
    final results = data['results'] as List?;
    if (results == null || results.isEmpty) {
      // throw WeatherException('City of State "$query" not found');
      return const <City>[];
    }

    final r = results as List<City>;
    return r;
  }

  @override
  Future<City> cityAt(double lat, double lon) async { 
    return City('ahmedabad', 0, 0); //update
  }
}
