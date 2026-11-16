import 'package:flutter/material.dart';

import '../data/weather_repository.dart';
import '../models/weather.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key, required this.repository});

  final WeatherRepository repository;

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final _searchController = TextEditingController();

  late Future<Weather> _future; // created in initState, never in build()
  String _cityName = 'Ahmedabad'; // shown in the AppBar
  String _lastQuery = 'Ahmedabad'; // used by Retry

  @override
  void initState() {
    super.initState();
    _future = _load(_lastQuery);
  }

  @override
  void dispose() {
    _searchController.dispose(); 
    super.dispose();
  }

  /// Name → City → Weather.
  Future<Weather> _load(String query) async {
    _lastQuery = query;
    final city = await widget.repository.findCity(query);
    if (mounted) setState(() => _cityName = city.name);
    return widget.repository.getWeather(city);
  }

  void _search() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return; // guard clause
    FocusScope.of(context).unfocus(); // hide the keyboard
    setState(() => _future = _load(query));
  }

  void _retry() => setState(() => _future = _load(_lastQuery));

  /// Pull to refresh: RefreshIndicator waits for this Future to finish.
  Future<void> _refresh() async {
    final future = _load(_lastQuery);
    setState(() => _future = future);
    try {
      await future;
    } catch (_) {
      // The FutureBuilder shows the error; nothing else to do here.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_cityName)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: 'Search city',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  tooltip: 'Search',
                  onPressed: _search,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            // Expanded: a ListView inside a Column needs a bounded height.
            child: FutureBuilder<Weather>(
              future: _future,
              builder: (context, snapshot) {
                // 1. Loading
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                // 2. Error (already a friendly message from the repository)
                if (snapshot.hasError) {
                  return _ErrorView(
                    message: '${snapshot.error}',
                    onRetry: _retry,
                  );
                }
                // 3. Data
                final weather = snapshot.data!;
                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    // lets pull-to-refresh work even when content is short
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      _CurrentCard(weather: weather),
                      const SizedBox(height: 24),
                      Text(
                        '7-day forecast',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      for (var i = 0; i < weather.daily.length; i++)
                        _ForecastRow(day: weather.daily[i], isToday: i == 0),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// The big card with the current conditions.
class _CurrentCard extends StatelessWidget {
  const _CurrentCard({required this.weather});

  final Weather weather;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          children: [
            Text(
              weatherEmoji(weather.weatherCode),
              style: const TextStyle(fontSize: 72),
            ),
            Text(
              '${weather.temperature.toStringAsFixed(1)}°C',
              style: textTheme.displayMedium,
            ),
            Text(
              weatherDescription(weather.weatherCode),
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _InfoItem(iconName: Icons.water_drop, text: '${weather.humidity.toStringAsFixed(0)} %'),
                _InfoItem(iconName: Icons.air, text: '${weather.windSpeed.toStringAsFixed(0)} km/h')
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({required this.iconName, required this.text});

  final IconData iconName;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(children: [Icon(iconName, size: 20,), Text(text)]);
  }
}

/// One row of the forecast.
class _ForecastRow extends StatelessWidget {
  const _ForecastRow({required this.day, required this.isToday});

  final DailyForecast day;
  final bool isToday;

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Text(
        weatherEmoji(day.weatherCode),
        style: const TextStyle(fontSize: 28),
      ),
      title: Text(isToday ? 'Today' : _weekdays[day.date.weekday - 1]),
      subtitle: Text(weatherDescription(day.weatherCode)),
      trailing: Text(
        '${day.maxTemp.round()}° / ${day.minTemp.round()}°',
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}

/// Error state: icon, friendly message and a Retry button.
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
