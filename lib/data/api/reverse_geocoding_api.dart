import 'package:dio/dio.dart' hide Headers;
import 'package:retrofit/retrofit.dart';


part 'reverse_geocoding_api.g.dart';

@RestApi(baseUrl: 'https://nominatim.openstreetmap.org')
abstract class ReverseGeocodingApi {
  factory ReverseGeocodingApi(Dio dio, {String? baseUrl}) = _ReverseGeocodingApi;

  /// GET /v1/search?name=..&count=..&language=..
  @GET('/reverse')
  @Headers({'User-Agent': 'weather_app_learning/1.0'})
  Future<ReverseGeocodeResponse> getReverse(
    @Query('lat') double lat,
    @Query('lon') double lon,
    @Query('format') String format,
    @Query('zoom') int zoom,
    @Query('accept-language') String acceptLang,
  );
}

class ReverseGeocodeResponse {
  final String name;
  final String? state;
  final String? countryCode;

  const ReverseGeocodeResponse(this.name, this.state, this.countryCode);

  factory ReverseGeocodeResponse.fromJson(Map<String, dynamic> json) {
    final address = json['address'] as Map<String, dynamic>? ?? const {};
    final name = address['city'] ?? address['town'] ?? address['village']
    ?? address['county'] ?? address['state_district'] ?? 'Selected location';
    final state = address['state_district'];
    final countryCode =address['country'];

    return ReverseGeocodeResponse(name, state, countryCode);
  }
}

// factory ReverseGeocodeResponse.fromJson(Map<String, dynamic> json) {
//   final address = json['address'] as Map<String, dynamic>? ?? const {};

//   final name = address['city'] as String? ??
//       address['town'] as String? ??
//       address['village'] as String? ??
//       address['county'] as String? ??
//       address['state_district'] as String? ??
//       'Selected location';

//   return ReverseGeocodeResponse(
//     name,
//     address['state'] as String?,
//     address['country_code'] as String?,
//   );
// }