import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class GeminiException implements Exception {
  final String message;
  final int? statusCode;
  final int? retryAfterSeconds;

  GeminiException(this.message, {this.statusCode, this.retryAfterSeconds});

  @override
  String toString() => message;
}

class GeminiExceptionHandler {
  /// Keep detailed logs only in Debug mode. Never expose these logs in Release mode.
  static void logRequest({
    required String endpoint,
    required int? statusCode,
    required String errorType,
    required int retryCount,
    required Duration responseTime,
  }) {
    if (kDebugMode) {
      print('=== GEMINI API LOG ===');
      print('Endpoint: $endpoint');
      print('HTTP Code: ${statusCode ?? "N/A"}');
      print('Error Type: $errorType');
      print('Retry Count: $retryCount');
      print('Response Time: ${responseTime.inMilliseconds}ms');
      print('======================');
    }
  }

  /// Maps HTTP status codes to friendly user-facing messages.
  static GeminiException handleResponse(http.Response response) {
    final code = response.statusCode;
    int? retryAfter;

    // 1. Try parsing Retry-After header
    final retryAfterHeader = response.headers['retry-after'];
    if (retryAfterHeader != null) {
      retryAfter = int.tryParse(retryAfterHeader);
    }

    // 2. Try parsing response body for error details & retryDelay
    try {
      final bodyMap = jsonDecode(response.body) as Map<String, dynamic>;
      final errorMap = bodyMap['error'] as Map<String, dynamic>?;
      if (errorMap != null) {
        final details = errorMap['details'] as List<dynamic>?;
        if (details != null && details.isNotEmpty) {
          for (final detail in details) {
            if (detail is Map && detail.containsKey('retryDelay')) {
              final delayStr = detail['retryDelay'] as String?;
              if (delayStr != null) {
                final seconds = int.tryParse(delayStr.replaceAll('s', ''));
                if (seconds != null) {
                  retryAfter = seconds;
                }
              }
            }
          }
        }
      }
    } catch (_) {}

    switch (code) {
      case 400:
        return GeminiException(
          "Invalid request. Please try another receipt.",
          statusCode: code,
        );
      case 401:
      case 403:
        return GeminiException(
          "AI service authentication failed.",
          statusCode: code,
        );
      case 404:
        return GeminiException(
          "Requested AI service is unavailable.",
          statusCode: code,
        );
      case 408:
        return GeminiException(
          "The request timed out. Please try again.",
          statusCode: code,
        );
      case 429:
        return GeminiException(
          "AI Service Busy. The request limit has been reached. Please wait a few moments and try again.",
          statusCode: code,
          retryAfterSeconds: retryAfter,
        );
      case 500:
      case 502:
      case 503:
      case 504:
        return GeminiException(
          "AI service is temporarily unavailable. Please try again later.",
          statusCode: code,
          retryAfterSeconds: retryAfter,
        );
      default:
        return GeminiException(
          "Unexpected error occurred.",
          statusCode: code,
        );
    }
  }

  /// Maps internal exceptions (network, timeout, etc.) to friendly user-facing messages.
  static GeminiException handleException(dynamic exception) {
    if (exception is SocketException) {
      return GeminiException("No Internet Connection");
    }
    if (exception is TimeoutException) {
      return GeminiException("Network timeout. Check your connection.");
    }
    if (exception is GeminiException) {
      return exception;
    }
    return GeminiException("Unexpected error occurred.");
  }
}
