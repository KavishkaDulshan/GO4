import 'dart:io';
import 'package:dio/dio.dart';
import '../../models/search_result.dart';

/// Base URL strategy:
///   - Physical device via USB  → localhost:5000  (adb reverse tcp:5000 tcp:5000 tunnels to host)
///   - Android emulator         → 10.0.2.2:5000   (emulator alias for host localhost)
///   Host port 5000 maps to container port 3000 via docker-compose.
const String _deviceBase = 'http://localhost:5000'; // USB + adb reverse
// const String _emulatorBase = 'http://10.0.2.2:5000'; // uncomment for Android emulator

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  late final Dio _dio = _buildDio();

  Dio _buildDio() {
    final baseUrl = _resolveBaseUrl();

    final options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );

    final dio = Dio(options);

    // ── Logging interceptor (dev only) ─────────────────────────────────────
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // ignore: avoid_print
          print('[API] ▶  ${options.method} ${options.uri}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          // ignore: avoid_print
          print(
            '[API] ✅  ${response.statusCode} ${response.requestOptions.path}',
          );
          handler.next(response);
        },
        onError: (DioException e, handler) {
          // ignore: avoid_print
          print('[API] ❌  ${e.type} – ${e.message}');
          handler.next(e);
        },
      ),
    );

    return dio;
  }

  /// Returns the correct base URL for the current run target.
  /// Switch to _emulatorBase when using the Android emulator instead of a real device.
  String _resolveBaseUrl() => _deviceBase;

  // ── Health ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> checkHealth() async {
    final res = await _dio.get('/api/v1/health');
    return res.data as Map<String, dynamic>;
  }

  // ── Multimodal Search ───────────────────────────────────────────────────

  /// [imagePath]  – local file path to the captured image (nullable)
  /// [audioPath]  – local file path to the voice recording (nullable)
  /// [query]      – optional plain-text override / supplement
  /// [transcript] – pre-transcribed voice text
  /// [sessionId]  – anonymous session token for history persistence
  Future<Map<String, dynamic>> multimodalSearch({
    String? imagePath,
    String? audioPath,
    String? query,
    String? transcript,
    String? sessionId,
  }) async {
    final formData = FormData();

    if (imagePath != null) {
      formData.files.add(
        MapEntry(
          'image',
          await MultipartFile.fromFile(
            imagePath,
            filename: File(imagePath).uri.pathSegments.last,
          ),
        ),
      );
    }

    if (audioPath != null) {
      formData.files.add(
        MapEntry(
          'audio',
          await MultipartFile.fromFile(
            audioPath,
            filename: File(audioPath).uri.pathSegments.last,
          ),
        ),
      );
    }

    if (query      != null && query.isNotEmpty)      formData.fields.add(MapEntry('query',      query));
    if (transcript != null && transcript.isNotEmpty) formData.fields.add(MapEntry('transcript', transcript));
    if (sessionId  != null && sessionId.isNotEmpty)  formData.fields.add(MapEntry('sessionId',  sessionId));

    final res = await _dio.post(
      '/api/v1/search',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
        receiveTimeout: const Duration(seconds: 60), // Gemini can take up to 15s
      ),
    );
    return res.data as Map<String, dynamic>;
  }

  /// Typed wrapper — returns a [SearchResult] model directly.
  Future<SearchResult> search({
    String? imagePath,
    String? audioPath,
    String? query,
    String? transcript,
    String? sessionId,
  }) async {
    final raw = await multimodalSearch(
      imagePath:  imagePath,
      audioPath:  audioPath,
      query:      query,
      transcript: transcript,
      sessionId:  sessionId,
    );
    return SearchResult.fromJson(raw);
  }
}
