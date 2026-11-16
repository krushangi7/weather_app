import 'dart:io';

import 'package:dio/dio.dart';
import 'package:weather_app/data/api/reverse_geocoding_api.dart';

import '../models/weather.dart';
import 'api/forecast_api.dart';
import 'api/geocoding_api.dart';
import 'weather_repository.dart';

/// Version 2: Dio + Retrofit.
/// Implements the SAME contract as OpenMeteoWeatherRepository (version 1, http),
/// so the UI works with either one unchanged.
class RetrofitWeatherRepository implements WeatherRepository {
  RetrofitWeatherRepository(Dio dio)
      : _geocoding = GeocodingApi(dio),
        _forecast = ForecastApi(dio),
        _reversegeo = ReverseGeocodingApi(dio);


  final GeocodingApi _geocoding;
  final ForecastApi _forecast;
  final ReverseGeocodingApi _reversegeo;

  static const _currentFields =
      'temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code';
  static const _dailyFields =
      'weather_code,temperature_2m_max,temperature_2m_min';

  @override
  Future<City> findCity(String name) => _guard(() async {
        final response = await _geocoding.searchCity(name, 10, 'en', 'In');
        if (response.cities.isEmpty) {
          throw WeatherException('City "$name" not found');
        }
        return response.cities.first;
      });
  
  @override
  Future<List<City>> searchCities(String query)  => _guard(() async {
    final listOfCity = await _geocoding.searchCity(query, 10, 'en', 'IN');

    return listOfCity.cities;
  });

  @override
  Future<City> cityAt(double lat, double lon) => _guard(() async { 
    final city = await _reversegeo.getReverse(lat, lon, 'json', 10, 'en');
    if(city.countryCode != 'India'){
      throw WeatherException("Selected place is not in India.");
    }
    return City(city.name, lat, lon, city.state);
  });

  @override
  Future<Weather> getWeather(City city) => _guard(
        () => _forecast.getForecast(
          city.lat,
          city.lon,
          _currentFields,
          _dailyFields,
          'auto',
          7,
          'IN',
          10
        ),
      );

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw WeatherException(_messageFor(e));
    }
  }

  /// One exhaustive-style switch replaces the separate `on SocketException`,
  /// `on TimeoutException` clauses from version 1.
  String _messageFor(DioException e) => switch (e.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout =>
          'The server took too long to respond',
        DioExceptionType.connectionError => 'No internet connection',
        DioExceptionType.unknown when e.error is SocketException =>
          'No internet connection',
        DioExceptionType.badResponse =>
          'Server error (${e.response?.statusCode})',
        _ => 'Something went wrong. Please try again.',
      };
}
