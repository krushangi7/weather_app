import '../models/weather.dart';

/// A place found by name.
class City {
  final String name;
  final double lat;
  final double lon;

  const City(this.name, this.lat, this.lon);
}

/// An error with a message that is ready to show to users.
class WeatherException implements Exception {
  final String message;

  WeatherException(this.message);

  @override
  String toString() => message;
}

abstract class WeatherRepository {
  Future<City> findCity(String name);

  Future<Weather> getWeather(City city);
}

/// A fake for testing or working offline. No screen changes needed to use it.
class FakeWeatherRepository implements WeatherRepository {
  @override
  Future<City> findCity(String name) async => City(name, 0, 0);

  @override
  Future<Weather> getWeather(City city) async {
    await Future.delayed(const Duration(seconds: 1));
    final today = DateTime.now();
    return Weather(
      temperature: 31.5,
      windSpeed: 8,
      weatherCode: 0,
      time: today,
      humidity: 40,
      daily: [
        for (var i = 0; i < 7; i++)
          DailyForecast(
            date: today.add(Duration(days: i)),
            weatherCode: i.isEven ? 0 : 3,
            maxTemp: 32 - i.toDouble(),
            minTemp: 21 - i.toDouble(),
          ),
      ],
    );
  }
}
