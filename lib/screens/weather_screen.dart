import 'package:flutter/material.dart';
import 'package:weather_app/screens/map_picker_screen.dart';

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
  final _searchFocusNode = FocusNode();
  String _lastSearchedText = '';

  late Future<Weather> _future; // created in initState, never in build()
  String _cityName = 'Ahmedabad'; // shown in the AppBar
  String _lastQuery = 'Ahmedabad';
  City? _lastCity;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_onSearchFocusChange);
    _future = _load(_lastQuery);
  }

  @override
  void dispose() {
    _searchController.dispose(); 
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchFocusChange() {
    if (!_searchFocusNode.hasFocus) _search();
  }

  /// Name → City → Weather.
  Future<Weather> _load(String query) async {
    _lastQuery = query;
    final city = await widget.repository.findCity(query);
    if (mounted) setState(() => _cityName = city.name);
    return _loadCity(city);
  }

  void _search() {
    final query = _searchController.text.trim();
    if (query.isEmpty || query == _lastSearchedText) return;
    _lastSearchedText = query;
    setState(() => _future = _load(query));
  }

  Future<Weather> _loadFromMap(City picked) async {
  final city = await widget.repository.cityAt(picked.lat, picked.lon);
  if (mounted) {
    setState(() {
      _lastCity = city;
      _cityName = city.label;            // "Panipat, Haryana"
    });
  }
  return widget.repository.getWeather(city);
}

  Future<Weather> _loadCity(City city) {
    // setState(() {
    //   _lastCity = city;
    // });
    _lastCity = city;
    _cityName = city.label;
    return widget.repository.getWeather(city);
  }

  void _retry() => setState(() => _future = _load(_lastCity != null ? _lastCity!.name : _lastQuery));

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

  Future<void> _pickOnMap() async {
    final city = await Navigator.push<City>(
      context,
      MaterialPageRoute(builder: (context) => const MapPickerScreen()),
    );
    if (city == null || !mounted) return;
    setState(() {
        _future = _loadFromMap(city);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_cityName), actions: [
        IconButton(onPressed: _pickOnMap, icon: Icon(Icons.map))
      ],),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Autocomplete<City>(
              textEditingController: _searchController,
              focusNode: _searchFocusNode,
              displayStringForOption: (city) => city.label,              // text shown for a City
              optionsBuilder: (textEditingValue) async {                 // runs as the user types
                final query = textEditingValue.text.trim();
                if (query.length < 2) return const <City>[];             // guard clause
                return widget.repository.searchCities(query);
              },
              onSelected: (city) {
                _lastSearchedText = city.label;            // so the blur doesn't search again by name
                setState(() {
                _cityName = city.name;
                _lastQuery = city.name;
                _future = _loadCity(city);
              });

                _searchFocusNode.unfocus();    
              },
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                return TextField(
                  controller: controller,                   
                  focusNode: focusNode,                     
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => focusNode.unfocus(),       // Enter → lose focus → search runs
                  onTapOutside: (_) => focusNode.unfocus(),     
                  decoration: InputDecoration(            
                    hintText: 'Search city',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
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
