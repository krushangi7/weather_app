import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Creates ONE configured Dio, shared by every Retrofit API in the app.
/// Interceptors added here apply to every request.
Dio createDio() {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 50),
      receiveTimeout: const Duration(seconds: 50),
      headers: {'Accept': 'application/json'},
    ),
  );

  // Prints each request and its status in the Debug Console.
  // Only in debug builds, so release builds stay quiet.
  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(
        responseBody: false, 
        logPrint: (object) => debugPrint(object.toString()),
      ),
    );
  }

  return dio;
}
