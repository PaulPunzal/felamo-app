import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ErrorHelper {
  static const offlineMessage =
      'Walang koneksyon sa internet. Pakisuri ang iyong network at subukan muli.';
  static const timeoutMessage =
      'Masyadong matagal ang koneksyon. Pakisubukan muli.';
  static const serverMessage =
      'May problema sa server. Pakisubukan muli mamaya.';
  static const unknownMessage = 'May nangyaring mali. Pakisubukan muli.';

  /// For exceptions thrown by http.post / video init (offline, timeout, etc.)
  static String fromException(Object e) {
    if (e is TimeoutException) return timeoutMessage;
    if (e is SocketException ||
        e is HandshakeException ||
        e is http.ClientException) {
      return offlineMessage;
    }
    return unknownMessage;
  }

  /// For HTTP responses. Prefers the backend's own message (e.g. the 403
  /// "not enough points") and falls back to a friendly default per status.
  static String fromResponse(http.Response r, {String? fallback}) {
    if (r.statusCode >= 500) return serverMessage;

    try {
      final body = jsonDecode(r.body);
      if (body is Map) {
        final errors = body['errors'];
        if (errors is List && errors.isNotEmpty) return errors.join('\n');
        final msg = body['message'];
        if (msg is String && msg.isNotEmpty) return msg;
      }
    } catch (_) {}

    switch (r.statusCode) {
      case 401:
        return 'Nag-expire na ang iyong session. Mangyaring mag-login muli.';
      case 403:
        return 'Hindi pinapayagan ang aksyong ito.';
      case 404:
        return 'Hindi mahanap ang hinihinging impormasyon.';
      default:
        return fallback ?? unknownMessage;
    }
  }

  static void showSnack(BuildContext context, String message,
      {bool isError = true}) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              isError ? const Color(0xFFC62828) : const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}