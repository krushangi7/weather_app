import 'package:flutter/material.dart';

// import 'data/open_meteo_repository.dart';
import 'screens/weather_screen.dart';
import 'config/repository_config.dart';

void main() => runApp(const WeatherApp());

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  ThemeData _buildTheme(Brightness brightness) => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.lightBlue,
          brightness: brightness,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      home: WeatherScreen(repository: createWeatherRepository()), //old(http): OpenMeteoWeatherRepository()
    );
  }
}
