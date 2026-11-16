import '../data/api/dio_client.dart';
import '../data/open_meteo_repository.dart';
import '../data/retrofit_weather_repository.dart';
import '../data/weather_repository.dart';

/// Which data layer the app uses.
/// Both implement WeatherRepository, so nothing else in the app changes.
///   true  → version 2: Dio + Retrofit (lib/data/retrofit_weather_repository.dart)
///   false → version 1: http package  (lib/data/open_meteo_repository.dart)
const bool useRetrofit = true;

/// The single place where the app's WeatherRepository is created.
WeatherRepository createWeatherRepository() => useRetrofit
    ? RetrofitWeatherRepository(createDio())
    : OpenMeteoWeatherRepository();
