/// Current weather plus the daily forecast for one place.
class Weather {
  final double temperature;
  final double windSpeed;
  final int weatherCode;
  final DateTime time;
  final List<DailyForecast> daily;
  final double humidity;

  const Weather({
    required this.temperature,
    required this.windSpeed,
    required this.weatherCode,
    required this.time,
    required this.daily,
    required this.humidity
  });

  /// Converts Open-Meteo's JSON into a typed object, in ONE place (Lesson 3).
  factory Weather.fromJson(Map<String, dynamic> json) {
    final current = json['current'] as Map<String, dynamic>;
    final dailyJson = json['daily'] as Map<String, dynamic>;

    // The forecast arrives as parallel lists (Lesson 2).
    final dates = dailyJson['time'] as List;
    final codes = dailyJson['weather_code'] as List;
    final maxes = dailyJson['temperature_2m_max'] as List;
    final mins = dailyJson['temperature_2m_min'] as List;

    return Weather(
      // `as num` then convert: safe whether JSON sends 27 or 27.4.
      temperature: (current['temperature_2m'] as num).toDouble(),
      windSpeed: (current['wind_speed_10m'] as num).toDouble(),
      weatherCode: (current['weather_code'] as num).toInt(),
      time: DateTime.parse(current['time'] as String),
      daily: [
        for (var i = 0; i < dates.length; i++)
          DailyForecast(
            date: DateTime.parse(dates[i] as String),
            weatherCode: (codes[i] as num).toInt(),
            maxTemp: (maxes[i] as num).toDouble(),
            minTemp: (mins[i] as num).toDouble(),
          ),
      ],
      humidity: (current['relative_humidity_2m'] as num).toDouble()
    );
  }
}

/// One day of the forecast.
class DailyForecast {
  final DateTime date;
  final int weatherCode;
  final double maxTemp;
  final double minTemp;

  const DailyForecast({
    required this.date,
    required this.weatherCode,
    required this.maxTemp,
    required this.minTemp,
  });
}

/// WMO weather code → emoji (relational and logical patterns, Phase 2/3).
String weatherEmoji(int code) => switch (code) {
      0 => '☀️',
      1 || 2 => '🌤️',
      3 => '☁️',
      45 || 48 => '🌫️',
      >= 51 && <= 67 => '🌧️',
      >= 71 && <= 77 => '❄️',
      >= 80 && <= 82 => '🌦️',
      >= 85 && <= 86 => '🌨️',
      >= 95 => '⛈️',
      _ => '🌡️',
    };

/// WMO weather code → words.
String weatherDescription(int code) => switch (code) {
      0 => 'Clear sky',
      1 => 'Mainly clear',
      2 => 'Partly cloudy',
      3 => 'Overcast',
      45 || 48 => 'Fog',
      >= 51 && <= 57 => 'Drizzle',
      >= 61 && <= 67 => 'Rain',
      >= 71 && <= 77 => 'Snow',
      >= 80 && <= 82 => 'Rain showers',
      >= 85 && <= 86 => 'Snow showers',
      >= 95 => 'Thunderstorm',
      _ => 'Unknown',
    };
