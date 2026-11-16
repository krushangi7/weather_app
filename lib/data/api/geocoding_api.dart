import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../weather_repository.dart';

part 'geocoding_api.g.dart';

/// Open-Meteo geocoding endpoint: city name → coordinates.
@RestApi(baseUrl: 'https://geocoding-api.open-meteo.com')
abstract class GeocodingApi {
  factory GeocodingApi(Dio dio, {String? baseUrl}) = _GeocodingApi;

  /// GET /v1/search?name=..&count=..&language=..
  @GET('/v1/search')
  Future<CitySearchResponse> searchCity(
    @Query('name') String name,
    @Query('count') int count,
    @Query('language') String language,
    @Query('countryCode') String countryCode,
  );
}

/// The geocoding response. The API leaves out `results`
/// entirely when nothing matches, so a missing list becomes empty.
class CitySearchResponse {
  final List<City> cities;

  const CitySearchResponse(this.cities);

  factory CitySearchResponse.fromJson(Map<String, dynamic> json) {
    final results = json['results'] as List? ?? const [];
    return CitySearchResponse([
      for (final r in results.cast<Map<String, dynamic>>())
        City(
          r['name'] as String,
          (r['latitude'] as num).toDouble(),
          (r['longitude'] as num).toDouble(),
          r['admin1'] as String
        ),
    ]);
  }
}
