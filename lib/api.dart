import 'dart:convert';

import 'package:http/http.dart' as http;

const apiBase = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:3000',
);

class Api {
  Future<dynamic> call(String method, String path, [Object? body]) async {
    final uri = Uri.parse('$apiBase$path');
    final headers = {'Content-Type': 'application/json'};
    final http.Response response = switch (method) {
      'GET' => await http.get(uri),
      'POST' => await http.post(
        uri,
        headers: headers,
        body: jsonEncode(body ?? {}),
      ),
      'PUT' => await http.put(
        uri,
        headers: headers,
        body: jsonEncode(body ?? {}),
      ),
      _ => throw ArgumentError('Unsupported method'),
    };
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode >= 400) {
      throw ApiException(
        (data is Map ? data['error'] : null)?.toString() ?? 'Ошибка запроса',
      );
    }
    return data;
  }
}

class ApiException implements Exception {
  final String message;
  const ApiException(this.message);
  @override
  String toString() => message;
}
