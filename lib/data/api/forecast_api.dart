import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../models/weather.dart';

// The generator writes the implementation (_ForecastApi) into this file.
// Never edit it by hand: run `dart run build_runner build` instead.
part 'forecast_api.g.dart';

/// Open-Meteo forecast endpoint, DECLARED instead of hand-written.
@RestApi(baseUrl: 'https://api.open-meteo.com')
abstract class ForecastApi {
  factory ForecastApi(Dio dio, {String? baseUrl}) = _ForecastApi;

  /// GET /v1/forecast?latitude=..&longitude=..&current=..&daily=..
  /// The generated code calls Weather.fromJson for us.
  @GET('/v1/forecast')
  Future<Weather> getForecast(
    @Query('latitude') double latitude,
    @Query('longitude') double longitude,
    @Query('current') String current,
    @Query('daily') String daily,
    @Query('timezone') String timezone,
    @Query('forecast_days') int forecastDays,
    @Query('countryCode') String countryCode,
    @Query('count') int count
  );
}
